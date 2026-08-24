import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kappogy_share/features/transfer/domain/models/transfer_session.dart';

part 'transfer_history_record.freezed.dart';
part 'transfer_history_record.g.dart';

@freezed
class TransferHistoryRecord with _$TransferHistoryRecord {
  const factory TransferHistoryRecord({
    required String id,
    required String filename,
    required int totalBytes,
    required TransferRole role,
    required TransferStatus status,
    required DateTime date,
    required int durationSeconds,
    required String deviceName,
  }) = _TransferHistoryRecord;

  factory TransferHistoryRecord.fromJson(Map<String, dynamic> json) =>
      _$TransferHistoryRecordFromJson(json);
}
