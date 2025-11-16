import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_entry.dart';
import '../utils/app_colors.dart';
import '../utils/app_icons.dart';

/// Widget for displaying a single health entry preview card
class VitalsCard extends StatefulWidget {
  final HealthEntry entry;
  final VoidCallback? onTap;

  const VitalsCard({super.key, required this.entry, this.onTap});

  @override
  State<VitalsCard> createState() => _VitalsCardState();
}

class _VitalsCardState extends State<VitalsCard> {
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(AppIcons.clock, size: 16, color: AppColors.secondaryText),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.entry.formattedTime,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  if (widget.entry.symptoms != null &&
                      widget.entry.symptoms!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.entry.symptoms!,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                if (widget.entry.heartRate != null)
                  _buildVitalsBadge(
                    icon: AppIcons.heart,
                    value: '${widget.entry.heartRate}',
                  ),
                if (widget.entry.systolicBP != null &&
                    widget.entry.diastolicBP != null)
                  _buildVitalsBadge(
                    icon: AppIcons.ecgWave,
                    value:
                        '${widget.entry.systolicBP}/${widget.entry.diastolicBP} $_bpUnitLabel',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsBadge({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.vitalsBadge,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
