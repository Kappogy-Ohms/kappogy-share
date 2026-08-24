import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kappogy_share/features/settings/domain/models/device_profile.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_service.g.dart';

@riverpod
class SettingsService extends _$SettingsService {
  static const _profileKey = 'kappogy_device_profile';

  @override
  Future<DeviceProfile> build() async {
    return _loadProfile();
  }

  Future<DeviceProfile> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_profileKey);
    
    if (jsonStr != null) {
      try {
        return DeviceProfile.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        // Fallback to default if parsing fails
      }
    }

    String defaultName = 'Kappogy Device';
    try {
      defaultName = Platform.localHostname;
    } catch (_) {}

    final defaultProfile = DeviceProfile(deviceName: defaultName);
    await _saveProfile(defaultProfile);
    return defaultProfile;
  }

  Future<void> _saveProfile(DeviceProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> updateDeviceName(String name) async {
    if (state.value == null) return;
    final newProfile = state.value!.copyWith(deviceName: name);
    state = AsyncData(newProfile);
    await _saveProfile(newProfile);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (state.value == null) return;
    final newProfile = state.value!.copyWith(themeMode: mode);
    state = AsyncData(newProfile);
    await _saveProfile(newProfile);
  }

  Future<void> updateAutoAccept(bool autoAccept) async {
    if (state.value == null) return;
    final newProfile = state.value!.copyWith(autoAcceptTransfers: autoAccept);
    state = AsyncData(newProfile);
    await _saveProfile(newProfile);
  }

  Future<void> updateDiscoverable(bool value) async {
    if (state.value == null) return;
    final newProfile = state.value!.copyWith(discoverable: value);
    state = AsyncData(newProfile);
    await _saveProfile(newProfile);
  }

  Future<void> updateAllowIncomingTransfers(bool value) async {
    if (state.value == null) return;
    final newProfile = state.value!.copyWith(allowIncomingTransfers: value);
    state = AsyncData(newProfile);
    await _saveProfile(newProfile);
  }

  Future<void> updateRequireConfirmation(bool value) async {
    if (state.value == null) return;
    final newProfile = state.value!.copyWith(requireConfirmation: value);
    state = AsyncData(newProfile);
    await _saveProfile(newProfile);
  }

  Future<void> updateAutoAcceptTrusted(bool value) async {
    if (state.value == null) return;
    final newProfile = state.value!.copyWith(autoAcceptTrusted: value);
    state = AsyncData(newProfile);
    await _saveProfile(newProfile);
  }

  Future<void> updateShareDiagnostics(bool value) async {
    if (state.value == null) return;
    final newProfile = state.value!.copyWith(shareDiagnostics: value);
    state = AsyncData(newProfile);
    await _saveProfile(newProfile);
  }

  Future<void> updateAnalyticsEnabled(bool value) async {
    if (state.value == null) return;
    final newProfile = state.value!.copyWith(analyticsEnabled: value);
    state = AsyncData(newProfile);
    await _saveProfile(newProfile);
  }

  Future<void> updateAmoledMode(bool value) async {
    if (state.value == null) return;
    final newProfile = state.value!.copyWith(amoledMode: value);
    state = AsyncData(newProfile);
    await _saveProfile(newProfile);
  }

  Future<void> updateDynamicColor(bool value) async {
    if (state.value == null) return;
    final newProfile = state.value!.copyWith(dynamicColorEnabled: value);
    state = AsyncData(newProfile);
    await _saveProfile(newProfile);
  }

  Future<void> clearTemporaryFiles() async {
    final tempDir = await getTemporaryDirectory();
    if (await tempDir.exists()) {
      try {
        final entities = await tempDir.list().toList();
        for (final entity in entities) {
          if (entity is File) {
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        }
      } catch (e) {
        // ignore errors during cleanup
      }
    }
  }
}
