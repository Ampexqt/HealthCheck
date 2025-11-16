import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/health_provider.dart';
import '../models/health_entry.dart';
import '../utils/app_colors.dart';
import '../utils/app_icons.dart';
import '../widgets/vitals_input_field.dart';

class AddEntryScreen extends StatefulWidget {
  final HealthEntry? entry; // For editing existing entry

  const AddEntryScreen({super.key, this.entry});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _heartRateController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _bpUnitLabel = 'mmHg';

  @override
  void initState() {
    super.initState();
    _loadUnitPreference();
    if (widget.entry != null) {
      _heartRateController.text = widget.entry!.heartRate?.toString() ?? '';
      _systolicController.text = widget.entry!.systolicBP?.toString() ?? '';
      _diastolicController.text = widget.entry!.diastolicBP?.toString() ?? '';
      _symptomsController.text = widget.entry!.symptoms ?? '';
    }
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
  void dispose() {
    _heartRateController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      final entry = HealthEntry(
        id: widget.entry?.id ?? const Uuid().v4(),
        heartRate: _heartRateController.text.isNotEmpty
            ? int.tryParse(_heartRateController.text)
            : null,
        systolicBP: _systolicController.text.isNotEmpty
            ? int.tryParse(_systolicController.text)
            : null,
        diastolicBP: _diastolicController.text.isNotEmpty
            ? int.tryParse(_diastolicController.text)
            : null,
        symptoms: _symptomsController.text.trim().isEmpty
            ? null
            : _symptomsController.text.trim(),
        timestamp: widget.entry?.timestamp ?? DateTime.now(),
      );

      final provider = context.read<HealthProvider>();
      if (widget.entry != null) {
        provider.updateEntry(entry).then((_) {
          Navigator.pop(context);
        });
      } else {
        provider.addEntry(entry).then((_) {
          Navigator.pop(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'New Entry',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Heart Rate input
              VitalsInputField(
                label: 'Heart Rate (bpm)',
                placeholder: 'Enter heart rate',
                icon: AppIcons.heart,
                controller: _heartRateController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              // Blood Pressure inputs
              Row(
                children: [
                  Expanded(
                    child: VitalsInputField(
                      label: 'Systolic ($_bpUnitLabel)',
                      placeholder: 'Systolic',
                      icon: AppIcons.ecgWave,
                      controller: _systolicController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: VitalsInputField(
                      label: 'Diastolic ($_bpUnitLabel)',
                      placeholder: 'Diastolic',
                      icon: AppIcons.bloodPressure,
                      controller: _diastolicController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Symptoms input
              VitalsInputField(
                label: 'Symptoms (optional)',
                placeholder: 'Any symptoms to note?',
                icon: AppIcons.symptoms,
                controller: _symptomsController,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              // Timestamp row
              Row(
                children: [
                  const Icon(
                    AppIcons.clock,
                    size: 18,
                    color: AppColors.primaryText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Now',
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Save button
              ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAction,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Save Entry',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.primaryText, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
