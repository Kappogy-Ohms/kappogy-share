import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mime_type/mime_type.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

part 'kappogy_file.freezed.dart';
part 'kappogy_file.g.dart';

@freezed
class KappogyFile with _$KappogyFile {
  const factory KappogyFile({
    required String path,
    required String name,
    required int size,
    required bool isDirectory,
    String? mimeType,
    DateTime? lastModified,
  }) = _KappogyFile;

  factory KappogyFile.fromJson(Map<String, dynamic> json) =>
      _$KappogyFileFromJson(json);

  factory KappogyFile.fromFile(File file) {
    return KappogyFile(
      path: file.path,
      name: p.basename(file.path),
      size: file.lengthSync(),
      isDirectory: false,
      mimeType: mime(file.path),
      lastModified: file.lastModifiedSync(),
    );
  }

  factory KappogyFile.fromDirectory(Directory dir) {
    return KappogyFile(
      path: dir.path,
      name: p.basename(dir.path),
      size: 0,
      isDirectory: true,
      lastModified: dir.statSync().modified,
    );
  }
}

extension KappogyFileX on KappogyFile {
  String get readableSize {
    if (isDirectory) return 'Folder';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
