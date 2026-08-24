import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/ui_helpers.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../file_management/application/file_picker_service.dart';
import '../../file_management/domain/models/kappogy_file.dart';
import '../../file_management/presentation/widgets/drag_drop_zone.dart';
import '../../transfer/application/transfer_engine.dart';
import '../../transfer/presentation/screens/sender_waiting_screen.dart';
import '../../settings/application/settings_service.dart';
import '../../../core/network/network_info_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _handleFilesPicked(BuildContext context, WidgetRef ref, List<KappogyFile> files) async {
    if (files.isEmpty) return;
    await ref.read(transferEngineProvider.notifier).startAsSender(files);
    if (context.mounted) {
      context.go('/sender-waiting');
    }
  }

  void _showGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.rocket_launch_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('How Kappogy Share Works'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideStep(
                context,
                step: '1',
                title: 'Send Files or Folders',
                description: 'Pick files, select a folder, or drag & drop onto the window. A secure 6-digit PIN and QR code are instantly created.',
                icon: Icons.upload_file_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              _buildGuideStep(
                context,
                step: '2',
                title: 'Receive & Connect',
                description: 'On the other device, enter the 6-digit PIN, scan the QR code, or use Radar discovery to auto-pair.',
                icon: Icons.download_rounded,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 16),
              _buildGuideStep(
                context,
                step: '3',
                title: 'Encrypted High-Speed P2P',
                description: 'Data streams directly across your local network with end-to-end ChaCha20-Poly1305 encryption at max Wi-Fi speed.',
                icon: Icons.shield_rounded,
                color: AppColors.accent,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it, let\'s share!'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(
    BuildContext context, {
    required String step,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
            border: Border.all(color: color.withAlpha(100)),
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(networkInfoServiceProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.share_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Kappogy Share'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showGuideDialog(context),
            tooltip: 'Quick Guide',
          ),
          IconButton(
            icon: const Icon(Icons.radar_rounded),
            onPressed: () => context.go('/radar'),
            tooltip: 'Radar (Nearby Devices)',
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.go('/history'),
            tooltip: 'Transfer History',
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6_rounded),
            onPressed: () {
              ref.read(themeModeNotifierProvider.notifier).toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.go('/settings'),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (!isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(25),
                border: const Border(bottom: BorderSide(color: AppColors.warning, width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No local network detected. Connect to Wi-Fi or Mobile Hotspot for high-speed P2P transfers.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: DragDropZone(
              onFilesDropped: (files) => _handleFilesPicked(context, ref, files),
              child: ResponsiveLayout(
                mobile: _MobileHome(
                  onFilesPicked: (files) => _handleFilesPicked(context, ref, files),
                ),
                tablet: _TabletHome(
                  onFilesPicked: (files) => _handleFilesPicked(context, ref, files),
                ),
                desktop: _DesktopHome(
                  onFilesPicked: (files) => _handleFilesPicked(context, ref, files),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceHeroCard extends ConsumerWidget {
  const _DeviceHeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsServiceProvider).valueOrNull;
    final deviceName = settings?.deviceName ?? (Platform.isWindows ? 'Windows PC' : 'My Device');
    final ipAsync = ref.watch(localIpProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppGradients.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(100),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(
              Platform.isWindows
                  ? Icons.laptop_windows_rounded
                  : (Platform.isAndroid ? Icons.phone_android_rounded : Icons.devices_rounded),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      deviceName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accent.withAlpha(100)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: AppColors.accent),
                          SizedBox(width: 4),
                          Text(
                            'Ready',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ipAsync.when(
                  data: (ip) => InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: ip));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('IP address copied: $ip')),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_rounded,
                          size: 14,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'IP: $ip',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.copy_rounded,
                          size: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ],
                    ),
                  ),
                  loading: () => const Text('Detecting local IP...', style: TextStyle(fontSize: 12)),
                  error: (_, __) => const Text('Local network only', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.diagonal3Values(_isHovered ? 1.02 : 1.0, _isHovered ? 1.02 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _isHovered
                ? AppColors.primaryLight
                : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? AppColors.primary.withAlpha(60)
                  : Colors.black.withAlpha(isDark ? 40 : 10),
              blurRadius: _isHovered ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient.colors.first.withAlpha(80),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarBanner extends StatelessWidget {
  const _RadarBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.accent.withAlpha(isDark ? 80 : 120),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withAlpha(30),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => context.go('/radar'),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withAlpha(100),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.radar_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Radar Discovery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Find and connect to nearby devices on this Wi-Fi network',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(isDark ? 30 : 180),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Scan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileHome extends ConsumerStatefulWidget {
  final ValueChanged<List<KappogyFile>> onFilesPicked;
  const _MobileHome({required this.onFilesPicked});

  @override
  ConsumerState<_MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends ConsumerState<_MobileHome> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        const _DeviceHeroCard(),
        const SizedBox(height: 20),
        const _RadarBanner(),
        const SizedBox(height: 24),
        const Text(
          'Transfer Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          title: 'Send Files',
          subtitle: 'Select images, videos, audio, or documents',
          icon: Icons.upload_file_rounded,
          gradient: AppGradients.primaryGradient,
          onTap: () async {
            try {
              final files = await ref.read(filePickerServiceProvider).pickFiles();
              if (!mounted) return;
              widget.onFilesPicked(files);
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
        ),
        const SizedBox(height: 12),
        _ActionTile(
          title: 'Send Folder',
          subtitle: 'Share an entire directory structure',
          icon: Icons.folder_copy_rounded,
          gradient: AppGradients.cyanIndigoGradient,
          onTap: () async {
            try {
              final folder = await ref.read(filePickerServiceProvider).pickFolder();
              if (!mounted) return;
              if (folder != null) widget.onFilesPicked([folder]);
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
        ),
        const SizedBox(height: 12),
        _ActionTile(
          title: 'Receive via PIN',
          subtitle: 'Enter sender\'s 6-digit session code',
          icon: Icons.pin_rounded,
          gradient: AppGradients.amberGradient,
          onTap: () => context.go('/receive'),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          title: 'Scan QR Code',
          subtitle: 'Fast camera pairing with sender',
          icon: Icons.qr_code_scanner_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.go('/scan-qr'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _TabletHome extends ConsumerWidget {
  final ValueChanged<List<KappogyFile>> onFilesPicked;
  const _TabletHome({required this.onFilesPicked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const _DeviceHeroCard(),
        const SizedBox(height: 20),
        const _RadarBanner(),
        const SizedBox(height: 28),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            _ActionTile(
              title: 'Send Files',
              subtitle: 'Select any documents or media',
              icon: Icons.upload_file_rounded,
              gradient: AppGradients.primaryGradient,
              onTap: () async {
                final files = await ref.read(filePickerServiceProvider).pickFiles();
                if (context.mounted) onFilesPicked(files);
              },
            ),
            _ActionTile(
              title: 'Send Folder',
              subtitle: 'Select and send whole directory',
              icon: Icons.folder_copy_rounded,
              gradient: AppGradients.cyanIndigoGradient,
              onTap: () async {
                final folder = await ref.read(filePickerServiceProvider).pickFolder();
                if (context.mounted && folder != null) onFilesPicked([folder]);
              },
            ),
            _ActionTile(
              title: 'Receive via PIN',
              subtitle: 'Connect using 6-digit PIN',
              icon: Icons.pin_rounded,
              gradient: AppGradients.amberGradient,
              onTap: () => context.go('/receive'),
            ),
            _ActionTile(
              title: 'Scan QR Code',
              subtitle: 'Instant camera viewfinder scan',
              icon: Icons.qr_code_scanner_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
              ),
              onTap: () => context.go('/scan-qr'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DesktopHome extends ConsumerStatefulWidget {
  final ValueChanged<List<KappogyFile>> onFilesPicked;
  const _DesktopHome({required this.onFilesPicked});

  @override
  ConsumerState<_DesktopHome> createState() => _DesktopHomeState();
}

class _DesktopHomeState extends ConsumerState<_DesktopHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 260,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border(
              right: BorderSide(
                color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(80),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kappogy Share',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Ultra Fast P2P v1.0',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildNavItem(
                      index: 0,
                      label: 'Dashboard',
                      icon: Icons.dashboard_rounded,
                      onTap: () => setState(() => _selectedIndex = 0),
                    ),
                    _buildNavItem(
                      index: 1,
                      label: 'Radar (Nearby)',
                      icon: Icons.radar_rounded,
                      onTap: () => context.go('/radar'),
                    ),
                    _buildNavItem(
                      index: 2,
                      label: 'Receive Files',
                      icon: Icons.download_rounded,
                      onTap: () => context.go('/receive'),
                    ),
                    _buildNavItem(
                      index: 3,
                      label: 'Transfer History',
                      icon: Icons.history_rounded,
                      onTap: () => context.go('/history'),
                    ),
                    _buildNavItem(
                      index: 4,
                      label: 'Received Files',
                      icon: Icons.folder_shared_rounded,
                      onTap: () => context.go('/received-files'),
                    ),
                    _buildNavItem(
                      index: 5,
                      label: 'Settings',
                      icon: Icons.settings_rounded,
                      onTap: () => context.go('/settings'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
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
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'P2P Engine Active',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(32.0),
            children: [
              const _DeviceHeroCard(),
              const SizedBox(height: 24),
              const _RadarBanner(),
              const SizedBox(height: 32),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard.withAlpha(120) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(60),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.cloud_upload_rounded, size: 36, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Drag & Drop Files Anywhere Here',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'or click one of the quick action buttons below',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      title: 'Send Files',
                      subtitle: 'Browse files on this PC',
                      icon: Icons.upload_file_rounded,
                      gradient: AppGradients.primaryGradient,
                      onTap: () async {
                        final files = await ref.read(filePickerServiceProvider).pickFiles();
                        if (context.mounted) widget.onFilesPicked(files);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionTile(
                      title: 'Send Folder',
                      subtitle: 'Pick complete directory',
                      icon: Icons.folder_copy_rounded,
                      gradient: AppGradients.cyanIndigoGradient,
                      onTap: () async {
                        final folder = await ref.read(filePickerServiceProvider).pickFolder();
                        if (context.mounted && folder != null) widget.onFilesPicked([folder]);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionTile(
                      title: 'Receive via PIN',
                      subtitle: 'Enter 6-digit receiver code',
                      icon: Icons.pin_rounded,
                      gradient: AppGradients.amberGradient,
                      onTap: () => context.go('/receive'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        selected: isSelected,
        selectedTileColor: isDark ? AppColors.primary.withAlpha(40) : AppColors.primary.withAlpha(20),
        leading: Icon(
          icon,
          color: isSelected
              ? AppColors.primaryLight
              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : AppColors.primary)
                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
