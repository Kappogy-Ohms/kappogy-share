// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransferSessionImpl _$$TransferSessionImplFromJson(
  Map<String, dynamic> json,
) => _$TransferSessionImpl(
  id: json['id'] as String,
  pin: json['pin'] as String,
  role: $enumDecode(_$TransferRoleEnumMap, json['role']),
  status:
      $enumDecodeNullable(_$TransferStatusEnumMap, json['status']) ??
      TransferStatus.initializing,
  files:
      (json['files'] as List<dynamic>?)
          ?.map((e) => KappogyFile.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
  transferredBytes: (json['transferredBytes'] as num?)?.toInt() ?? 0,
  currentSpeedBytesPerSecond:
      (json['currentSpeedBytesPerSecond'] as num?)?.toInt() ?? 0,
  averageSpeedBytesPerSecond:
      (json['averageSpeedBytesPerSecond'] as num?)?.toInt() ?? 0,
  speedHistory:
      (json['speedHistory'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      const [],
  estimatedTimeRemainingSeconds: (json['estimatedTimeRemainingSeconds'] as num?)
      ?.toInt(),
  remoteDeviceName: json['remoteDeviceName'] as String?,
  chatMessages:
      (json['chatMessages'] as List<dynamic>?)
          ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  hasUnreadChatMessages: json['hasUnreadChatMessages'] as bool? ?? false,
  errorMessage: json['errorMessage'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$TransferSessionImplToJson(
  _$TransferSessionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'pin': instance.pin,
  'role': _$TransferRoleEnumMap[instance.role]!,
  'status': _$TransferStatusEnumMap[instance.status]!,
  'files': instance.files,
  'totalBytes': instance.totalBytes,
  'transferredBytes': instance.transferredBytes,
  'currentSpeedBytesPerSecond': instance.currentSpeedBytesPerSecond,
  'averageSpeedBytesPerSecond': instance.averageSpeedBytesPerSecond,
  'speedHistory': instance.speedHistory,
  'estimatedTimeRemainingSeconds': instance.estimatedTimeRemainingSeconds,
  'remoteDeviceName': instance.remoteDeviceName,
  'chatMessages': instance.chatMessages,
  'hasUnreadChatMessages': instance.hasUnreadChatMessages,
  'errorMessage': instance.errorMessage,
  'createdAt': instance.createdAt.toIso8601String(),
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

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      text: json['text'] as String,
      isFromMe: json['isFromMe'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'isFromMe': instance.isFromMe,
      'timestamp': instance.timestamp.toIso8601String(),
    };
