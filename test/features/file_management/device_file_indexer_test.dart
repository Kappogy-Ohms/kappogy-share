import 'package:flutter_test/flutter_test.dart';
import 'package:kappogy_share/features/file_management/domain/models/date_grouped_files.dart';
import 'package:kappogy_share/features/file_management/domain/models/file_category.dart';
import 'package:kappogy_share/features/file_management/domain/models/kappogy_file.dart';
import 'package:kappogy_share/features/file_management/application/file_selection_controller.dart';

void main() {
  group('FileCategory Classification Tests', () {
    test('Classifies extensions accurately', () {
      expect(FileCategory.fromExtension('.jpg'), FileCategory.photos);
      expect(FileCategory.fromExtension('.png'), FileCategory.photos);
      expect(FileCategory.fromExtension('.mp4'), FileCategory.videos);
      expect(FileCategory.fromExtension('.mkv'), FileCategory.videos);
      expect(FileCategory.fromExtension('.mp3'), FileCategory.audio);
      expect(FileCategory.fromExtension('.flac'), FileCategory.audio);
      expect(FileCategory.fromExtension('.apk'), FileCategory.apps);
      expect(FileCategory.fromExtension('.exe'), FileCategory.apps);
      expect(FileCategory.fromExtension('.vcf'), FileCategory.contacts);
      expect(FileCategory.fromExtension('.pdf'), FileCategory.files);
      expect(FileCategory.fromExtension('.zip'), FileCategory.files);
    });
  });

  group('DateGroupedFiles Tests', () {
    test('Groups files by date buckets and sorts chronologically', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 14, 30);
      final yesterday = today.subtract(const Duration(days: 1));
      final pastDate = DateTime(2025, 8, 20, 10, 0);

      final files = [
        KappogyFile(path: '/a.jpg', name: 'a.jpg', size: 1024, isDirectory: false, lastModified: today),
        KappogyFile(path: '/b.jpg', name: 'b.jpg', size: 2048, isDirectory: false, lastModified: today),
        KappogyFile(path: '/c.mp4', name: 'c.mp4', size: 4096, isDirectory: false, lastModified: yesterday),
        KappogyFile(path: '/d.pdf', name: 'd.pdf', size: 8192, isDirectory: false, lastModified: pastDate),
      ];

      final groups = DateGroupedFiles.groupFiles(files);

      expect(groups.length, 3);
      expect(groups[0].title, 'Today');
      expect(groups[0].files.length, 2);
      expect(groups[1].title, 'Yesterday');
      expect(groups[1].files.length, 1);
    });
  });

  group('FileSelectionController Tests', () {
    test('Select, toggle, and group select works properly', () {
      final file1 = const KappogyFile(path: '/path/1.png', name: '1.png', size: 1000, isDirectory: false);
      final file2 = const KappogyFile(path: '/path/2.png', name: '2.png', size: 2000, isDirectory: false);

      var state = const FileSelectionState();
      expect(state.isEmpty, true);

      final map1 = {file1.path: file1};
      state = FileSelectionState(selectedFilesMap: map1);
      expect(state.count, 1);
      expect(state.totalBytes, 1000);
      expect(state.isSelected(file1), true);
      expect(state.isSelected(file2), false);

      final map2 = {file1.path: file1, file2.path: file2};
      state = FileSelectionState(selectedFilesMap: map2);
      expect(state.count, 2);
      expect(state.totalBytes, 3000);
      expect(state.isGroupSelected([file1, file2]), true);
    });
  });
}
