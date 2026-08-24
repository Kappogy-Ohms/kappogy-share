import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/ui_helpers.dart';
import '../../domain/models/file_category.dart';
import '../../domain/models/kappogy_file.dart';

class MediaThumbnailWidget extends StatelessWidget {
  final KappogyFile file;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback? onTap;

  const MediaThumbnailWidget({
    super.key,
    required this.file,
    required this.isSelected,
    required this.onToggleSelect,
    this.onTap,
  });

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    final size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = FileCategory.fromExtension(file.name) == FileCategory.videos;
    final info = FileTypeHelper.getInfo(file.name);

    return GestureDetector(
      onTap: onTap ?? onToggleSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(100),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.grey.shade900,
                child: File(file.path).existsSync()
                    ? Image.file(
                        File(file.path),
                        fit: BoxFit.cover,
                        cacheWidth: 320,
                        cacheHeight: 320,
                        errorBuilder: (_, _, _) => Container(
                          decoration: BoxDecoration(gradient: info.gradient),
                          child: Center(
                            child: Icon(info.icon, color: Colors.white, size: 32),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(gradient: info.gradient),
                        child: Center(
                          child: Icon(info.icon, color: Colors.white, size: 32),
                        ),
                      ),
              ),
              if (isVideo)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          _formatBytes(file.size),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatBytes(file.size),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 6,
                left: 6,
                child: GestureDetector(
                  onTap: onToggleSelect,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primary : Colors.black.withAlpha(80),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white.withAlpha(200),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(100),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
                          )
                        : null,
                  ),
                ),
              ),
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    color: AppColors.primary.withAlpha(40),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
