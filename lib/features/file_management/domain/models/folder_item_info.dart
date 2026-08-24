import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;

class FolderItemInfo {
  final String path;
  final String name;
  final int fileCount;
  final int totalBytes;
  final bool isZipping;

  const FolderItemInfo({
    required this.path,
    required this.name,
    required this.fileCount,
    required this.totalBytes,
    this.isZipping = false,
  });

  String get formattedSize {
    if (totalBytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(totalBytes) / log(1024)).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    final size = totalBytes / pow(1024, i);
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  FolderItemInfo copyWith({
    String? path,
    String? name,
    int? fileCount,
    int? totalBytes,
    bool? isZipping,
  }) {
    return FolderItemInfo(
      path: path ?? this.path,
      name: name ?? this.name,
      fileCount: fileCount ?? this.fileCount,
      totalBytes: totalBytes ?? this.totalBytes,
      isZipping: isZipping ?? this.isZipping,
    );
  }

  /// Calculates stats (item count & total size) for a physical directory.
  static Future<FolderItemInfo> fromDirectory(Directory dir) async {
    final name = p.basename(dir.path);
    int count = 0;
    int bytes = 0;

    try {
      if (dir.existsSync()) {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            count++;
            try {
              bytes += entity.lengthSync();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    return FolderItemInfo(
      path: dir.path,
      name: name.isEmpty ? dir.path : name,
      fileCount: count,
      totalBytes: bytes,
    );
  }
}
