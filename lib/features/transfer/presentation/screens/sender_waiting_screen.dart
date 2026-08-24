import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/ui_helpers.dart';
import '../../../file_management/domain/models/kappogy_file.dart';
import '../../application/transfer_engine.dart';
import '../../domain/models/transfer_session.dart';

final localIpProvider = FutureProvider<String>((ref) async {
  try {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (!addr.isLoopback && !addr.address.startsWith('169.254')) {
          return addr.address;
        }
      }
    }
  } catch (_) {}
  return '127.0.0.1';
});

class SenderWaitingScreen extends ConsumerWidget {
  const SenderWaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transferState = ref.watch(transferEngineProvider);

    ref.listen(transferEngineProvider, (previous, next) {
      if (previous?.status != next?.status &&
          (next?.status == TransferStatus.transferring || next?.status == TransferStatus.completed)) {
        context.go('/transfer-progress');
      }
    });

    final pin = transferState?.pin;
    final files = transferState?.files ?? [];

    if (pin == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Send Files')),
        body: const Center(
          child: Text('Session expired or no active transfer session found.'),
        ),
      );
    }

    final totalBytes = files.fold<int>(0, (sum, f) => sum + f.size);
    final formattedSize = totalBytes < 1024 * 1024
        ? '${(totalBytes / 1024).toStringAsFixed(1)} KB'
        : '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ready to Send'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(transferEngineProvider.notifier).cancelTransfer();
            context.go('/');
          },
          tooltip: 'Cancel Transfer',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(isDark ? 40 : 20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryLight.withAlpha(180),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Broadcasting on local Wi-Fi...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ref.watch(localIpProvider).when(
                  data: (ip) {
                    final port = ref.read(transferEngineProvider.notifier).serverPort;
                    final qrData = port != null
                        ? 'kappogy://connect?ip=$ip&port=$port&pin=$pin'
                        : 'kappogy://transfer?pin=$pin';

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.primary.withAlpha(60), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(isDark ? 60 : 30),
                            blurRadius: 28,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 220.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.primaryDark,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox(height: 220),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 40 : 10),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'OR ENTER THIS 6-DIGIT PIN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            pin,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8.0,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: pin));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('PIN copied to clipboard: $pin')),
                              );
                            },
                            tooltip: 'Copy PIN',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        '${files.length} ${files.length == 1 ? "File" : "Files"} Queued ($formattedSize)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: const Text('Tap to inspect file list', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      children: files.map((file) {
                        final info = FileTypeHelper.getInfo(file.name, isDirectory: file.isDirectory);
                        return ListTile(\n                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: info.gradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(info.icon, color: Colors.white, size: 16),
                          ),
                          title: Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          trailing: Text(
                            file.readableSize,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_rounded, size: 18),
                  label: const Text('Cancel Transfer Session'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withAlpha(100)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: () {
                    ref.read(transferEngineProvider.notifier).cancelTransfer();
                    context.go('/');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
