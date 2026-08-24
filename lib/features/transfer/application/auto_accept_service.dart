import 'dart:convert';
import 'package:kappogy_share/features/settings/application/settings_service.dart';
import 'package:kappogy_share/features/transfer/application/discovery_service.dart';
import 'package:kappogy_share/features/transfer/application/transfer_engine.dart';
import 'package:kappogy_share/features/transfer/application/trusted_devices_service.dart';
import 'package:kappogy_share/core/router/app_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auto_accept_service.g.dart';

@Riverpod(keepAlive: true)
class AutoAcceptService extends _$AutoAcceptService {
  @override
  void build() {
    _startListening();
    _startDiscoveryIfEnabled();
    
    ref.listen(settingsServiceProvider, (prev, next) {
      _startDiscoveryIfEnabled();
    });
  }

  void _startDiscoveryIfEnabled() {
    final settings = ref.read(settingsServiceProvider).valueOrNull;
    if (settings != null && settings.autoAcceptTrusted) {
      ref.read(discoveryServiceProvider.notifier).startDiscoveringAll();
    }
  }

  void _startListening() {
    ref.listen(discoveryServiceProvider, (previous, next) async {
      final settings = ref.read(settingsServiceProvider).valueOrNull;
      if (settings == null || !settings.autoAcceptTrusted) return;
      
      final transferState = ref.read(transferEngineProvider);
      if (transferState != null) return;
      
      for (final service in next.services) {
        if (service.txt != null && service.txt!['deviceName'] != null && service.name != null) {
          final deviceNameBytes = service.txt!['deviceName']!;
          final deviceName = utf8.decode(deviceNameBytes);
          
          final isTrusted = await ref.read(trustedDevicesServiceProvider.notifier).isTrusted(deviceName);
          if (isTrusted && service.host != null && service.port != null) {
            final parts = service.name!.split('_');
            if (parts.length >= 2) {
              final pin = parts.last;
              
              await ref.read(transferEngineProvider.notifier).connectToSender(pin, service.host!, service.port!);
              ref.read(appRouterProvider).go('/transfer-progress');
              break;
            }
          }
        }
      }
    });
  }
}
