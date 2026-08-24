import 'package:flutter/material.dart';

class AppColors {
  // Primary brand palette
  static const Color primary = Color(0xFF4F46E5); // Indigo
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF3730A3);
  
  // Secondary & Accents
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color accent = Color(0xFF10B981); // Emerald green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Crimson
  static const Color info = Color(0xFF3B82F6); // Sky blue

  // Neutral & Surfaces for Dark Theme
  static const Color darkBg = Color(0xFF0B0F19); // Midnight Obsidian
  static const Color darkSurface = Color(0xFF111827); // Deep Slate
  static const Color darkCard = Color(0xFF1F2937); // Elevated Card
  static const Color darkCardBorder = Color(0x26FFFFFF); // 15% white outline
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // Neutral & Surfaces for Light Theme
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0x1A000000); // 10% black outline
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Pure AMOLED
  static const Color amoledBg = Color(0xFF000000);
  static const Color amoledSurface = Color(0xFF000000);
  static const Color amoledCard = Color(0xFF121212);
  static const Color amoledBorder = Color(0x33333333);
}

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanIndigoGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient radarGradient = LinearGradient(
    colors: [Color(0x334F46E5), Color(0x0506B6D4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient cardGlass(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? [const Color(0x22FFFFFF), const Color(0x0DFFFFFF)]
          : [const Color(0xCCFFFFFF), const Color(0x99FFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

class FileTypeInfo {
  final IconData icon;
  final Color color;
  final LinearGradient gradient;
  final String category;

  const FileTypeInfo({
    required this.icon,
    required this.color,
    required this.gradient,
    required this.category,
  });
}

class FileTypeHelper {
  static FileTypeInfo getInfo(String filename, {bool isDirectory = false}) {
    if (isDirectory) {
      return const FileTypeInfo(
        icon: Icons.folder_rounded,
        color: Color(0xFFF59E0B),
        gradient: LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFD97706)]),
        category: 'Folder',
      );
    }

    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';

    switch (ext) {
      // Images
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'svg':
      case 'bmp':
      case 'heic':
        return const FileTypeInfo(
          icon: Icons.image_rounded,
          color: Color(0xFFEC4899),
          gradient: LinearGradient(colors: [Color(0xFFF472B6), Color(0xFFDB2777)]),
          category: 'Image',
        );

      // Videos
      case 'mp4':
      case 'mkv':
      case 'mov':
      case 'avi':
      case 'webm':
      case 'flv':
      case 'wmv':
        return const FileTypeInfo(
          icon: Icons.movie_rounded,
          color: Color(0xFF8B5CF6),
          gradient: LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
          category: 'Video',
        );

      // Audio
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'm4a':
      case 'ogg':
        return const FileTypeInfo(
          icon: Icons.music_note_rounded,
          color: Color(0xFFF97316),
          gradient: LinearGradient(colors: [Color(0xFFFB923C), Color(0xFFEA580C)]),
          category: 'Audio',
        );

      // Documents
      case 'pdf':
        return const FileTypeInfo(
          icon: Icons.picture_as_pdf_rounded,
          color: Color(0xFFEF4444),
          gradient: LinearGradient(colors: [Color(0xFFF87171), Color(0xFFDC2626)]),
          category: 'PDF Document',
        );
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
      case 'odt':
        return const FileTypeInfo(
          icon: Icons.description_rounded,
          color: Color(0xFF3B82F6),
          gradient: LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF2563EB)]),
          category: 'Document',
        );
      case 'xls':
      case 'xlsx':
      case 'csv':
        return const FileTypeInfo(
          icon: Icons.table_chart_rounded,
          color: Color(0xFF10B981),
          gradient: LinearGradient(colors: [Color(0xFF34D399), Color(0xFF059669)]),
          category: 'Spreadsheet',
        );
      case 'ppt':
      case 'pptx':
        return const FileTypeInfo(
          icon: Icons.slideshow_rounded,
          color: Color(0xFFF59E0B),
          gradient: LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFD97706)]),
          category: 'Presentation',
        );

      // Archives
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return const FileTypeInfo(
          icon: Icons.folder_zip_rounded,
          color: Color(0xFF14B8A6),
          gradient: LinearGradient(colors: [Color(0xFF2DD4BF), Color(0xFF0D9488)]),
          category: 'Archive',
        );

      // Applications & Code
      case 'apk':
        return const FileTypeInfo(
          icon: Icons.android_rounded,
          color: Color(0xFF22C55E),
          gradient: LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF16A34A)]),
          category: 'Android Package',
        );
      case 'exe':
      case 'msi':
        return const FileTypeInfo(
          icon: Icons.window_rounded,
          color: Color(0xFF0284C7),
          gradient: LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF0369A1)]),\
          category: 'Windows Application',
        );
      case 'dart':
      case 'js':
      case 'ts':
      case 'json':
      case 'html':
      case 'css':
      case 'py':
      case 'cpp':
      case 'c':
      case 'java':
        return const FileTypeInfo(
          icon: Icons.code_rounded,
          color: Color(0xFF6366F1),
          gradient: LinearGradient(colors: [Color(0xFF818CF8), Color(0xFF4F46E5)]),
          category: 'Code File',
        );

      // Default Generic File
      default:
        return const FileTypeInfo(
          icon: Icons.insert_drive_file_rounded,
          color: Color(0xFF64748B),
          gradient: LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF475569)]),
          category: 'File',
        );
    }
  }
}
