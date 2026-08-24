import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/ui_helpers.dart';
import '../../application/transfer_engine.dart';
import 'sender_waiting_screen.dart';

class MyLinkScreen extends ConsumerWidget {
  const MyLinkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localIpAsync = ref.watch(localIpProvider);
    final port = ref.read(transferEngineProvider.notifier).serverPort ?? 8080;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Link (Web Share)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'How it works',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('About My Link Web Sharing'),
                  content: const Text(
                    'My Link lets anyone on your local Wi-Fi or Hotspot download files directly using their web browser (Chrome, Safari, Firefox, Edge) \u2014 no app installation required!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: localIpAsync.when(
        data: (ip) {
          final shareUrl = 'http://$ip:$port';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? const LinearGradient(
                                colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? AppColors.primaryLight.withAlpha(50)
                              : AppColors.primary.withAlpha(30),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppGradients.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.wifi_tethering_rounded,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [\n                                const Text(
                                  'Web Server Active',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Share files with iOS, Mac, PC, TV, Linux without installing the app.',
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(60),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(isDark ? 60 : 30),
                            blurRadius: 28,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: shareUrl,
                        version: QrVersions.auto,
                        size: 200.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.primaryDark,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : AppColors.lightCardBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'OPEN THIS LINK IN ANY WEB BROWSER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SelectableText(
                                shareUrl,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryLight,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                tooltip: 'Copy Link',
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: shareUrl));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Link copied: $shareUrl'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : AppColors.lightCardBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '3 Quick Steps',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildStepRow(
                            '1',
                            'Connect',
                            'Make sure both devices are connected to the same Wi-Fi network (or connect the other device to this phone\'s hotspot).',
                            isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildStepRow(
                            '2',
                            'Scan or Type',
                            'Scan the QR code with phone camera or type the URL into Chrome/Safari.',
                            isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildStepRow(
                            '3',
                            'Download & Share',
                            'Instantly download queued files or upload files straight to this device.',
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStepRow(
      String number, String title, String description, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(30),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryLight,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
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
      ],
    );
  }
}
