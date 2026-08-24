import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import 'package:kappogy_share/features/file_management/domain/models/kappogy_file.dart';
import 'package:kappogy_share/features/history/application/history_service.dart';
import 'package:kappogy_share/features/history/domain/models/transfer_history_record.dart';
import 'package:kappogy_share/features/transfer/domain/models/transfer_session.dart';
import 'package:kappogy_share/features/transfer/application/crypto_service.dart';
import 'package:kappogy_share/features/transfer/application/discovery_service.dart';
import 'package:kappogy_share/features/transfer/application/storage_service.dart';
import 'package:kappogy_share/features/settings/application/settings_service.dart';
import 'package:kappogy_share/core/notifications/notification_service.dart';

part 'transfer_engine.g.dart';

@riverpod
class TransferEngine extends _$TransferEngine {
  HttpServer? _server;
  WebSocketChannel? _channel;
  SecretKey? _sharedSecret;
  
  final Map<int, IOSink> _activeSinks = {};
  final Map<int, String> _downloadPaths = {};
  
  Timer? _speedTicker;
  int _lastTransferredBytes = 0;
  DateTime? _transferStartTime;

  int? get serverPort => _server?.port;

  @override
  TransferSession? build() {
    ref.onDispose(() {
      _cleanup();
    });
    return null;
  }

  Future<void> _cleanup() async {
    for (var sink in _activeSinks.values) {
      await sink.close();
    }
    _activeSinks.clear();
    _downloadPaths.clear();

    _speedTicker?.cancel();
    _speedTicker = null;
    _transferStartTime = null;
    _lastTransferredBytes = 0;

    await _server?.close(force: true);
    await _channel?.sink.close();
    _server = null;
    _channel = null;
    _sharedSecret = null;
    
    if (state != null && state!.status != TransferStatus.completed && state!.status != TransferStatus.failed) {
       final failedFilename = state!.files.isEmpty ? 'Unknown' : state!.files.length == 1 ? state!.files.first.name : '${state!.files.length} files';
       final errorMessage = state!.errorMessage ?? 'Unknown error';
       ref.read(notificationServiceProvider.notifier).showTransferFailed(failedFilename, errorMessage);
       state = state!.copyWith(status: TransferStatus.failed);
       _logHistory();
    }
    state = null;
  }

  void _logHistory() {
    if (state == null) return;
    
    if (state!.status != TransferStatus.completed && state!.status != TransferStatus.failed) {
      return;
    }

    final duration = _transferStartTime != null 
        ? DateTime.now().difference(_transferStartTime!).inSeconds
        : 0;

    final record = TransferHistoryRecord(
      id: state!.id,
      filename: state!.files.length == 1 
          ? state!.files.first.name 
          : '${state!.files.length} files',
      totalBytes: state!.totalBytes,
      role: state!.role,
      status: state!.status,
      date: DateTime.now(),
      durationSeconds: duration,
      deviceName: 'Device',
    );
    
    ref.read(historyServiceProvider.notifier).addRecord(record);
  }

  void _startSpeedTicker() {
    _speedTicker?.cancel();
    _lastTransferredBytes = state!.transferredBytes;
    _transferStartTime ??= DateTime.now();
    
    _speedTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state == null || state!.status != TransferStatus.transferring) {
        timer.cancel();
        return;
      }
      
      final currentBytes = state!.transferredBytes;
      final bytesSinceLastTick = currentBytes - _lastTransferredBytes;
      _lastTransferredBytes = currentBytes;
      
      final elapsed = DateTime.now().difference(_transferStartTime!);
      final avgSpeed = elapsed.inSeconds > 0 ? (currentBytes / elapsed.inSeconds).round() : 0;
      
      final remainingBytes = state!.totalBytes - currentBytes;
      int? etaSeconds;
      if (bytesSinceLastTick > 0) {
        etaSeconds = remainingBytes ~/ bytesSinceLastTick;
      } else if (avgSpeed > 0) {
        etaSeconds = remainingBytes ~/ avgSpeed;
      }
      
      final currentMBps = bytesSinceLastTick / (1024 * 1024);
      final newSpeedHistory = List<double>.from(state!.speedHistory)..add(currentMBps);
      if (newSpeedHistory.length > 60) {
        newSpeedHistory.removeAt(0);
      }
      
