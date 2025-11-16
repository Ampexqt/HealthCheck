import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/health_entry.dart';
import '../providers/health_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_icons.dart';
import '../widgets/vitals_card.dart';
import '../widgets/empty_state.dart';
import 'entry_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _showTodayOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthProvider>().loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: true,
        title: const Text(
          'History',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FilterButton(
                  label: 'Today',
                  isSelected: _showTodayOnly,
                  onTap: () => setState(() => _showTodayOnly = true),
                ),
                const SizedBox(width: 8),
                _FilterButton(
                  label: 'All',
                  isSelected: !_showTodayOnly,
                  onTap: () => setState(() => _showTodayOnly = false),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<HealthProvider>(
        builder: (context, provider, child) {
          List<HealthEntry> entries = _showTodayOnly
              ? provider.todayEntries
              : provider.entries;

          if (entries.isEmpty) {
            return const EmptyState(
              message: 'No entries found',
              icon: AppIcons.history,
            );
          }

          // Group entries by date
          final Map<String, List<HealthEntry>> groupedEntries = {};
          for (var entry in entries) {
            final dateKey = entry.formattedDate;
            groupedEntries.putIfAbsent(dateKey, () => []).add(entry);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: groupedEntries.length,
            itemBuilder: (context, index) {
              final dateKey = groupedEntries.keys.elementAt(index);
              final dateEntries = groupedEntries[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 12,
                      top: index > 0 ? 24 : 0,
                    ),
                    child: Text(
                      dateKey,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...dateEntries.map(
                    (entry) => VitalsCard(
                      entry: entry,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EntryDetailScreen(entry: entry),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAction : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryAction, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primaryAction,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
