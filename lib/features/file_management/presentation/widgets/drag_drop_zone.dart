import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/kappogy_file.dart';
import '../../../../core/theme/ui_helpers.dart';

class DragDropZone extends ConsumerStatefulWidget {
  final Widget child;
  final ValueChanged<List<KappogyFile>> onFilesDropped;

  const DragDropZone({
    super.key,
    required this.child,
    required this.onFilesDropped,
  });

  @override
  ConsumerState<DragDropZone> createState() => _DragDropZoneState();
}

class _DragDropZoneState extends ConsumerState<DragDropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return widget.child;
    }

    return DropTarget(
      onDragEntered: (details) {
        setState(() {
          _isDragging = true;
        });
      },
      onDragExited: (details) {
        setState(() {
          _isDragging = false;
        });
      },
      onDragDone: (details) async {
        setState(() {
          _isDragging = false;
        });

        if (details.files.isEmpty) return;

        final droppedFiles = <KappogyFile>[];
        for (final xfile in details.files) {
          final isDir = await FileSystemEntity.isDirectory(xfile.path);
          if (isDir) {
            droppedFiles.add(KappogyFile.fromDirectory(Directory(xfile.path)));
          } else {
            droppedFiles.add(KappogyFile.fromFile(File(xfile.path)));
          }
        }

        if (droppedFiles.isNotEmpty) {
          widget.onFilesDropped(droppedFiles);
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDragging)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(160),
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkCard
                          : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.primaryLight,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(100),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppGradients.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(80),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.cloud_upload_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Drop Files or Folders Here',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Release to instantly generate a secure transfer session',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
