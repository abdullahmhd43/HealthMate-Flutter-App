import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/health_records_provider.dart';
import '../widgets/delete_record_dialog.dart';
import '../widgets/record_tile.dart';
import 'record_detail_screen.dart';
import 'record_form_screen.dart';

/// Lists every record (newest first) with date search and range filtering.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<HealthRecordsProvider>().searchQuery;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) context.read<HealthRecordsProvider>().setSearchQuery(value);
    });
    setState(() {}); // refresh the clear button
  }

  Future<void> _pickSingleDate() async {
    final provider = context.read<HealthRecordsProvider>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateHelper.dateOnly(now),
      firstDate: AppConstants.earliestDate,
      lastDate: DateHelper.dateOnly(now),
      helpText: 'Find records on a date',
    );
    if (picked == null || !mounted) return;
    final iso = DateHelper.toIso(picked);
    _searchController.text = iso;
    setState(() {});
    await provider.setSearchQuery(iso);
  }

  Future<void> _pickRange() async {
    final provider = context.read<HealthRecordsProvider>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: AppConstants.earliestDate,
      lastDate: DateHelper.dateOnly(now),
      initialDateRange: provider.dateRange,
      helpText: 'Filter by date range',
    );
    if (picked == null || !mounted) return;
    await provider.setDateRange(picked);
  }

  Future<void> _clearAll() async {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {});
    await context.read<HealthRecordsProvider>().clearFilters();
  }

  void _openDetail(int id) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => RecordDetailScreen(recordId: id),
    ));
  }

  void _openEdit(int id) {
    Navigator.of(context).push(MaterialPageRoute<bool>(
      builder: (_) => RecordFormScreen(recordId: id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthRecordsProvider>();
    final theme = Theme.of(context);
    final range = provider.dateRange;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              key: const Key('search_field'),
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by date (e.g. 2026-11 or 06/11/2026)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _debounce?.cancel();
                          _searchController.clear();
                          setState(() {});
                          provider.setSearchQuery('');
                        },
                      ),
                    IconButton(
                      key: const Key('pick_date_button'),
                      tooltip: 'Pick a date',
                      icon: const Icon(Icons.calendar_today_rounded),
                      onPressed: _pickSingleDate,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (range == null)
                  ActionChip(
                    key: const Key('range_chip'),
                    avatar: const Icon(Icons.date_range_rounded, size: 18),
                    label: const Text('Date range'),
                    onPressed: _pickRange,
                  )
                else
                  InputChip(
                    key: const Key('range_chip'),
                    avatar: const Icon(Icons.date_range_rounded, size: 18),
                    label: Text(
                        '${DateHelper.shortDay(range.start)} – ${DateHelper.shortDay(range.end)}'),
                    onPressed: _pickRange,
                    onDeleted: () => provider.setDateRange(null),
                  ),
                const Spacer(),
                Text(
                  '${provider.visibleRecords.length} '
                  '${provider.visibleRecords.length == 1 ? 'record' : 'records'}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildList(context, provider)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, HealthRecordsProvider provider) {
    if (provider.isLoading && !provider.isInitialised) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.allRecords.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        message: provider.error!,
        actionLabel: 'Try again',
        onAction: provider.refresh,
      );
    }

    final records = provider.visibleRecords;

    if (records.isEmpty) {
      if (provider.hasActiveFilters) {
        return EmptyState(
          icon: Icons.search_off_rounded,
          title: 'No matching records',
          message: 'No records match your search or date filter.',
          actionLabel: 'Clear filters',
          onAction: _clearAll,
        );
      }
      return EmptyState(
        icon: Icons.history_rounded,
        title: 'No records yet',
        message: 'Your saved daily records will appear here.',
        actionLabel: 'Add record',
        onAction: () => Navigator.of(context).push(MaterialPageRoute<bool>(
          builder: (_) => const RecordFormScreen(),
        )),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = records[index];
        return RecordTile(
          key: ValueKey(record.id),
          record: record,
          isSample: provider.isSample(record),
          onTap: () => _openDetail(record.id!),
          onEdit: () => _openEdit(record.id!),
          onDelete: () => confirmAndDeleteRecord(context, record),
        );
      },
    );
  }
}
