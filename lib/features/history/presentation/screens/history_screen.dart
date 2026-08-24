import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ui_helpers.dart';
import '../../application/history_service.dart';
import '../../../transfer/domain/models/transfer_session.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 0) return 'Today, $timeStr';
    if (diff.inDays == 1) return 'Yesterday, $timeStr';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} $timeStr';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyAsync = ref.watch(historyServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear History',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear All History?'),
                  content: const Text('This will remove all logged records of past transfers. Transferred files on your disk will not be deleted.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () {
                        ref.read(historyServiceProvider.notifier).clearHistory();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: historyAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history_rounded, size: 56, color: AppColors.primaryLight),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Past Transfers',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your incoming and outgoing transfers will show up here.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Start Sharing'),
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            );
          }

          final totalBytes = records.fold<int>(0, (sum, r) => sum + r.totalBytes);
          final successCount = records.where((r) => r.status == TransferStatus.completed).length;
          final successPercent = ((successCount / records.length) * 100).toInt();

          final filtered = records.where((r) {
            if (_searchQuery.isNotEmpty &&
                !r.filename.toLowerCase().contains(_searchQuery.toLowerCase())) {
              return false;
            }
            if (_selectedFilter == 'Sent') return r.role == TransferRole.sender;
            if (_selectedFilter == 'Received') return r.role == TransferRole.receiver;
            if (_selectedFilter == 'Success') return r.status == TransferStatus.completed;
            if (_selectedFilter == 'Failed') return r.status == TransferStatus.failed;
            return true;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppColors.primaryLight.withAlpha(50) : AppColors.primary.withAlpha(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Data', _formatBytes(totalBytes), AppColors.primaryLight),
                    Container(height: 36, width: 1, color: isDark ? Colors.white24 : Colors.black12),
                    _buildStatItem('Transfers', '${records.length}', AppColors.secondary),
                    Container(height: 36, width: 1, color: isDark ? Colors.white24 : Colors.black12),
                    _buildStatItem('Success Rate', '$successPercent%', AppColors.accent),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search transfers by filename...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Sent', 'Received', 'Success', 'Failed'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withAlpha(40),
                        checkmarkColor: AppColors.primaryLight,
                        onSelected: (val) {
                          setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('No transfers match your filter.')),
                )
              else
                ...filtered.map((record) {
                  final info = FileTypeHelper.getInfo(record.filename);
                  final isSuccess = record.status == TransferStatus.completed;
                  final isSent = record.role == TransferRole.sender;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: info.gradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: info.color.withAlpha(80),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(info.icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.filename,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    isSent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                    size: 13,
                                    color: isSent ? AppColors.primaryLight : AppColors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${isSent ? "Sent" : "Received"} \u2022 ${_formatBytes(record.totalBytes)} \u2022 ${_formatDate(record.date)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSuccess ? AppColors.accent.withAlpha(25) : AppColors.error.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSuccess ? AppColors.accent.withAlpha(80) : AppColors.error.withAlpha(80),
                            ),
                          ),
                          child: Text(
                            isSuccess ? 'Success' : 'Failed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSuccess ? AppColors.accent : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryLight)),
        error: (e, _) => Center(child: Text('Error loading history: $e')),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
