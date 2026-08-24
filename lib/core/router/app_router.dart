import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/home/presentation/main_shell_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/file_management/presentation/screens/received_files_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/transfer/presentation/screens/my_link_screen.dart';
import '../../features/transfer/presentation/screens/receive_screen.dart';
import '../../features/transfer/presentation/screens/sender_waiting_screen.dart';
import '../../features/transfer/presentation/screens/transfer_progress_screen.dart';
import '../../features/transfer/presentation/screens/radar_screen.dart';
import '../../features/transfer/presentation/screens/qr_scanner_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const MainShellScreen(),
      ),
      GoRoute(
        path: '/receive',
        name: 'receive',
        builder: (context, state) => const ReceiveScreen(),
      ),
      GoRoute(
        path: '/sender-waiting',
        name: 'sender-waiting',
        builder: (context, state) => const SenderWaitingScreen(),
      ),
      GoRoute(
        path: '/transfer-progress',
        name: 'transfer-progress',
        builder: (context, state) => const TransferProgressScreen(),
      ),
      GoRoute(
        path: '/scan-qr',
        name: 'scan-qr',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/received-files',
        name: 'received-files',
        builder: (context, state) => const ReceivedFilesScreen(),
      ),
      GoRoute(
        path: '/radar',
        name: 'radar',
        builder: (context, state) => const RadarScreen(),
      ),
      GoRoute(
        path: '/my-link',
        name: 'my-link',
        builder: (context, state) => const MyLinkScreen(),
      ),
    ],
  );
}
