import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kappogy_share/features/transfer/application/transfer_engine.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _isProcessing = false;

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.startsWith('kappogy://connect')) {
        setState(() {
          _isProcessing = true;
        });
        
        try {
          final uri = Uri.parse(code);
          final ip = uri.queryParameters['ip'];
          final portStr = uri.queryParameters['port'];
          final pin = uri.queryParameters['pin'];

          if (ip != null && portStr != null && pin != null) {
            final port = int.tryParse(portStr);
            if (port != null) {
              ref.read(transferEngineProvider.notifier).connectToSender(pin, ip, port);
              context.go('/transfer-progress');
              return;
            }
          }
        } catch (e) {
          debugPrint('Error parsing QR code: $e');
        }

        setState(() {
          _isProcessing = false;
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid QR code')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
