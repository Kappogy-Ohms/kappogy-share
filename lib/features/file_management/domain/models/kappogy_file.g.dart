// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kappogy_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KappogyFileImpl _$$KappogyFileImplFromJson(Map<String, dynamic> json) =>
    _$KappogyFileImpl(
      path: json['path'] as String,
      name: json['name'] as String,
      size: (json['size'] as num).toInt(),
      isDirectory: json['isDirectory'] as bool,
      mimeType: json['mimeType'] as String?,
      lastModified: json['lastModified'] == null
          ? null
          : DateTime.parse(json['lastModified'] as String),
    );

Map<String, dynamic> _$$KappogyFileImplToJson(_$KappogyFileImpl instance) =>
    <String, dynamic>{
      'path': instance.path,
      'name': instance.name,
      'size': instance.size,
      'isDirectory': instance.isDirectory,
      'mimeType': instance.mimeType,
      'lastModified': instance.lastModified?.toIso8601String(),
    };
