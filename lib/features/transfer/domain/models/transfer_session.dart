import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kappogy_share/features/file_management/domain/models/kappogy_file.dart';

part 'transfer_session.freezed.dart';
part 'transfer_session.g.dart';

enum TransferRole {
  sender,
  receiver,
}

enum TransferStatus {
  initializing,
  waitingForConnection,
  connecting,
  handshake,
  transferring,
  completed,
  failed,
  cancelled,
}

@freezed
class TransferSession with _$TransferSession {
  const factory TransferSession({
    required String id,
    required String pin,
    required TransferRole role,
    @Default(TransferStatus.initializing) TransferStatus status,
    @Default([]) List<KappogyFile> files,
    @Default(0) int totalBytes,
    @Default(0) int transferredBytes,
    @Default(0) int currentSpeedBytesPerSecond,
    @Default(0) int averageSpeedBytesPerSecond,
    @Default([]) List<double> speedHistory,
    int? estimatedTimeRemainingSeconds,
    String? remoteDeviceName,
    @Default([]) List<ChatMessage> chatMessages,
    @Default(false) bool hasUnreadChatMessages,
    String? errorMessage,
    required DateTime createdAt,
  }) = _TransferSession;

  factory TransferSession.fromJson(Map<String, dynamic> json) =>
      _$TransferSessionFromJson(json);
}

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String text,
    required bool isFromMe,
    required DateTime timestamp,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
