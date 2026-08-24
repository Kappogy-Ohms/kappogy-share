import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:path/path.dart' as p;

part 'received_files_service.g.dart';

@riverpod
class ReceivedFilesService extends _$ReceivedFilesService {
  @override
  Future<List<File>> build() async {
    return _scanDirectory();
  }

  Future<List<File>> _scanDirectory() async {
    final downloadsDir = await getApplicationDocumentsDirectory();
    final kappogyDir = Directory(p.join(downloadsDir.path, 'Kappogy Downloads'));
    
    if (!await kappogyDir.exists()) {
      return [];
    }

    final entities = await kappogyDir.list().toList();
    final files = entities.whereType<File>().toList();
    
    // Sort by modification time descending (newest first)
    files.sort((a, b) {
      final statA = a.statSync();
      final statB = b.statSync();
      return statB.modified.compareTo(statA.modified);
    });

    return files;
  }

  Future<void> deleteFile(File file) async {
    if (await file.exists()) {
      await file.delete();
      // Reload the state
      state = AsyncData(await _scanDirectory());
    }
  }

  Future<void> openFile(File file) async {
    if (await file.exists()) {
      await OpenFilex.open(file.path);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _scanDirectory());
  }
}
