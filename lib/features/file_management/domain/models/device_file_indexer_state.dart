import 'file_category.dart';
import 'kappogy_file.dart';

enum FileSortOption {
  dateDesc('Date (Newest first)'),
  dateAsc('Date (Oldest first)'),
  nameAsc('Name (A - Z)'),
  nameDesc('Name (Z - A)'),
  sizeDesc('Size (Largest first)'),
  sizeAsc('Size (Smallest first)');

  final String label;
  const FileSortOption(this.label);
}

class DeviceFileIndexerState {
  final bool isScanning;
  final bool hasPermission;
  final List<KappogyFile> recentFiles;
  final List<KappogyFile> photos;
  final List<KappogyFile> videos;
  final List<KappogyFile> audio;
  final List<KappogyFile> apps;
  final List<KappogyFile> contacts;
  final List<KappogyFile> files;
  final Map<String, KappogyFile> allFilesMap;
  final List<String> customFolders;
  final String searchQuery;
  final FileSortOption sortOption;

  const DeviceFileIndexerState({
    this.isScanning = false,
    this.hasPermission = true,
    this.recentFiles = const [],
    this.photos = const [],
    this.videos = const [],
    this.audio = const [],
    this.apps = const [],
    this.contacts = const [],
    this.files = const [],
    this.allFilesMap = const {},
    this.customFolders = const [],
    this.searchQuery = '',
    this.sortOption = FileSortOption.dateDesc,
  });

  DeviceFileIndexerState copyWith({
    bool? isScanning,
    bool? hasPermission,
    List<KappogyFile>? recentFiles,
    List<KappogyFile>? photos,
    List<KappogyFile>? videos,
    List<KappogyFile>? audio,
    List<KappogyFile>? apps,
    List<KappogyFile>? contacts,
    List<KappogyFile>? files,
    Map<String, KappogyFile>? allFilesMap,
    List<String>? customFolders,
    String? searchQuery,
    FileSortOption? sortOption,
  }) {
    return DeviceFileIndexerState(\n      isScanning: isScanning ?? this.isScanning,\n      hasPermission: hasPermission ?? this.hasPermission,\n      recentFiles: recentFiles ?? this.recentFiles,\n      photos: photos ?? this.photos,\n      videos: videos ?? this.videos,\n      audio: audio ?? this.audio,\n      apps: apps ?? this.apps,\n      contacts: contacts ?? this.contacts,\n      files: files ?? this.files,\n      allFilesMap: allFilesMap ?? this.allFilesMap,\n      customFolders: customFolders ?? this.customFolders,\n      searchQuery: searchQuery ?? this.searchQuery,\n      sortOption: sortOption ?? this.sortOption,\n    );\n  }\n\n  List<KappogyFile> getFilesForCategory(FileCategory category) {\n    List<KappogyFile> raw;\n    switch (category) {\n      case FileCategory.recent:\n        raw = recentFiles;\n        break;\n      case FileCategory.photos:\n        raw = photos;\n        break;\n      case FileCategory.videos:\n        raw = videos;\n        break;\n      case FileCategory.audio:\n        raw = audio;\n        break;\n      case FileCategory.apps:\n        raw = apps;\n        break;\n      case FileCategory.contacts:\n        raw = contacts;\n        break;\n      case FileCategory.files:\n        raw = files;\n        break;\n    }\n\n    var filtered = raw;\n    if (searchQuery.trim().isNotEmpty) {\n      final q = searchQuery.toLowerCase().trim();\n      filtered = raw.where((f) => f.name.toLowerCase().contains(q)).toList();\n    }\n\n    final sorted = List<KappogyFile>.from(filtered);\n    switch (sortOption) {\n      case FileSortOption.dateDesc:\n        sorted.sort((a, b) {\n          final da = a.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);\n          final db = b.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);\n          return db.compareTo(da);\n        });\n        break;\n      case FileSortOption.dateAsc:\n        sorted.sort((a, b) {\n          final da = a.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);\n          final db = b.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);\n          return da.compareTo(db);\n        });\n        break;\n      case FileSortOption.nameAsc:\n        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));\n        break;\n      case FileSortOption.nameDesc:\n        sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));\n        break;\n      case FileSortOption.sizeDesc:\n        sorted.sort((a, b) => b.size.compareTo(a.size));\n        break;\n      case FileSortOption.sizeAsc:\n        sorted.sort((a, b) => a.size.compareTo(b.size));\n        break;\n    }\n\n    return sorted;\n  }\n}\n