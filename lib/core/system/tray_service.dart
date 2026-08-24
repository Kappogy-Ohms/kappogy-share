import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tray_service.g.dart';

@Riverpod(keepAlive: true)
class TrayService extends _$TrayService with TrayListener {
  @override
  void build() {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      _initTray();
    }
  }

  Future<void> _initTray() async {
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png',
    );
    
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_app',
          label: 'Show App',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit',
        ),
      ],
    );
    
    await trayManager.setContextMenu(menu);
    trayManager.addListener(this);
  }
  
  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_app') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      exit(0);
    }
  }
  
  void showNotification(String title, String body) {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // We can use local_notifier or just rely on existing notification_service
    }
  }
}
