import 'package:flutter/material.dart';
import '../../../../core/theme/ui_helpers.dart';
import '../../domain/models/date_grouped_files.dart';

class DateGroupHeaderWidget extends StatelessWidget {
  final DateGroupedFiles group;
  final bool isAllSelected;
  final VoidCallback onToggleGroup;

  const DateGroupHeaderWidget({
    super.key,
    required this.group,
    required this.isAllSelected,
    required this.onToggleGroup,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onToggleGroup,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isAllSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isAllSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white38 : Colors.black38),
                    width: 2,
                  ),
                ),
                child: isAllSelected
                    ? const Center(
                        child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                group.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${group.files.length} ${group.files.length == 1 ? "item" : "items"}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
