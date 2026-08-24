import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/models/device_file_indexer_state.dart';
import '../domain/models/file_category.dart';
import '../domain/models/kappogy_file.dart';
import 'permission_service.dart';

part 'device_file_indexer_service.g.dart';

@Riverpod(keepAlive: true)
class DeviceFileIndexerService extends _$DeviceFileIndexerService {
  @override
  DeviceFileIndexerState build() {
    // Proactively scan files on launch
    Future.microtask(() => scanDevice());
    return const DeviceFileIndexerState(isScanning: true);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortOption(FileSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  Future<void> addCustomFolder(String folderPath) async {
    if (!state.customFolders.contains(folderPath)) {
      final updated = [...state.customFolders, folderPath];
      state = state.copyWith(customFolders: updated);
      await scanDevice();
    }
  }

  Future<void> refresh() async {
    await scanDevice();
  }

  Future<void> scanDevice() async {
    state = state.copyWith(isScanning: true);

    try {
      final permissionGranted = await ref.read(permissionServiceProvider).requestStoragePermission();
      if (!permissionGranted && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        state = state.copyWith(isScanning: false, hasPermission: false);
        return;
      }

      state = state.copyWith(hasPermission: true);

      final List<Directory> directoriesToScan = await _getInitialDirectories();

      // Include custom folders added by user
      for (final folder in state.customFolders) {
        final dir = Directory(folder);
        if (dir.existsSync() && !directoriesToScan.any((d) => d.path == dir.path)) {
          directoriesToScan.add(dir);
        }
      }

      final Map<String, KappogyFile> fileMap = {};
      final List<KappogyFile> photos = [];
      final List<KappogyFile> videos = [];
      final List<KappogyFile> audio = [];
      final List<KappogyFile> apps = [];
      final List<KappogyFile> contacts = [];
      final List<KappogyFile> files = [];

      for (final dir in directoriesToScan) {
        if (!dir.existsSync()) continue;\n\n        try {\n          await for (final entity in dir.list(recursive: true, followLinks: false)) {\n            if (entity is! File) continue;\n\n            final filePath = entity.path;\n            final normalized = p.normalize(filePath).toLowerCase();\n\n            // Ignore hidden files and system trash\n            final basename = p.basename(filePath);\n            if (basename.startsWith('.')) continue;\n            if (filePath.contains(r'$RECYCLE.BIN') ||\n                filePath.contains('System Volume Information') ||\n                filePath.contains('node_modules') ||\n                filePath.contains('AppData') ||\n                filePath.contains('/.') ||\n                filePath.contains(r'\\.')) {\n              continue;\n            }\n\n            if (fileMap.containsKey(normalized)) continue;\n\n            try {\n              final stat = entity.statSync();\n              if (stat.size <= 0) continue;\n\n              final ext = p.extension(filePath);\n              final category = FileCategory.fromExtension(ext);\n\n              final kappogyFile = KappogyFile(\n                path: filePath,\n                name: basename,\n                size: stat.size,\n                isDirectory: false,\n                mimeType: mime(filePath),\n                lastModified: stat.modified,\n              );\n\n              fileMap[normalized] = kappogyFile;\n\n              switch (category) {\n                case FileCategory.photos:\n                  photos.add(kappogyFile);\n                  break;\n                case FileCategory.videos:\n                  videos.add(kappogyFile);\n                  break;\n                case FileCategory.audio:\n                  audio.add(kappogyFile);\n                  break;\n                case FileCategory.apps:\n                  apps.add(kappogyFile);\n                  break;\n                case FileCategory.contacts:\n                  contacts.add(kappogyFile);\n                  break;\n                case FileCategory.files:\n                case FileCategory.recent:\n                  files.add(kappogyFile);\n                  break;\n              }\n            } catch (_) {\n              // Ignore individual unreadable files (permission locked, etc.)\n            }\n          }\n        } catch (_) {\n          // Ignore unreadable directory\n        }\n      }\n\n      // Compute Recent Files (top 150 sorted descending by last modified)\n      final allFilesList = fileMap.values.toList();\n      allFilesList.sort((a, b) {\n        final da = a.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);\n        final db = b.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);\n        return db.compareTo(da);\n      });\n      final recent = allFilesList.take(150).toList();\n\n      state = state.copyWith(\n        isScanning: false,\n        allFilesMap: fileMap,\n        recentFiles: recent,\n        photos: photos,\n        videos: videos,\n        audio: audio,\n        apps: apps,\n        contacts: contacts,\n        files: files,\n      );\n    } catch (_) {\n      state = state.copyWith(isScanning: false);\n    }\n  }\n\n  Future<List<Directory>> _getInitialDirectories() async {\n    final List<Directory> dirs = [];\n\n    if (kIsWeb) return dirs;\n\n    if (Platform.isAndroid) {\n      final candidates = [\n        '/storage/emulated/0/DCIM',\n        '/storage/emulated/0/Pictures',\n        '/storage/emulated/0/Download',\n        '/storage/emulated/0/Movies',\n        '/storage/emulated/0/Music',\n        '/storage/emulated/0/Documents',\n        '/storage/emulated/0/WhatsApp/Media',\n        '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media',\n      ];\n      for (final path in candidates) {\n        final d = Directory(path);\n        if (d.existsSync()) dirs.add(d);\n      }\n    } else if (Platform.isWindows) {\n      final userProfile = Platform.environment['USERPROFILE'];\n      if (userProfile != null) {\n        final subfolders = ['Downloads', 'Pictures', 'Videos', 'Music', 'Documents', 'Desktop'];\n        for (final sub in subfolders) {\n          final d = Directory(p.join(userProfile, sub));\n          if (d.existsSync()) dirs.add(d);\n        }\n      }\n    } else if (Platform.isMacOS || Platform.isLinux) {\n      final home = Platform.environment['HOME'];\n      if (home != null) {\n        final subfolders = ['Downloads', 'Pictures', 'Movies', 'Music', 'Documents', 'Desktop'];\n        for (final sub in subfolders) {\n          final d = Directory(p.join(home, sub));\n          if (d.existsSync()) dirs.add(d);\n        }\n      }\n    } else if (Platform.isIOS) {\n      final appDocDir = await getApplicationDocumentsDirectory();\n      dirs.add(appDocDir);\n    }\n\n    return dirs;\n  }\n}\n