import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/ui_helpers.dart';
import '../../application/settings_service.dart';
import '../../../history/application/history_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(settingsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (_nameController.text.isEmpty && _nameController.text != profile.deviceName) {
            _nameController.text = profile.deviceName;
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              _buildSectionHeader('Device Identity', Icons.perm_identity_rounded),
              const SizedBox(height: 10),
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
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(80),
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
                              Text(
                                profile.deviceName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Platform.isWindows
                                    ? 'Windows 64-bit Device'
                                    : (Platform.isAndroid ? 'Android Device' : 'Cross-Platform Node'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Broadcast Device Name',
                        hintText: 'e.g. John\'s Laptop',
                        prefixIcon: const Icon(Icons.edit_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_circle_rounded, color: AppColors.accent),
                          onPressed: () {
                            final val = _nameController.text.trim();
                            if (val.isNotEmpty) {
                              ref.read(settingsServiceProvider.notifier).updateDeviceName(val);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Device name updated!')),
                              );
                            }
                          },
                        ),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          ref.read(settingsServiceProvider.notifier).updateDeviceName(val.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Device name updated!')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Appearance & Theme', Icons.palette_rounded),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                icon: Icon(Icons.auto_mode_rounded, size: 16),
                                label: Text('Auto'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_rounded, size: 16),
                                label: Text('Light'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_rounded, size: 16),
                                label: Text('Dark'),
                              ),
                            ],
                            selected: {profile.themeMode},
                            onSelectionChanged: (Set<ThemeMode> newSelection) {
                              ref.read(themeModeNotifierProvider.notifier).setThemeMode(newSelection.first);
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Dynamic Color (Material You)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                      subtitle: const Text('Extract accent colors dynamically from wallpaper (Android 12+ / Windows)'),
                      value: profile.dynamicColorEnabled,
                      onChanged: (val) {
                        ref.read(settingsServiceProvider.notifier).updateDynamicColor(val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('AMOLED Pure Black Mode', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                      subtitle: const Text('Use pitch-black (#000000) background for OLED battery savings'),
                      value: profile.amoledMode,
                      onChanged: (val) {
                        ref.read(settingsServiceProvider.notifier).updateAmoledMode(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Transfer & Security', Icons.security_rounded),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Auto-Accept Incoming Transfers', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                      subtitle: const Text('Automatically receive incoming files without prompt'),
                      value: profile.autoAcceptTransfers,
                      onChanged: (val) {
                        ref.read(settingsServiceProvider.notifier).updateAutoAccept(val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Auto-Accept from Trusted Devices', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                      subtitle: const Text('Only auto-accept files from devices marked as trusted'),
                      value: profile.autoAcceptTrusted,
                      onChanged: (val) {
                        ref.read(settingsServiceProvider.notifier).updateAutoAcceptTrusted(val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Discoverable by Nearby Devices', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                      subtitle: const Text('Allow other Kappogy Share peers on this Wi-Fi to find this device'),
                      value: profile.discoverable,
                      onChanged: (val) {
                        ref.read(settingsServiceProvider.notifier).updateDiscoverable(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Storage & Maintenance', Icons.cleaning_services_rounded),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_sweep_rounded, color: AppColors.warning),
                      ),
                      title: const Text('Clear Temporary Cache', style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: const Text('Remove incomplete chunks and temporary files'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Clear Cache?'),
                            content: const Text('This will delete all temporary download chunks and cache.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Clear Cache'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(settingsServiceProvider.notifier).clearTemporaryFiles();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Temporary cache cleared!')),
                            );
                          }
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                      ),
                      title: const Text('Clear All Transfer History', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.error)),
                      subtitle: const Text('Erase transfer records log'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Clear History?'),
                            content: const Text('This action will delete your entire transfer log permanently.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Clear History'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          ref.read(historyServiceProvider.notifier).clearHistory();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Transfer history cleared!')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.share_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kappogy Share',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Version 1.0.0 (Production Build)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'End-to-End Encrypted Local P2P File Sharing',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryLight),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
