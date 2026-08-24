import 'dart:convert';

import 'package:kappogy_share/features/history/domain/models/transfer_history_record.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'history_service.g.dart';

@riverpod
class HistoryService extends _$HistoryService {
  static const _historyKey = 'kappogy_transfer_history';
  static const _maxHistoryRecords = 200;

  @override
  Future<List<TransferHistoryRecord>> build() async {
    return _loadHistory();
  }

  Future<List<TransferHistoryRecord>> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_historyKey);
    if (jsonList == null) return [];

    try {
      final records = jsonList
          .map((jsonStr) => TransferHistoryRecord.fromJson(jsonDecode(jsonStr)))
          .toList();
      
      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    } catch (e) {
      return [];
    }
  }

  Future<void> addRecord(TransferHistoryRecord record) async {
    final currentRecords = state.valueOrNull ?? [];
    final updatedRecords = [record, ...currentRecords];
    
    if (updatedRecords.length > _maxHistoryRecords) {
      updatedRecords.removeRange(_maxHistoryRecords, updatedRecords.length);
    }
    
    state = AsyncData(updatedRecords);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = updatedRecords
        .map((r) => jsonEncode(r.toJson()))
        .toList();
    await prefs.setStringList(_historyKey, jsonList);
  }

  Future<void> clearHistory() async {
    state = const AsyncData([]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
