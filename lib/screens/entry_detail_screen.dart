import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_entry.dart';
import '../providers/health_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_icons.dart';
import 'add_entry_screen.dart';

class EntryDetailScreen extends StatefulWidget {
  final HealthEntry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  String _bpUnitLabel = 'mmHg';

  @override
  void initState() {
    super.initState();
    _loadUnitPreference();
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

  void _deleteEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text(
          'Delete Entry',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: const Text(
          'Are you sure you want to delete this entry?',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<HealthProvider>()
                  .deleteEntry(widget.entry.id)
                  .then((_) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close detail screen
              });
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.deleteDanger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Entry Details',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.edit, color: AppColors.primaryAction),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEntryScreen(entry: widget.entry),
                ),
              ).then((_) {
                context.read<HealthProvider>().loadEntries();
              });
            },
          ),
          IconButton(
            icon: const Icon(AppIcons.delete, color: AppColors.deleteDanger),
            onPressed: () => _deleteEntry(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and time
              Row(
                children: [
                  const Icon(
                    AppIcons.clock,
                    size: 18,
                    color: AppColors.primaryText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.entry.formattedDateTime,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Heart Rate
              if (widget.entry.heartRate != null) ...[
                Row(
                  children: [
                    const Icon(
                      AppIcons.heart,
                      size: 20,
                      color: AppColors.primaryText,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Heart Rate',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${widget.entry.heartRate}',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'bpm',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              // Blood Pressure
              if (widget.entry.systolicBP != null && widget.entry.diastolicBP != null) ...[
                Row(
                  children: [
                    const Icon(
                      AppIcons.ecgWave,
                      size: 20,
                      color: AppColors.primaryText,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Blood Pressure',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${widget.entry.systolicBP}/${widget.entry.diastolicBP}',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _bpUnitLabel,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              // Symptoms
              Row(
                children: [
                  const Icon(
                    AppIcons.symptoms,
                    size: 20,
                    color: AppColors.primaryText,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Symptoms',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider, width: 1),
                ),
                child: Text(
                  widget.entry.symptoms ?? 'No symptoms noted',
                  style: TextStyle(
                    color: widget.entry.symptoms != null
                        ? AppColors.primaryText
                        : AppColors.placeholder,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
