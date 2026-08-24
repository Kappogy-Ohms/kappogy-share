// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DeviceProfileImpl _$$DeviceProfileImplFromJson(Map<String, dynamic> json) =>
    _$DeviceProfileImpl(
      deviceName: json['deviceName'] as String,
      autoAcceptTransfers: json['autoAcceptTransfers'] as bool? ?? false,
      themeMode:
          $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
          ThemeMode.system,
      discoverable: json['discoverable'] as bool? ?? true,
      allowIncomingTransfers: json['allowIncomingTransfers'] as bool? ?? true,
      requireConfirmation: json['requireConfirmation'] as bool? ?? true,
      autoAcceptTrusted: json['autoAcceptTrusted'] as bool? ?? false,
      shareDiagnostics: json['shareDiagnostics'] as bool? ?? false,
      analyticsEnabled: json['analyticsEnabled'] as bool? ?? false,
      amoledMode: json['amoledMode'] as bool? ?? false,
      dynamicColorEnabled: json['dynamicColorEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$$DeviceProfileImplToJson(_$DeviceProfileImpl instance) =>
    <String, dynamic>{
      'deviceName': instance.deviceName,
      'autoAcceptTransfers': instance.autoAcceptTransfers,
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
      'discoverable': instance.discoverable,
      'allowIncomingTransfers': instance.allowIncomingTransfers,
      'requireConfirmation': instance.requireConfirmation,
      'autoAcceptTrusted': instance.autoAcceptTrusted,
      'shareDiagnostics': instance.shareDiagnostics,
      'analyticsEnabled': instance.analyticsEnabled,
      'amoledMode': instance.amoledMode,
      'dynamicColorEnabled': instance.dynamicColorEnabled,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
