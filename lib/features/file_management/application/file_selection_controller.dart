import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/models/kappogy_file.dart';

part 'file_selection_controller.g.dart';

class FileSelectionState {
  final Map<String, KappogyFile> selectedFilesMap;

  const FileSelectionState({
    this.selectedFilesMap = const {},
  });

  List<KappogyFile> get selectedFiles => selectedFilesMap.values.toList();
  int get count => selectedFilesMap.length;
  bool get isEmpty => selectedFilesMap.isEmpty;
  bool get isNotEmpty => selectedFilesMap.isNotEmpty;

  int get totalBytes => selectedFiles.fold(0, (sum, f) => sum + f.size);

  String get formattedTotalSize {
    final bytes = totalBytes;
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    final size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  bool isSelected(KappogyFile file) => selectedFilesMap.containsKey(file.path);

  bool isGroupSelected(List<KappogyFile> groupFiles) {
    if (groupFiles.isEmpty) return false;
    return groupFiles.every((f) => selectedFilesMap.containsKey(f.path));
  }
}

@Riverpod(keepAlive: true)
class FileSelectionController extends _$FileSelectionController {
  @override
  FileSelectionState build() {
    return const FileSelectionState();
  }

  void toggleSelect(KappogyFile file) {
    final map = Map<String, KappogyFile>.from(state.selectedFilesMap);
    if (map.containsKey(file.path)) {
      map.remove(file.path);
    } else {
      map[file.path] = file;
    }
    state = FileSelectionState(selectedFilesMap: map);
  }

  void toggleGroup(List<KappogyFile> groupFiles) {
    if (groupFiles.isEmpty) return;
    final map = Map<String, KappogyFile>.from(state.selectedFilesMap);
    final allSelected = groupFiles.every((f) => map.containsKey(f.path));

    if (allSelected) {
      for (final f in groupFiles) {
        map.remove(f.path);
      }
    } else {
      for (final f in groupFiles) {
        map[f.path] = f;
      }
    }
    state = FileSelectionState(selectedFilesMap: map);
  }

  void selectAll(List<KappogyFile> files) {
    final map = Map<String, KappogyFile>.from(state.selectedFilesMap);
    for (final f in files) {
      map[f.path] = f;
    }
    state = FileSelectionState(selectedFilesMap: map);
  }

  void clearSelection() {
    state = const FileSelectionState();
  }
}
