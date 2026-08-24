import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/ui_helpers.dart';
import '../../domain/models/kappogy_file.dart';

class FileListItemWidget extends StatelessWidget {
  final KappogyFile file;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback? onTap;

  const FileListItemWidget({
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = FileTypeHelper.getInfo(file.name, isDirectory: file.isDirectory);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withAlpha(isDark ? 35 : 20)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryLight
              : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? onToggleSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onToggleSelect,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white38 : Colors.black26),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: info.gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: info.color.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(info.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [\n                      Text(\n                        file.name,\n                        maxLines: 1,\n                        overflow: TextOverflow.ellipsis,\n                        style: TextStyle(\n                          fontSize: 14,\n                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,\n                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,\n                        ),\n                      ),\n                      const SizedBox(height: 3),\n                      Row(\n                        children: [\n                          Text(\n                            _formatBytes(file.size),\n                            style: TextStyle(\n                              fontSize: 12,\n                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,\n                              fontWeight: FontWeight.w500,\n                            ),\n                          ),\n                          if (file.lastModified != null) ...[\n                            const SizedBox(width: 6),\n                            Text(\n                              '\u2022',\n                              style: TextStyle(\n                                fontSize: 10,\n                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,\n                              ),\n                            ),\n                            const SizedBox(width: 6),\n                            Text(\n                              _formatDate(file.lastModified),\n                              style: TextStyle(\n                                fontSize: 11,\n                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,\n                              ),\n                            ),\n                          ],\n                        ],\n                      ),\n                    ],\n                  ),\n                ),\n                Container(\n                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),\n                  decoration: BoxDecoration(\n                    color: info.color.withAlpha(25),\n                    borderRadius: BorderRadius.circular(6),\n                  ),\n                  child: Text(\n                    info.category,\n                    style: TextStyle(\n                      color: info.color,\n                      fontSize: 10,\n                      fontWeight: FontWeight.bold,\n                    ),\n                  ),\n                ),\n              ],\n            ),\n          ),\n        ),\n      ),\n    );\n  }\n}\n