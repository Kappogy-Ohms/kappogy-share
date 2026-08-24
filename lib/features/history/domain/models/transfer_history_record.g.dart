// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_history_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransferHistoryRecordImpl _$$TransferHistoryRecordImplFromJson(
  Map<String, dynamic> json,
) => _$TransferHistoryRecordImpl(
  id: json['id'] as String,
  filename: json['filename'] as String,
  totalBytes: (json['totalBytes'] as num).toInt(),
  role: $enumDecode(_$TransferRoleEnumMap, json['role']),
  status: $enumDecode(_$TransferStatusEnumMap, json['status']),
  date: DateTime.parse(json['date'] as String),
  durationSeconds: (json['durationSeconds'] as num).toInt(),
  deviceName: json['deviceName'] as String,
);

Map<String, dynamic> _$$TransferHistoryRecordImplToJson(
  _$TransferHistoryRecordImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'filename': instance.filename,
  'totalBytes': instance.totalBytes,
  'role': _$TransferRoleEnumMap[instance.role]!,
  'status': _$TransferStatusEnumMap[instance.status]!,
  'date': instance.date.toIso8601String(),
  'durationSeconds': instance.durationSeconds,
  'deviceName': instance.deviceName,
};

const _$TransferRoleEnumMap = {
  TransferRole.sender: 'sender',
  TransferRole.receiver: 'receiver',
};

const _$TransferStatusEnumMap = {
  TransferStatus.initializing: 'initializing',
  TransferStatus.waitingForConnection: 'waitingForConnection',
  TransferStatus.connecting: 'connecting',
  TransferStatus.handshake: 'handshake',
  TransferStatus.transferring: 'transferring',
  TransferStatus.completed: 'completed',
  TransferStatus.failed: 'failed',
  TransferStatus.cancelled: 'cancelled',
};
