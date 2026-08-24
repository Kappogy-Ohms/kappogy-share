import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ui_helpers.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../file_management/presentation/screens/send_library_screen.dart';
import '../../file_management/presentation/widgets/bulk_folder_dialog.dart';
import '../../history/presentation/screens/history_screen.dart';
import '../../transfer/presentation/screens/my_link_screen.dart';
import '../../transfer/presentation/screens/receive_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SendLibraryScreen(),
    ReceiveScreen(),
    HistoryScreen(),
    MyLinkScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.lightCardBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppGradients.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(100),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.share_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kappogy',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Share Pro',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildSidebarItem(
                    index: 0,
                    icon: Icons.arrow_upward_rounded,
                    label: 'Send',
                    isDark: isDark,
                  ),
                  _buildSidebarItem(
                    index: 1,
                    icon: Icons.arrow_downward_rounded,
                    label: 'Receive',
                    isDark: isDark,
                  ),
                  _buildSidebarItem(
                    index: 2,
                    icon: Icons.history_rounded,
                    label: 'History',
                    isDark: isDark,
                  ),
                  _buildSidebarItem(
                    index: 3,
                    icon: Icons.link_rounded,
                    label: 'My Link',
                    isDark: isDark,
                  ),
                  const Spacer(),
                  ListTile(
                    leading: const Icon(Icons.folder_copy_rounded,
                        color: AppColors.primaryLight),
                    title: const Text('Send Bulk Folders',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    onTap: () => BulkFolderDialog.show(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.radar_rounded,
                        color: AppColors.accent),
                    title: const Text('Device Radar',
                        style: TextStyle(fontSize: 13)),
                    onTap: () => context.push('/radar'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_open_rounded,
                        color: AppColors.secondary),
                    title: const Text('Received Files',
                        style: TextStyle(fontSize: 13)),
                    onTap: () => context.push('/received-files'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_rounded),
                    title: const Text('Settings',
                        style: TextStyle(fontSize: 13)),
                    onTap: () => context.push('/settings'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.darkCardBorder
                  : AppColors.lightCardBorder,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 50 : 15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          elevation: 0,
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primary.withAlpha(isDark ? 60 : 35),
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.arrow_upward_rounded),
              selectedIcon: Icon(Icons.arrow_upward_rounded,
                  color: AppColors.primaryLight),
              label: 'Send',
            ),
            NavigationDestination(
              icon: Icon(Icons.arrow_downward_rounded),
              selectedIcon: Icon(Icons.arrow_downward_rounded,
                  color: AppColors.primaryLight),
              label: 'Receive',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon:
                  Icon(Icons.history_rounded, color: AppColors.primaryLight),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.link_rounded),
              selectedIcon:
                  Icon(Icons.link_rounded, color: AppColors.primaryLight),
              label: 'My Link',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _currentIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withAlpha(isDark ? 40 : 25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryLight.withAlpha(80)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primaryLight
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primaryLight
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
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
