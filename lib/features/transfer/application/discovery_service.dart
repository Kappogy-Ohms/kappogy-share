import 'dart:convert';
import 'package:nsd/nsd.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kappogy_share/features/settings/application/settings_service.dart';

part 'discovery_service.g.dart';

class DiscoveryState {
  final bool isDiscovering;
  final List<Service> services;
  DiscoveryState({this.isDiscovering = false, this.services = const []});
  
  DiscoveryState copyWith({bool? isDiscovering, List<Service>? services}) {
    return DiscoveryState(
      isDiscovering: isDiscovering ?? this.isDiscovering,
      services: services ?? this.services,
    );
  }
}

@riverpod
class DiscoveryService extends _$DiscoveryService {
  Registration? _registration;
  Discovery? _discovery;

  @override
  DiscoveryState build() {
    ref.onDispose(() {
      stopBroadcasting();
      stopDiscovering();
    });
    return DiscoveryState();
  }

  Future<void> startBroadcasting(String transferPin, int port) async {
    await stopBroadcasting();
    final profile = ref.read(settingsServiceProvider).valueOrNull;
    
    if (profile != null && !profile.discoverable) {
      return;
    }

    final deviceName = profile?.deviceName ?? 'Kappogy Device';
    final service = Service(
      name: 'kappogy_$transferPin',
      type: '_kappogy._tcp',
      port: port,
      txt: {'deviceName': utf8.encode(deviceName)},
    );
    _registration = await register(service);
  }

  Future<void> stopBroadcasting() async {
    if (_registration != null) {
      await unregister(_registration!);
      _registration = null;
    }
  }

  Future<void> startDiscoveringAll() async {
    await stopDiscovering();
    state = state.copyWith(isDiscovering: true, services: []);
    _discovery = await startDiscovery('_kappogy._tcp');
    
    _discovery!.addListener(() {
      state = state.copyWith(services: _discovery!.services.toList());
    });
  }

  Future<void> stopDiscovering() async {
    if (_discovery != null) {
      await stopDiscovery(_discovery!);
      _discovery = null;
    }
    state = state.copyWith(isDiscovering: false, services: []);
  }

  Stream<Service> discoverTransfers(String transferPin) async* {
    await stopDiscovering();
    _discovery = await startDiscovery('_kappogy._tcp');
    for (final service in _discovery!.services) {
      if (service.name != null && service.name!.contains('kappogy_$transferPin')) {
        yield service;
      }
    }
  }
}
