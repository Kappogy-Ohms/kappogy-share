import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_service.g.dart';

@riverpod
class NotificationService extends _$NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> build() async {
    await _init();
  }

  Future<void> _init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const macInit = DarwinInitializationSettings();
    const linuxInit = LinuxInitializationSettings(defaultActionName: 'Open notification');

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: macInit,
      linux: linuxInit,
    );

    await _plugin.initialize(settings: initSettings);
  }

  Future<void> showTransferStarted(String filename) async {
    await _showNotification(
      id: 0,
      title: 'Transfer Started',
      body: 'Sending: $filename',
    );
  }

  Future<void> showTransferCompleted(String filename) async {
    await _showNotification(
      id: 1,
      title: 'Transfer Completed',
      body: 'Successfully transferred: $filename',
    );
  }

  Future<void> showTransferFailed(String filename, String error) async {
    await _showNotification(
      id: 2,
      title: 'Transfer Failed',
      body: 'Failed to transfer $filename: $error',
    );
  }

  Future<void> showIncomingRequest(String deviceName) async {
    await _showNotification(
      id: 3,
      title: 'Incoming Request',
      body: '$deviceName wants to send you a file.',
    );
  }

  Future<void> _showNotification({required int id, required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'kappogy_transfers',
      'Transfers',
      channelDescription: 'Notifications for file transfers',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const macDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macDetails,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
