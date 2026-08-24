import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/ui_helpers.dart';
import '../../application/transfer_engine.dart';
import '../../domain/models/transfer_session.dart';
import '../../application/trusted_devices_service.dart';

class TransferProgressScreen extends ConsumerWidget {
  const TransferProgressScreen({super.key});

  String _formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) return '$bytesPerSecond B/s';
    if (bytesPerSecond < 1024 * 1024) return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return 'Calculating...';
    if (seconds < 60) return '${seconds}s left';
    if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s left';
    return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m left';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transferState = ref.watch(transferEngineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live P2P Transfer'),
        automaticallyImplyLeading: false,
        actions: [
          if (transferState != null && transferState.status == TransferStatus.transferring)
            TextButton.icon(
              icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 18),
              label: const Text('Cancel', style: TextStyle(color: AppColors.error)),
              onPressed: () {
                ref.read(transferEngineProvider.notifier).cancelTransfer();
                context.go('/home');
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: transferState == null
          ? const Center(child: Text('No active transfer session.'))\n          : _buildBody(context, ref, transferState, isDark),
      floatingActionButton: transferState != null &&
              (transferState.status == TransferStatus.transferring ||
                  transferState.status == TransferStatus.completed)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () {
                ref.read(transferEngineProvider.notifier).markChatAsRead();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const _ChatBottomSheet(),
                );
              },
              icon: Badge(
                isLabelVisible: transferState.hasUnreadChatMessages,
                child: const Icon(Icons.chat_bubble_rounded),
              ),
              label: const Text('Peer Chat'),
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TransferSession transferState,
    bool isDark,
  ) {
    switch (transferState.status) {
      case TransferStatus.transferring:
        return _buildTransferringView(context, ref, transferState, isDark);
      case TransferStatus.completed:
        return _buildCompletedView(context, ref, transferState, isDark);
      case TransferStatus.failed:
        return _buildFailedView(context, ref, transferState, isDark);
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryLight),
              const SizedBox(height: 24),
              Text(
                'Connecting and negotiating handshake...',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildTransferringView(
    BuildContext context,
    WidgetRef ref,
    TransferSession transferState,
    bool isDark,
  ) {
    final percent = transferState.totalBytes > 0
        ? (transferState.transferredBytes / transferState.totalBytes).clamp(0.0, 1.0)
        : 0.0;
    final percentInt = (percent * 100).toInt();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppGradients.cyanIndigoGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.devices_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transferState.remoteDeviceName ?? 'Connected Peer',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.lock_rounded, size: 12, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          'ChaCha20-Poly1305 Encrypted',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withAlpha(100)),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFEEF2FF), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.primaryLight.withAlpha(60) : AppColors.primary.withAlpha(40),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(isDark ? 40 : 20),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  Text(
                    '$percentInt%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryLight,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percent > 0 ? percent : null,
                  minHeight: 14,
                  backgroundColor: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(20),
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatBytes(transferState.transferredBytes)} of ${_formatBytes(transferState.totalBytes)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    _formatDuration(transferState.estimatedTimeRemainingSeconds),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.accent),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (transferState.speedHistory.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.speed_rounded, size: 18, color: AppColors.primaryLight),
                        SizedBox(width: 8),
                        Text(
                          'Throughput Speed',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatSpeed(transferState.currentSpeedBytesPerSecond),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [\n                        LineChartBarData(
                          spots: transferState.speedHistory.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value);
                          }).toList(),
                          isCurved: true,
                          color: AppColors.primaryLight,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryLight.withAlpha(100),
                                AppColors.primaryLight.withAlpha(0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      minX: 0,
                      maxX: 60,
                      minY: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        OutlinedButton.icon(
          icon: const Icon(Icons.content_paste_rounded, size: 18),
          label: const Text('Send Clipboard Text to Peer'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data?.text != null && data!.text!.isNotEmpty) {
              ref.read(transferEngineProvider.notifier).sendClipboard(data.text!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Clipboard text sent to peer!')),
                );
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Clipboard is empty.')),
                );
              }
            }
          },
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildCompletedView(
    BuildContext context,
    WidgetRef ref,
    TransferSession transferState,
    bool isDark,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: AppGradients.emeraldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withAlpha(120),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 28),
              const Text(
                'Transfer Complete!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All files transferred successfully with zero errors.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Total Payload',
                      _formatBytes(transferState.totalBytes),
                      isDark,
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      'Files Count',
                      '${transferState.files.length} items',
                      isDark,
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      'Connected Peer',
                      transferState.remoteDeviceName ?? 'Peer Device',
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (transferState.remoteDeviceName != null) ...[
                _TrustDeviceWidget(deviceName: transferState.remoteDeviceName!),
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Back to Dashboard'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    ref.read(transferEngineProvider.notifier).cancelTransfer();
                    context.go('/home');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFailedView(
    BuildContext context,
    WidgetRef ref,
    TransferSession transferState,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'Transfer Failed or Interrupted',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              transferState.errorMessage ?? 'Connection timed out or network connection was lost.',
              style: const TextStyle(color: AppColors.error, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                ref.read(transferEngineProvider.notifier).cancelTransfer();
                context.go('/home');
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustDeviceWidget extends ConsumerWidget {
  final String deviceName;
  const _TrustDeviceWidget({required this.deviceName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustedDevicesAsync = ref.watch(trustedDevicesServiceProvider);

    return trustedDevicesAsync.when(
      data: (devices) {
        final isTrusted = devices.contains(deviceName);
        return SwitchListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCard
              : AppColors.lightCard,
          title: const Text('Trust this device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: const Text('Auto-accept future incoming transfers from this peer', style: TextStyle(fontSize: 12)),
          value: isTrusted,
          onChanged: (val) {
            if (val) {
              ref.read(trustedDevicesServiceProvider.notifier).addTrustedDevice(deviceName);
            } else {
              ref.read(trustedDevicesServiceProvider.notifier).removeTrustedDevice(deviceName);
            }
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ChatBottomSheet extends ConsumerStatefulWidget {
  const _ChatBottomSheet();

  @override
  ConsumerState<_ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends ConsumerState<_ChatBottomSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transferState = ref.watch(transferEngineProvider);
    final messages = transferState?.chatMessages ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AppBar(
            title: Text(transferState?.remoteDeviceName ?? 'Peer Chat'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text('No messages yet. Send encrypted notes to your peer!'),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[messages.length - 1 - index];
                      return Align(
                        alignment: msg.isFromMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: msg.isFromMe ? AppGradients.primaryGradient : null,
                            color: msg.isFromMe
                                ? null
                                : (isDark ? AppColors.darkCard : AppColors.lightCard),
                            borderRadius: BorderRadius.circular(18),
                            border: msg.isFromMe
                                ? null
                                : Border.all(
                                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                                  ),
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color: msg.isFromMe
                                  ? Colors.white
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type an encrypted note...',
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        ref.read(transferEngineProvider.notifier).sendChatMessage(val);
                        _controller.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    final val = _controller.text;
                    if (val.trim().isNotEmpty) {
                      ref.read(transferEngineProvider.notifier).sendChatMessage(val);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
