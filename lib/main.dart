import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:window_manager/window_manager.dart';

import 'core/router/app_router.dart';
import 'core/system/tray_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/file_management/domain/models/kappogy_file.dart';
import 'features/settings/application/settings_service.dart';
import 'features/transfer/application/auto_accept_service.dart';
import 'features/transfer/application/transfer_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
        size: Size(960, 680),
        minimumSize: Size(600, 480),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (_) {}
  }

  // Request mobile permissions safely
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Permission.notification.request();
    } catch (_) {}
  }

  runApp(
    const ProviderScope(
      child: IntentListener(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);
    final settings = ref.watch(settingsServiceProvider).valueOrNull;
    final amoledMode = settings?.amoledMode ?? false;
    final dynamicColorEnabled = settings?.dynamicColorEnabled ?? true;

    // Initialize Auto Accept background listener
    ref.read(autoAcceptServiceProvider);

    // Initialize System Tray on desktop
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      ref.read(trayServiceProvider);
    }

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useLightDynamic = dynamicColorEnabled ? lightDynamic : null;
        final useDarkDynamic = dynamicColorEnabled ? darkDynamic : null;

        return MaterialApp.router(
          title: 'Kappogy Share',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(dynamicColorScheme: useLightDynamic),
          darkTheme: AppTheme.darkTheme(
            dynamicColorScheme: useDarkDynamic,
            amoledMode: amoledMode,
          ),
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}

class IntentListener extends ConsumerStatefulWidget {
  final Widget child;
  const IntentListener({super.key, required this.child});

  @override
  ConsumerState<IntentListener> createState() => _IntentListenerState();
}

class _IntentListenerState extends ConsumerState<IntentListener> {
  @override
  void initState() {
    super.initState();

    // receive_sharing_intent is only available on Android & iOS
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        ReceiveSharingIntent.instance
            .getMediaStream()
            .listen((List<SharedMediaFile> value) {
          _handleSharedFiles(value);
        }, onError: (err) {
          debugPrint("getIntentDataStream error: $err");
        });

        ReceiveSharingIntent.instance
            .getInitialMedia()
            .then((List<SharedMediaFile> value) {
          _handleSharedFiles(value);
          ReceiveSharingIntent.instance.reset();
        });
      } catch (_) {}
    }
  }

  void _handleSharedFiles(List<SharedMediaFile> sharedFiles) async {
    if (sharedFiles.isEmpty) return;

    List<KappogyFile> files = [];
    for (var sharedFile in sharedFiles) {
      final file = File(sharedFile.path);
      if (file.existsSync()) {
        files.add(KappogyFile(
          path: file.path,
          name: file.path.split(Platform.pathSeparator).last,
          size: file.lengthSync(),
          isDirectory: false,
          mimeType: sharedFile.mimeType ?? 'application/octet-stream',
        ));
      }
    }

    if (files.isNotEmpty) {
      await ref.read(transferEngineProvider.notifier).startAsSender(files);
      ref.read(appRouterProvider).go('/sender-waiting');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
