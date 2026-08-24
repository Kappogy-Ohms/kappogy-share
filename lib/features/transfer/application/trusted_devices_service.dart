import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'trusted_devices_service.g.dart';

@riverpod
class TrustedDevicesService extends _$TrustedDevicesService {
  static const _trustedDevicesKey = 'kappogy_trusted_devices';

  @override
  Future<List<String>> build() async {
    return _loadTrustedDevices();
  }

  Future<List<String>> _loadTrustedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_trustedDevicesKey) ?? [];
  }

  Future<void> addTrustedDevice(String deviceName) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = prefs.getStringList(_trustedDevicesKey) ?? [];
    if (!currentList.contains(deviceName)) {
      currentList.add(deviceName);
      await prefs.setStringList(_trustedDevicesKey, currentList);
      state = AsyncData(currentList);
    }
  }

  Future<void> removeTrustedDevice(String deviceName) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = prefs.getStringList(_trustedDevicesKey) ?? [];
    if (currentList.contains(deviceName)) {
      currentList.remove(deviceName);
      await prefs.setStringList(_trustedDevicesKey, currentList);
      state = AsyncData(currentList);
    }
  }

  Future<bool> isTrusted(String deviceName) async {
    final list = await _loadTrustedDevices();
    return list.contains(deviceName);
  }
}
