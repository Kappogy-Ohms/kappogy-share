import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/ui_helpers.dart';
import '../../../../core/widgets/pin_code_field.dart';
import '../../application/discovery_service.dart';
import '../../application/transfer_engine.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<PinCodeFieldState> _pinKey = GlobalKey<PinCodeFieldState>();
  late final TabController _tabController;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _isConnecting = false;
  bool _torchEnabled = false;
  String? _errorMessage;
  String _currentPin = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoveryServiceProvider.notifier).startDiscoveringAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _connectToPin(String pin) async {
    if (pin.length != 6) {
      setState(() => _errorMessage = 'Please enter a complete 6-digit PIN.');
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final services = ref.read(discoveryServiceProvider).services;
      final match = services.firstWhere(
        (s) => s.name?.contains(pin) ?? false,
        orElse: () => throw Exception('No sender found broadcasting PIN $pin on this local Wi-Fi network.'),
      );

      if (match.host == null || match.port == null) {
        throw Exception('Device discovered but network address is unreachable.');
      }

      await ref.read(transferEngineProvider.notifier).connectToSender(
            pin,
            match.host!,
            match.port!,
          );

      if (mounted) {
        context.go('/transfer-progress');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _handleQrCode(String rawCode) {
    if (_isConnecting) return;

    try {
      final uri = Uri.parse(rawCode);
      if (uri.scheme == 'kappogy') {
        final ip = uri.queryParameters['ip'];
        final portStr = uri.queryParameters['port'];
        final pin = uri.queryParameters['pin'];

        if (ip != null && portStr != null && pin != null) {
          final port = int.parse(portStr);
          setState(() {
            _isConnecting = true;
            _errorMessage = null;
          });
          ref.read(transferEngineProvider.notifier).connectToSender(pin, ip, port).then((_) {
            if (mounted) context.go('/transfer-progress');
          }).catchError((err) {
            if (mounted) {
              setState(() {
                _isConnecting = false;
                _errorMessage = 'QR Connection failed: $err';
              });
            }
          });
          return;
        }

        if (pin != null && pin.length == 6) {
          _connectToPin(pin);
          return;
        }
      }

      final clean = rawCode.replaceAll(RegExp(r'\D'), '');
      if (clean.length == 6) {
        _connectToPin(clean);
        return;
      }

      setState(() => _errorMessage = 'Invalid Kappogy QR code format.');
    } catch (e) {
      setState(() => _errorMessage = 'Error parsing QR code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(discoveryServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Files'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryLight,
          indicatorWeight: 3,
          labelColor: isDark ? Colors.white : AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.pin_rounded), text: 'Enter PIN'),
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Scan QR Code'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppGradients.amberGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warning.withAlpha(80),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.pin_rounded, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Enter 6-Digit Transfer PIN',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Ask the sender for the PIN generated on their screen',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: PinCodeField(
                  key: _pinKey,
                  length: 6,
                  onChanged: (val) {
                    setState(() {
                      _currentPin = val;
                      _errorMessage = null;
                    });
                  },
                  onCompleted: (val) => _connectToPin(val),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.content_paste_rounded, size: 18),
                  label: const Text('Paste PIN from Clipboard'),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _pinKey.currentState?.setPin(data!.text!);
                    }
                  },
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  icon: _isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.link_rounded),
                  label: Text(_isConnecting ? 'Connecting...' : 'Connect & Receive'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _isConnecting || _currentPin.length != 6
                      ? null
                      : () => _connectToPin(_currentPin),
                ),
              ),
              const SizedBox(height: 48),
              if (state.services.isNotEmpty) ...[
                const Text(
                  'Nearby Broadcasting Senders',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...state.services.map((service) {
                  String name = service.name ?? '';
                  String pin = name.replaceAll('kappogy_', '');
                  String deviceName = 'Nearby Sender';
                  if (service.txt != null && service.txt!.containsKey('deviceName')) {
                    final list = service.txt!['deviceName'];
                    if (list != null) deviceName = utf8.decode(list);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.wifi_tethering_rounded, color: AppColors.accent, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(deviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('PIN: $pin', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => _pinKey.currentState?.setPin(pin),
                          child: const Text('Use PIN'),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
          Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _handleQrCode(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primaryLight, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(80),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 32,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Point camera at the sender\'s QR code',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      icon: Icon(_torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded),
                      onPressed: () {
                        _scannerController.toggleTorch();
                        setState(() => _torchEnabled = !_torchEnabled);
                      },
                      tooltip: 'Toggle Flash',
                    ),
                    const SizedBox(width: 20),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.cameraswitch_rounded),
                      onPressed: () => _scannerController.switchCamera(),
                      tooltip: 'Switch Camera',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
