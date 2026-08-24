import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ui_helpers.dart';
import '../../../transfer/application/transfer_engine.dart';
import '../../application/file_picker_service.dart';
import '../../application/file_selection_controller.dart';
import '../../domain/models/folder_item_info.dart';

class BulkFolderDialog extends ConsumerStatefulWidget {
  const BulkFolderDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BulkFolderDialog(),
    );
  }

  @override
  ConsumerState<BulkFolderDialog> createState() => _BulkFolderDialogState();
}

class _BulkFolderDialogState extends ConsumerState<BulkFolderDialog> {
  final List<FolderItemInfo> _folders = [];
  bool _isProcessing = false;
  String _processingStatus = '';

  Future<void> _pickSingleFolder() async {
    final path = await FilePicker.getDirectoryPath();
    if (path != null && path.isNotEmpty) {
      if (_folders.any((f) => f.path == path)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This folder is already in the list.')),
          );
        }
        return;
      }

      final info = await FolderItemInfo.fromDirectory(Directory(path));
      if (mounted) {
        setState(() {
          _folders.add(info);
        });
      }
    }
  }

  Future<void> _processAndSend() async {
    if (_folders.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Preparing folders...';
    });

    try {
      final pickerService = ref.read(filePickerServiceProvider);
      final paths = _folders.map((f) => f.path).toList();

      final packedFiles = await pickerService.packageMultipleFolders(
        paths,
        onProgress: (current, total, name) {
          if (mounted) {
            setState(() {
              _processingStatus = 'Packing ($current/$total): $name...';
            });
          }
        },
      );

      if (packedFiles.isNotEmpty) {
        ref.read(fileSelectionControllerProvider.notifier).selectAll(packedFiles);
        ref.read(transferEngineProvider.notifier).startAsSender(packedFiles);

        if (mounted) {
          Navigator.pop(context);
          context.push('/sender-waiting');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to package folders: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalFiles = _folders.fold(0, (sum, f) => sum + f.fileCount);
    final totalBytes = _folders.fold(0, (sum, f) => sum + f.totalBytes);
    final totalSizeMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_copy_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Bulk Folders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Pick one or multiple directories to bundle and share',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(
            child: _folders.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.create_new_folder_rounded, size: 52, color: AppColors.primaryLight),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Folders Selected Yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click the button below to pick directories from your storage to send in bulk.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Folder'),
                            onPressed: _pickSingleFolder,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: _folders.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _folders.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
                            ),
                            icon: const Icon(Icons.add_rounded, color: AppColors.primaryLight),
                            label: const Text(
                              'Add Another Folder',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                            ),
                            onPressed: _pickSingleFolder,
                          ),
                        );
                      }

                      final folder = _folders[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBg : AppColors.lightBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.folder_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    folder.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${folder.fileCount} items \u2022 ${folder.formattedSize}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                              tooltip: 'Remove folder',
                              onPressed: () {
                                setState(() {
                                  _folders.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_folders.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_isProcessing) ...[
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _processingStatus,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_folders.length} ${_folders.length == 1 ? "Folder" : "Folders"}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$totalFiles files \u2022 $totalSizeMb MB',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(120),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          label: Text(
                            _isProcessing ? 'Packaging...' : 'Send (${_folders.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          onPressed: _isProcessing ? null : _processAndSend,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