      state = state!.copyWith(
        currentSpeedBytesPerSecond: bytesSinceLastTick,
        averageSpeedBytesPerSecond: avgSpeed,
        estimatedTimeRemainingSeconds: etaSeconds,
        speedHistory: newSpeedHistory,
      );
    });
  }

  Future<void> startAsSender(List<KappogyFile> files) async {
    await _cleanup();
    
    final pin = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString().substring(0, 6);
    
    int totalBytes = files.fold(0, (sum, f) => sum + f.size);

    state = TransferSession(
      id: const Uuid().v4(),
      pin: pin,
      role: TransferRole.sender,
      status: TransferStatus.initializing,
      files: files,
      totalBytes: totalBytes,
      createdAt: DateTime.now(),
    );

    final wsHandler = webSocketHandler((webSocket, protocol) {
      _channel = webSocket;
      _handleSenderConnection();
    });

    final handler = (shelf.Request request) async {
      if (request.url.path == 'ws') {
        return wsHandler(request);
      } else if (request.url.path == '' || request.url.path == '/') {
        return shelf.Response.ok(_generateWebInterface(), headers: {'content-type': 'text/html'});
      } else if (request.url.path == 'download') {
        if (state == null || state!.files.isEmpty) {
          return shelf.Response.notFound('No file available');
        }
        final file = state!.files.first;
        final dartFile = File(file.path);
        if (!dartFile.existsSync()) return shelf.Response.notFound('File not found');
        return shelf.Response.ok(dartFile.openRead(), headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Disposition': 'attachment; filename="${file.name}"',
          'Content-Length': file.size.toString(),
        });
      }
      return shelf.Response.notFound('Not found');
    };

    _server = await shelf_io.serve(handler, '0.0.0.0', 0);
    
    state = state!.copyWith(status: TransferStatus.waitingForConnection);

    await ref.read(discoveryServiceProvider.notifier).startBroadcasting(pin, _server!.port);
    
    final filename = files.length == 1 ? files.first.name : '${files.length} files';
    ref.read(notificationServiceProvider.notifier).showTransferStarted(filename);
  }

  Future<void> _handleSenderConnection() async {
    state = state!.copyWith(status: TransferStatus.handshake);
    ref.read(discoveryServiceProvider.notifier).stopBroadcasting();

    try {
      final cryptoService = ref.read(cryptoServiceProvider.notifier);
      final keyPair = await cryptoService.generateKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      
      final myDeviceName = ref.read(settingsServiceProvider).valueOrNull?.deviceName ?? 'Kappogy Sender';

      _channel!.sink.add(jsonEncode({
        'type': 'handshake',
        'publicKey': publicKey.bytes,
        'deviceName': myDeviceName,
      }));

      _channel!.stream.listen((message) async {
        if (message is String) {
          if (state?.status == TransferStatus.handshake) {
            final data = jsonDecode(message);
            if (data['type'] == 'handshake') {
              final remotePubKeyBytes = List<int>.from(data['publicKey']);
              final remoteDeviceName = data['deviceName'] as String?;
              _sharedSecret = await cryptoService.deriveSharedSecret(keyPair, remotePubKeyBytes);
              
              state = state!.copyWith(remoteDeviceName: remoteDeviceName);
              await _sendMetadata();
            }
          } else if (state?.status == TransferStatus.transferring) {
              final data = jsonDecode(message);
              if (data['type'] == 'metadata_ack') {
                 final offsets = List<int>.from(data['offsets'] ?? []);
                 _startSendingFiles(offsets: offsets);
              } else if (data['type'] == 'clipboard_encrypted') {
                 await _handleClipboardEncrypted(data, cryptoService);
              } else if (data['type'] == 'chat_encrypted') {
                 await _handleChatEncrypted(data, cryptoService);
              }
           }
         }
      }, onDone: () {
        if (state?.status != TransferStatus.completed) {
          state = state!.copyWith(status: TransferStatus.failed, errorMessage: 'Connection closed prematurely');
          _logHistory();
        }
      });

    } catch (e) {
      state = state!.copyWith(status: TransferStatus.failed, errorMessage: e.toString());
      _logHistory();
    }
  }

  Future<void> _sendMetadata() async {
    final metadata = state!.files.map((f) => {'name': f.name, 'size': f.size}).toList();
    
    final cryptoService = ref.read(cryptoServiceProvider.notifier);
    final jsonMetadata = jsonEncode({'type': 'metadata', 'files': metadata});
    final secretBox = await cryptoService.encryptData(utf8.encode(jsonMetadata), _sharedSecret!);

    _channel!.sink.add(jsonEncode({
      'type': 'metadata_encrypted',
      'cipherText': secretBox.cipherText,
      'nonce': secretBox.nonce,
      'mac': secretBox.mac.bytes,
    }));
    
    state = state!.copyWith(status: TransferStatus.transferring);
    _startSpeedTicker();
  }

  Future<void> _startSendingFiles({List<int>? offsets}) async {
    final cryptoService = ref.read(cryptoServiceProvider.notifier);
    
    int initialTransferred = offsets != null ? offsets.fold(0, (sum, offset) => sum + offset) : 0;
    state = state!.copyWith(transferredBytes: initialTransferred);
    
    for (int i = 0; i < state!.files.length; i++) {
      var file = state!.files[i];
      final dartFile = File(file.path);
      
      final offset = (offsets != null && i < offsets.length) ? offsets[i] : 0;
      final stream = dartFile.openRead(offset);
      
      await for (final chunk in stream) {
        final secretBox = await cryptoService.encryptData(chunk, _sharedSecret!);
        
        final bytesBuilder = BytesBuilder();
        bytesBuilder.addByte(0);
        bytesBuilder.addByte(i);
        bytesBuilder.add(secretBox.nonce);
        bytesBuilder.add(secretBox.mac.bytes);
        bytesBuilder.add(secretBox.cipherText);
        
        _channel!.sink.add(bytesBuilder.toBytes());
        
        state = state!.copyWith(transferredBytes: state!.transferredBytes + chunk.length);
      }
      
      final bytes = await dartFile.readAsBytes();
      final hash = cryptoService.calculateSha256(bytes);
      _channel!.sink.add(jsonEncode({
        'type': 'file_complete',
        'fileIndex': i,
        'hash': hash,
      }));
    }
    
    state = state!.copyWith(status: TransferStatus.completed);
    _logHistory();
    final filename = state!.files.length == 1 ? state!.files.first.name : '${state!.files.length} files';
    ref.read(notificationServiceProvider.notifier).showTransferCompleted(filename);
  }

  Future<void> startAsReceiver(String pin) async {
    await _cleanup();
    state = TransferSession(
      id: const Uuid().v4(),
      pin: pin,
      role: TransferRole.receiver,
      status: TransferStatus.initializing,
      createdAt: DateTime.now(),
    );

    final discoveryService = ref.read(discoveryServiceProvider.notifier);
    await for (final service in discoveryService.discoverTransfers(pin)) {
      if (service.host != null && service.port != null) {
        _connectToSender(service.host!, service.port!);
        discoveryService.stopDiscovering();
        break;
      }
    }
  }

  Future<void> _connectToSender(String host, int port) async {
    state = state!.copyWith(status: TransferStatus.connecting);
    
    try {
      final uri = Uri.parse('ws://$host:$port/ws');
      _channel = WebSocketChannel.connect(uri);
      
      final cryptoService = ref.read(cryptoServiceProvider.notifier);
      final keyPair = await cryptoService.generateKeyPair();
      final publicKey = await keyPair.extractPublicKey();

      state = state!.copyWith(status: TransferStatus.handshake);
      
      _channel!.stream.listen((message) async {
        if (message is String) {
          final data = jsonDecode(message);
          
          if (state?.status == TransferStatus.handshake) {
            if (data['type'] == 'handshake') {
              final remotePubKeyBytes = List<int>.from(data['publicKey']);
              final remoteDeviceName = data['deviceName'] as String?;
              _sharedSecret = await cryptoService.deriveSharedSecret(keyPair, remotePubKeyBytes);
              
              final myDeviceName = ref.read(settingsServiceProvider).valueOrNull?.deviceName ?? 'Kappogy Receiver';
              
              _channel!.sink.add(jsonEncode({
                'type': 'handshake',
                'publicKey': publicKey.bytes,
                'deviceName': myDeviceName,
              }));
              
              state = state!.copyWith(
                status: TransferStatus.transferring,
                remoteDeviceName: remoteDeviceName,
              );
              _startSpeedTicker();
            }
          } else if (state?.status == TransferStatus.transferring) {
            if (data['type'] == 'metadata_encrypted') {
              final secretBox = SecretBox(
                List<int>.from(data['cipherText']),
                nonce: List<int>.from(data['nonce']),
                mac: Mac(List<int>.from(data['mac'])),
              );
              final cleartext = await cryptoService.decryptData(secretBox, _sharedSecret!);
              final metadataJson = jsonDecode(utf8.decode(cleartext));
              
              final files = metadataJson['files'] as List<dynamic>;
              final kappogyFiles = <KappogyFile>[];
              int totalBytes = 0;
              
              final storageService = ref.read(storageServiceProvider.notifier);
              final offsets = <int>[];
              
              for (int i = 0; i < files.length; i++) {
                 final fileData = files[i];
                 final name = fileData['name'];
                 final size = fileData['size'];
                 totalBytes += size as int;
                 
                 final (sink, path, existingBytes) = await storageService.resumeOrCreateDownloadFile(name);
                 _activeSinks[i] = sink;
                 _downloadPaths[i] = path;
                 offsets.add(existingBytes);
                 
                 kappogyFiles.add(KappogyFile(
                   name: name,
                   size: size,
                   path: path,
                   isDirectory: false,
                 ));
              }
              
              int initialTransferred = offsets.fold(0, (sum, offset) => sum + offset);
              state = state!.copyWith(files: kappogyFiles, totalBytes: totalBytes, transferredBytes: initialTransferred);
              _channel!.sink.add(jsonEncode({'type': 'metadata_ack', 'offsets': offsets}));

            } else if (data['type'] == 'file_complete') {
               final fileIndex = data['fileIndex'] as int;
               final senderHash = data['hash'] as String;
               
               await _activeSinks[fileIndex]?.close();
               _activeSinks.remove(fileIndex);
               
               final savedPath = _downloadPaths[fileIndex];
               if (savedPath != null) {
                 final originalName = state!.files[fileIndex].name;
                 final finalPath = await ref.read(storageServiceProvider.notifier).finalizeDownloadFile(savedPath, originalName);
                 _downloadPaths[fileIndex] = finalPath;
                 
                 final bytes = await File(finalPath).readAsBytes();
                 final localHash = cryptoService.calculateSha256(bytes);
                 if (localHash != senderHash) {
                    state = state!.copyWith(status: TransferStatus.failed, errorMessage: 'Hash mismatch for file index $fileIndex');
                    _logHistory();
                    return;
                 }
                 
                 if (finalPath.endsWith('.zip')) {
                    final outDir = p.join(
                      (await ref.read(storageServiceProvider.notifier).getDownloadsDir()).path, 
                      p.basenameWithoutExtension(finalPath)
                    );
                    await compute(_extractZip, {'source': finalPath, 'destination': outDir});
                 }
               }
               
               if (_activeSinks.isEmpty) {
                 state = state!.copyWith(
                   status: TransferStatus.completed,
                   transferredBytes: state!.totalBytes,
                 );\n                 _logHistory();
                 final filename = state!.files.length == 1 ? state!.files.first.name : '${state!.files.length} files';
                 ref.read(notificationServiceProvider.notifier).showTransferCompleted(filename);
               }
             } else if (data['type'] == 'clipboard_encrypted') {
                await _handleClipboardEncrypted(data, cryptoService);
             } else if (data['type'] == 'chat_encrypted') {
                await _handleChatEncrypted(data, cryptoService);
             }
          }
        } else if (message is List<int>) {
           if (state?.status == TransferStatus.transferring) {
             final type = message[0];
             if (type == 0) {
                final fileIndex = message[1];
                final nonce = message.sublist(2, 14);
                final macBytes = message.sublist(14, 30);
                final cipherText = message.sublist(30);
                
                final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
                final cleartext = await cryptoService.decryptData(secretBox, _sharedSecret!);
                
                final sink = _activeSinks[fileIndex];
                if (sink != null) {
                  sink.add(cleartext);
                }
                
                state = state!.copyWith(transferredBytes: state!.transferredBytes + cleartext.length);
             }
           }
        }
      }, onDone: () {
        if (state?.status != TransferStatus.completed) {
          state = state!.copyWith(status: TransferStatus.failed, errorMessage: 'Connection closed prematurely');
        }
      });

    } catch (e) {
      state = state!.copyWith(status: TransferStatus.failed, errorMessage: e.toString());
    }
  }

  Future<void> connectToSender(String pin, String host, int port) async {
    await _cleanup();
    state = TransferSession(
      id: const Uuid().v4(),
      pin: pin,
      role: TransferRole.receiver,
      status: TransferStatus.initializing,
      createdAt: DateTime.now(),
    );
    await _connectToSender(host, port);
  }

  void cancelTransfer() {
    _cleanup();
  }

  Future<void> _handleClipboardEncrypted(Map<String, dynamic> data, CryptoService cryptoService) async {
    try {
      final secretBox = SecretBox(
        List<int>.from(data['cipherText']),
        nonce: List<int>.from(data['nonce']),
        mac: Mac(List<int>.from(data['mac'])),
      );
      final cleartext = await cryptoService.decryptData(secretBox, _sharedSecret!);
      final payloadJson = jsonDecode(utf8.decode(cleartext));
      
      if (payloadJson['type'] == 'clipboard') {
        final text = payloadJson['text'] as String;\n        await Clipboard.setData(ClipboardData(text: text));
        ref.read(notificationServiceProvider.notifier).showTransferCompleted('Copied text to clipboard');
      }
    } catch (e) {
      debugPrint('Clipboard decryption failed: $e');
    }
  }

  Future<void> sendClipboard(String text) async {
    if (state == null || state!.status != TransferStatus.transferring || _sharedSecret == null) {
      return;
    }
    final cryptoService = ref.read(cryptoServiceProvider.notifier);
    final jsonPayload = jsonEncode({'type': 'clipboard', 'text': text});
    final secretBox = await cryptoService.encryptData(utf8.encode(jsonPayload), _sharedSecret!);

    _channel!.sink.add(jsonEncode({
      'type': 'clipboard_encrypted',
      'cipherText': secretBox.cipherText,
      'nonce': secretBox.nonce,
      'mac': secretBox.mac.bytes,
    }));
  }

  Future<void> _handleChatEncrypted(Map<String, dynamic> data, CryptoService cryptoService) async {
    try {
      final secretBox = SecretBox(
        List<int>.from(data['cipherText']),
        nonce: List<int>.from(data['nonce']),
        mac: Mac(List<int>.from(data['mac'])),
      );
      final cleartext = await cryptoService.decryptData(secretBox, _sharedSecret!);
      final payloadJson = jsonDecode(utf8.decode(cleartext));
      
      if (payloadJson['type'] == 'chat') {
        final text = payloadJson['text'] as String;
        final timestamp = DateTime.parse(payloadJson['timestamp']);
        
        final msg = ChatMessage(text: text, isFromMe: false, timestamp: timestamp);
        
        state = state!.copyWith(
          chatMessages: [...state!.chatMessages, msg],
          hasUnreadChatMessages: true,
        );
        ref.read(notificationServiceProvider.notifier).showTransferStarted('New message: $text');
      }
    } catch (e) {
      debugPrint('Chat decryption failed: $e');
    }
  }

  Future<void> sendChatMessage(String text) async {
    if (state == null || _sharedSecret == null) return;
    
    final timestamp = DateTime.now();
    final msg = ChatMessage(text: text, isFromMe: true, timestamp: timestamp);
    state = state!.copyWith(chatMessages: [...state!.chatMessages, msg]);
    
    final cryptoService = ref.read(cryptoServiceProvider.notifier);
    final jsonPayload = jsonEncode({
       'type': 'chat',
       'text': text,
       'timestamp': timestamp.toIso8601String(),
    });
    final secretBox = await cryptoService.encryptData(utf8.encode(jsonPayload), _sharedSecret!);

    _channel?.sink.add(jsonEncode({
      'type': 'chat_encrypted',
      'cipherText': secretBox.cipherText,
      'nonce': secretBox.nonce,
      'mac': secretBox.mac.bytes,
    }));
  }

  void markChatAsRead() {
    if (state != null) {
      state = state!.copyWith(hasUnreadChatMessages: false);
    }
  }

  String _generateWebInterface() {
    final filename = state?.files.isNotEmpty == true ? state!.files.first.name : 'Unknown File';
    final filesize = state?.files.isNotEmpty == true ? (state!.files.first.size / (1024 * 1024)).toStringAsFixed(2) : '0';
    return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kappogy Share - Web Receiver</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background-color: #f4f4f5; color: #18181b; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; }
        .card { background: white; padding: 2rem; border-radius: 12px; box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1); text-align: center; max-width: 400px; width: 90%; }
        h1 { margin-top: 0; color: #4f46e5; }
        .file-info { background: #f3f4f6; padding: 1rem; border-radius: 8px; margin: 1.5rem 0; word-break: break-all; }
        .btn { display: inline-block; background-color: #4f46e5; color: white; padding: 0.75rem 1.5rem; text-decoration: none; border-radius: 8px; font-weight: 600; transition: background-color 0.2s; }
        .btn:hover { background-color: #4338ca; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Kappogy Share</h1>
        <p>A file has been shared with you over the local network.</p>
        <div class="file-info">
            <strong>$filename</strong><br/>
            <small>${filesize} MB</small>
        </div>
        <a href="/download" class="btn">Download File</a>
    </div>
</body>
</html>''';
  }
}

void _extractZip(Map<String, String> args) {
  extractFileToDisk(args['source']!, args['destination']!);
}
