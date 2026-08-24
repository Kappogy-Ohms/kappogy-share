import 'package:flutter/material.dart';

enum FileCategory {
  recent,
  photos,
  videos,
  audio,
  apps,
  contacts,
  files;

  String get label {
    switch (this) {
      case FileCategory.recent:
        return 'RECENT';
      case FileCategory.photos:
        return 'PHOTOS';
      case FileCategory.videos:
        return 'VIDEOS';
      case FileCategory.audio:
        return 'AUDIO';
      case FileCategory.apps:
        return 'APPS';
      case FileCategory.contacts:
        return 'CONTACTS';
      case FileCategory.files:
        return 'FILES';
    }
  }

  IconData get icon {
    switch (this) {
      case FileCategory.recent:
        return Icons.access_time_rounded;
      case FileCategory.photos:
        return Icons.image_rounded;
      case FileCategory.videos:
        return Icons.videocam_rounded;
      case FileCategory.audio:
        return Icons.audiotrack_rounded;
      case FileCategory.apps:
        return Icons.apps_rounded;
      case FileCategory.contacts:
        return Icons.contacts_rounded;
      case FileCategory.files:
        return Icons.folder_rounded;
    }
  }

  static FileCategory fromExtension(String ext) {
    final cleanExt = ext.toLowerCase().replaceAll('.', '');
    
    // Photos
    if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic', 'heif', 'svg', 'raw', 'ico', 'tiff'].contains(cleanExt)) {
      return FileCategory.photos;
    }
    // Videos
    if (['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', '3gp', 'm4v', 'ts', 'vob', 'ogv'].contains(cleanExt)) {
      return FileCategory.videos;
    }
    // Audio
    if (['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'wma', 'opus', 'mid', 'midi', 'amr', 'aiff'].contains(cleanExt)) {
      return FileCategory.audio;
    }
    // Apps
    if (['apk', 'xapk', 'apkm', 'exe', 'msi', 'app', 'dmg', 'deb', 'rpm', 'bat', 'sh'].contains(cleanExt)) {
      return FileCategory.apps;
    }
    // Contacts
    if (['vcf', 'vcard', 'contact'].contains(cleanExt)) {
      return FileCategory.contacts;
    }
    // Files / Documents / Other
    return FileCategory.files;
  }
}
