import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ui_helpers.dart';
import '../../../transfer/application/transfer_engine.dart';
import '../../application/device_file_indexer_service.dart';
import '../../application/file_picker_service.dart';
import '../../application/file_selection_controller.dart';
import '../../domain/models/date_grouped_files.dart';
import '../../domain/models/device_file_indexer_state.dart';
import '../../domain/models/file_category.dart';
import '../widgets/bulk_folder_dialog.dart';
import '../widgets/date_group_header_widget.dart';
import '../widgets/file_list_item_widget.dart';
import '../widgets/media_thumbnail_widget.dart';

class SendLibraryScreen extends ConsumerStatefulWidget {
  const SendLibraryScreen({super.key});

  @override
  ConsumerState<SendLibraryScreen> createState() => _SendLibraryScreenState();
}

class _SendLibraryScreenState extends ConsumerState<SendLibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<FileCategory> _categories = [
    FileCategory.recent,
    FileCategory.photos,
    FileCategory.videos,
    FileCategory.audio,
    FileCategory.apps,
    FileCategory.contacts,
    FileCategory.files,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickExternalFiles() async {
    try {
      final pickedFiles = await ref.read(filePickerServiceProvider).pickFiles();
      if (pickedFiles.isNotEmpty) {
        ref.read(fileSelectionControllerProvider.notifier).selectAll(pickedFiles);
      }
    } catch (_) {}
  }

  Future<void> _pickExternalFolder() async {
    try {
      final pickedFolder = await ref.read(filePickerServiceProvider).pickFolder();
      if (pickedFolder != null) {
        ref.read(fileSelectionControllerProvider.notifier).toggleSelect(pickedFolder);
      }
    } catch (_) {}
  }

  void _openBulkFolderPicker() {
    BulkFolderDialog.show(context);
  }

  void _startSendFlow() {
    final selectedFiles =
        ref.read(fileSelectionControllerProvider).selectedFiles;
    if (selectedFiles.isEmpty) return;

    ref.read(transferEngineProvider.notifier).startAsSender(selectedFiles);
    context.push('/sender-waiting');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indexerState = ref.watch(deviceFileIndexerServiceProvider);
    final selection = ref.watch(fileSelectionControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  if (_isSearching) ...[
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search files across device...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              setState(() {
                                _isSearching = false;
                                _searchController.clear();
                                ref
                                    .read(deviceFileIndexerServiceProvider.notifier)
                                    .setSearchQuery('');
                              });
                            },
                          ),
                        ),
                        onChanged: (val) {
                          ref
                              .read(deviceFileIndexerServiceProvider.notifier)
                              .setSearchQuery(val);
                        },
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppGradients.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Send',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.folder_copy_rounded, color: AppColors.primaryLight),
                      tooltip: 'Send Bulk Folders',
                      onPressed: _openBulkFolderPicker,
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded),
                      tooltip: 'Search Library',
                      onPressed: () => setState(() => _isSearching = true),
                    ),
                    PopupMenuButton<FileSortOption>(
                      icon: const Icon(Icons.sort_rounded),
                      tooltip: 'Sort Options',
                      initialValue: indexerState.sortOption,
                      onSelected: (option) {
                        ref
                            .read(deviceFileIndexerServiceProvider.notifier)
                            .setSortOption(option);
                      },
                      itemBuilder: (ctx) => FileSortOption.values.map((opt) {
                        return PopupMenuItem(
                          value: opt,
                          child: Row(
                            children: [
                              if (opt == indexerState.sortOption)
                                const Icon(Icons.check_rounded,
                                    size: 18, color: AppColors.primaryLight)
                              else
                                const SizedBox(width: 18),
                              const SizedBox(width: 8),
                              Text(opt.label),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      tooltip: 'More Actions',
                      onSelected: (val) {
                        if (val == 'bulk_folder') {
                          _openBulkFolderPicker();
                        } else if (val == 'refresh') {
                          ref
                              .read(deviceFileIndexerServiceProvider.notifier)
                              .refresh();
                        } else if (val == 'pick_file') {
                          _pickExternalFiles();
                        } else if (val == 'add_folder') {
                          _pickExternalFolder();
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'bulk_folder',
                          child: Row(
                            children: [
                              Icon(Icons.folder_copy_rounded, size: 18, color: AppColors.primaryLight),
                              SizedBox(width: 10),
                              Text('Send Bulk Folders...'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'refresh',
                          child: Row(
                            children: [
                              Icon(Icons.refresh_rounded, size: 18),
                              SizedBox(width: 10),
                              Text('Refresh Library'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'pick_file',
                          child: Row(
                            children: [
                              Icon(Icons.file_open_rounded, size: 18),
                              SizedBox(width: 10),
                              Text('Browse Files...'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'add_folder',
                          child: Row(
                            children: [
                              Icon(Icons.create_new_folder_rounded, size: 18),
                              SizedBox(width: 10),
                              Text('Add Scan Folder...'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (indexerState.isScanning)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
              ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primary,
                unselectedLabelColor:
                    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: _categories.map((cat) {
                  return Tab(text: cat.label);
                }).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.map((category) {
                  return _buildCategoryView(category, indexerState, selection);
                }).toList(),
              ),
            ),
            if (selection.isNotEmpty)
              _buildSelectionDock(selection, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryView(
    FileCategory category,
    DeviceFileIndexerState indexerState,
    FileSelectionState selection,
  ) {
    final files = indexerState.getFilesForCategory(category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (files.isEmpty) {
      if (indexerState.isScanning) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Scanning device files in background...'),
            ],
          ),
        );
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, size: 48, color: AppColors.primaryLight),
              ),
              const SizedBox(height: 16),
              Text(
                'No ${category.label.toLowerCase()} found',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add custom folders to index or browse files directly from disk.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.file_open_rounded, size: 18),
                    label: const Text('Browse Files'),
                    onPressed: _pickExternalFiles,
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.folder_copy_rounded, size: 18),
                    label: const Text('Send Folders'),
                    onPressed: _openBulkFolderPicker,
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.create_new_folder_rounded, size: 18),
                    label: const Text('Add Scan Folder'),
                    onPressed: _pickExternalFolder,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final dateGroups = DateGroupedFiles.groupFiles(files);
    final isGridCategory = category == FileCategory.photos ||
        category == FileCategory.videos ||
        category == FileCategory.recent;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(deviceFileIndexerServiceProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          if (category == FileCategory.files) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12, top: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.primaryLight.withAlpha(40) : AppColors.primary.withAlpha(20),
                ),
              ),
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
                          'Send Entire Folders',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Bundle & transfer one or multiple directories',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _openBulkFolderPicker,
                    child: const Text('Pick Folders'),
                  ),
                ],
              ),
            ),
          ],
          ...dateGroups.map((group) {
            final isGroupSelected = selection.isGroupSelected(group.files);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DateGroupHeaderWidget(
                  group: group,
                  isAllSelected: isGroupSelected,
                  onToggleGroup: () {
                    ref
                        .read(fileSelectionControllerProvider.notifier)
                        .toggleGroup(group.files);
                  },
                ),
                if (isGridCategory) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width < 420
                          ? 3
                          : (width < 700 ? 4 : (width < 1000 ? 6 : 8));

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: group.files.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, itemIdx) {
                          final file = group.files[itemIdx];
                          final isSelected = selection.isSelected(file);

                          return MediaThumbnailWidget(
                            file: file,
                            isSelected: isSelected,
                            onToggleSelect: () {
                              ref
                                  .read(fileSelectionControllerProvider.notifier)
                                  .toggleSelect(file);
                            },
                          );
                        },
                      );
                    },
                  ),
                ] else ...[
                  ...group.files.map((file) {
                    final isSelected = selection.isSelected(file);
                    return FileListItemWidget(
                      file: file,
                      isSelected: isSelected,
                      onToggleSelect: () {
                        ref
                            .read(fileSelectionControllerProvider.notifier)
                            .toggleSelect(file);
                      },
                    );
                  }),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSelectionDock(FileSelectionState selection, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 30),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${selection.count}',
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${selection.count == 1 ? "Item" : "Items"} Selected',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Total Size: ${selection.formattedTotalSize}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Clear Selection',
            onPressed: () {
              ref.read(fileSelectionControllerProvider.notifier).clearSelection();
            },
          ),
          const SizedBox(width: 8),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              label: Text(
                'Send (${selection.count})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
              onPressed: _startSendFlow,
            ),
          ),
        ],
      ),
    );
  }
}
