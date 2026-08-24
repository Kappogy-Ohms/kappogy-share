import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ui_helpers.dart';
import '../../application/discovery_service.dart';
import '../../application/transfer_engine.dart';
import 'sender_waiting_screen.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  bool _isConnecting = false;
  String? _connectingDeviceName;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoveryServiceProvider.notifier).startDiscoveringAll();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _connectToDevice(String pin, String host, int port, String deviceName) async {
    setState(() {
      _isConnecting = true;
      _connectingDeviceName = deviceName;
    });

    try {
      await ref.read(transferEngineProvider.notifier).connectToSender(pin, host, port);
      if (mounted) {
        context.go('/transfer-progress');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingDeviceName = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  IconData _getDeviceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('windows') || lower.contains('pc') || lower.contains('desktop') || lower.contains('laptop')) {
      return Icons.laptop_windows_rounded;
    }
    if (lower.contains('android') || lower.contains('galaxy') || lower.contains('pixel') || lower.contains('phone')) {
      return Icons.phone_android_rounded;
    }
    if (lower.contains('mac') || lower.contains('iphone') || lower.contains('ipad') || lower.contains('apple')) {
      return Icons.apple_rounded;
    }
    if (lower.contains('linux')) {
      return Icons.terminal_rounded;
    }
    return Icons.devices_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(discoveryServiceProvider);
    final myIp = ref.watch(localIpProvider).valueOrNull ?? 'Detecting...';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Network Radar'),
        actions: [
          IconButton(
            icon: Icon(state.isDiscovering ? Icons.sync_rounded : Icons.sync_disabled_rounded),
            onPressed: () {
              if (state.isDiscovering) {
                ref.read(discoveryServiceProvider.notifier).stopDiscovering();
              } else {
                ref.read(discoveryServiceProvider.notifier).startDiscoveringAll();
              }
            },
            tooltip: state.isDiscovering ? 'Stop Scanning' : 'Restart Scan',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: state.isDiscovering ? AppColors.accent : Colors.grey,
                              shape: BoxShape.circle,
                              boxShadow: state.isDiscovering
                                  ? [
                                      BoxShadow(
                                        color: AppColors.accent.withAlpha(150),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            state.isDiscovering ? 'Broadcasting & Scanning' : 'Scan Paused',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      Text(
                        'IP: $myIp',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: const Size(double.infinity, double.infinity),
                                painter: _RadarPainter(
                                  progress: _animController.value,
                                  isDark: isDark,
                                ),
                              );
                            },
                          ),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppGradients.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(120),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                          ),
                          ...state.services.asMap().entries.map((entry) {
                            final index = entry.key;
                            final service = entry.value;

                            String name = service.name ?? '';
                            String pin = name.replaceAll('kappogy_', '');
                            String deviceName = 'Nearby Device';
                            if (service.txt != null && service.txt!.containsKey('deviceName')) {
                              final list = service.txt!['deviceName'];
                              if (list != null) {
                                deviceName = utf8.decode(list);
                              }
                            }

                            final count = state.services.length;
                            final angle = (index / count) * 2 * math.pi + (_animController.value * 0.2);
                            const radius = 100.0;
                            final dx = radius * math.cos(angle);
                            final dy = radius * math.sin(angle);

                            return Transform.translate(
                              offset: Offset(dx, dy),
                              child: Tooltip(
                                message: '$deviceName (PIN: $pin)',
                                child: InkWell(
                                  onTap: () {
                                    if (service.host != null && service.port != null) {
                                      _connectToDevice(pin, service.host!, service.port!, deviceName);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.emeraldGradient,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withAlpha(140),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _getDeviceIcon(deviceName),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Discovered Devices (${state.services.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (state.services.isNotEmpty)
                            const Text(
                              'Tap to connect',
                              style: TextStyle(fontSize: 12, color: AppColors.accent),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: state.services.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.radar_rounded,
                                      size: 36,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Looking for devices sharing on this network...',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: state.services.length,
                                itemBuilder: (context, index) {
                                  final service = state.services[index];
                                  String name = service.name ?? '';
                                  String pin = name.replaceAll('kappogy_', '');
                                  String deviceName = 'Nearby Device';
                                  if (service.txt != null && service.txt!.containsKey('deviceName')) {
                                    final list = service.txt!['deviceName'];
                                    if (list != null) {
                                      deviceName = utf8.decode(list);
                                    }
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkCard : AppColors.lightBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            gradient: AppGradients.cyanIndigoGradient,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            _getDeviceIcon(deviceName),
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                deviceName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'PIN: $pin \u2022 Host: ${service.host ?? "local"}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? AppColors.darkTextSecondary
                                                      : AppColors.lightTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        FilledButton.icon(
                                          icon: const Icon(Icons.link_rounded, size: 16),
                                          label: const Text('Connect'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: () {
                                            if (service.host != null && service.port != null) {
                                              _connectToDevice(pin, service.host!, service.port!, deviceName);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isConnecting)
            Container(
              color: Colors.black.withAlpha(160),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primaryLight),
                      const SizedBox(height: 20),
                      Text(
                        'Connecting to ${_connectingDeviceName ?? "device"}...',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Establishing encrypted P2P channel',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _RadarPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    final ringPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, (maxRadius / 3) * i, ringPaint);
    }

    final crossPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(center.dx - maxRadius, center.dy), Offset(center.dx + maxRadius, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius), Offset(center.dx, center.dy + maxRadius), crossPaint);

    final pulseRadius = (progress * maxRadius);
    final pulsePaint = Paint()
      ..color = AppColors.primaryLight.withAlpha(((1 - progress) * 80).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, pulseRadius, pulsePaint);

    final sweepAngle = progress * 2 * math.pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi / 3,
        colors: [
          AppColors.primaryLight.withAlpha(100),
          AppColors.primaryLight.withAlpha(0),
        ],
        transform: GradientRotation(sweepAngle - math.pi / 3),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, sweepPaint);

    final lineEnd = Offset(
      center.dx + maxRadius * math.cos(sweepAngle),
      center.dy + maxRadius * math.sin(sweepAngle),
    );
    final leadLinePaint = Paint()
      ..color = AppColors.primaryLight.withAlpha(180)
      ..strokeWidth = 2.0;
    canvas.drawLine(center, lineEnd, leadLinePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
