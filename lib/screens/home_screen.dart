import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_entry.dart';
import '../providers/health_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_icons.dart';
import '../widgets/vitals_card.dart';
import '../widgets/empty_state.dart';
import 'add_entry_screen.dart';
import 'entry_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _bpUnitLabel = 'mmHg';

  @override
  void initState() {
    super.initState();
    _loadUnitPreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthProvider>().loadEntries();
    });
  }

  Future<void> _loadUnitPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('unit_preference') ?? 'bpm/mmHg';
    final isKpa = saved == 'bpm/kPa';
    if (!mounted) return;
    setState(() {
      _bpUnitLabel = isKpa ? 'kPa' : 'mmHg';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'HealthCheck',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.profile, color: AppColors.primaryText),
            onPressed: () {
              // Profile action (placeholder)
            },
          ),
        ],
      ),
      body: Consumer<HealthProvider>(
        builder: (context, provider, child) {
          final latestEntry = provider.latestEntry;
          final recentEntries = provider.entries.take(3).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (latestEntry != null && latestEntry.isToday)
                        _buildTodayContent(latestEntry)
                      else
                        const EmptyState(
                          message:
                              'No entries yet — tap + to log your first vitals.',
                          icon: AppIcons.heart,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Recent entries section
                if (recentEntries.isNotEmpty) ...[
                  const Text(
                    'Recent Entries',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...recentEntries.map(
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
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEntryScreen()),
          ).then((_) {
            context.read<HealthProvider>().loadEntries();
          });
        },
        backgroundColor: AppColors.primaryAction,
        child: const Icon(AppIcons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTodayContent(HealthEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(AppIcons.clock, size: 16, color: AppColors.placeholder),
            const SizedBox(width: 8),
            Text(
              entry.formattedTime,
              style: const TextStyle(
                color: AppColors.placeholder,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (entry.heartRate != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${entry.heartRate}',
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'bpm',
                style: TextStyle(color: AppColors.primaryText, fontSize: 18),
              ),
            ],
          ),
        if (entry.systolicBP != null && entry.diastolicBP != null) ...[
          const SizedBox(height: 8),
          Text(
            '${entry.systolicBP}/${entry.diastolicBP} $_bpUnitLabel',
            style: const TextStyle(color: AppColors.primaryText, fontSize: 16),
          ),
        ],
        if (entry.symptoms != null && entry.symptoms!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            entry.symptoms!,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}
