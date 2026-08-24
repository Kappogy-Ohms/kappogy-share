import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_profile.freezed.dart';
part 'device_profile.g.dart';

@freezed
class DeviceProfile with _$DeviceProfile {
  const factory DeviceProfile({
    required String deviceName,
    @Default(false) bool autoAcceptTransfers,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(true) bool discoverable,
    @Default(true) bool allowIncomingTransfers,
    @Default(true) bool requireConfirmation,
    @Default(false) bool autoAcceptTrusted,
    @Default(false) bool shareDiagnostics,
    @Default(false) bool analyticsEnabled,
    @Default(false) bool amoledMode,
    @Default(true) bool dynamicColorEnabled,
  }) = _DeviceProfile;

  factory DeviceProfile.fromJson(Map<String, dynamic> json) =>
      _$DeviceProfileFromJson(json);
}
