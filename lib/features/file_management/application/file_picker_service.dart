import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime_type/mime_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../domain/models/folder_item_info.dart';
import '../domain/models/kappogy_file.dart';
import 'permission_service.dart';

part 'file_picker_service.g.dart';

class FilePickerService {
  final PermissionService _permissionService;

  FilePickerService(this._permissionService);

  /// Opens the OS file picker and returns a list of [KappogyFile].
  /// Does not load files into memory.
  Future<List<KappogyFile>> pickFiles({bool allowMultiple = true}) async {
    final hasPermission = await _permissionService.requestStoragePermission();
    if (!hasPermission) {
      throw Exception('Storage permission denied.');
    }

    List<PlatformFile> platformFiles = [];

    if (allowMultiple) {
      final result = await FilePicker.pickFiles();
      platformFiles = result;
    } else {
      final result = await FilePicker.pickFile();
      if (result != null) {
        platformFiles = [result];
      }
    }

    if (platformFiles.isEmpty) {
      return [];
    }

    return platformFiles.where((f) => f.path != null).map((f) {
      return KappogyFile(\n        path: f.path!,\n        name: f.name,\n        size: File(f.path!).lengthSync(),\n        isDirectory: false,\n        mimeType: mime(f.name),\n        lastModified: File(f.path!).existsSync()\n            ? File(f.path!).lastModifiedSync()\n            : null,\n      );\n    }).toList();\n  }\n\n  /// Opens the OS folder picker and returns a [KappogyFile] representing the folder as a zip package.\n  Future<KappogyFile?> pickFolder() async {\n    final hasPermission = await _permissionService.requestStoragePermission();\n    if (!hasPermission) {\n      throw Exception('Storage permission denied.');\n    }\n\n    final directoryPath = await FilePicker.getDirectoryPath();\n    if (directoryPath == null) {\n      return null;\n    }\n\n    return packageFolder(directoryPath);\n  }\n\n  /// Packages a single folder into a zip archive and returns a [KappogyFile].\n  Future<KappogyFile?> packageFolder(String directoryPath) async {\n    final directory = Directory(directoryPath);\n    if (!directory.existsSync()) {\n      return null;\n    }\n\n    final tempDir = await getTemporaryDirectory();\n    final folderName = p.basename(directoryPath);\n    final zipName = folderName.isEmpty ? 'folder_${DateTime.now().millisecondsSinceEpoch}.zip' : '$folderName.zip';\n    final zipPath = p.join(tempDir.path, zipName);\n\n    await compute(_zipDirectory, {'source': directoryPath, 'destination': zipPath});\n\n    final zipFile = File(zipPath);\n    return KappogyFile(\n      path: zipPath,\n      name: zipName,\n      size: zipFile.existsSync() ? zipFile.lengthSync() : 0,\n      isDirectory: true,\n      mimeType: 'application/zip',\n      lastModified: DateTime.now(),\n    );\n  }\n\n  /// Packages multiple directories into individual zip archives in background compute.\n  Future<List<KappogyFile>> packageMultipleFolders(\n    List<String> directoryPaths, {\n    Function(int current, int total, String name)? onProgress,\n  }) async {\n    final List<KappogyFile> result = [];\n    for (int i = 0; i < directoryPaths.length; i++) {\n      final dirPath = directoryPaths[i];\n      final name = p.basename(dirPath);\n      onProgress?.call(i + 1, directoryPaths.length, name);\n      final packed = await packageFolder(dirPath);\n      if (packed != null) {\n        result.add(packed);\n      }\n    }\n    return result;\n  }\n\n  /// Inspects folder file count and size without loading or compressing.\n  Future<FolderItemInfo> inspectFolder(String directoryPath) async {\n    return FolderItemInfo.fromDirectory(Directory(directoryPath));\n  }\n}\n\nvoid _zipDirectory(Map<String, String> args) {\n  var encoder = ZipFileEncoder();\n  encoder.zipDirectory(Directory(args['source']!), filename: args['destination']!);\n}\n\n@riverpod\nFilePickerService filePickerService(FilePickerServiceRef ref) {\n  return FilePickerService(ref.watch(permissionServiceProvider));\n}\n