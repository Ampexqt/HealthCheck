import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../providers/health_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedUnit = 'bpm/mmHg';
  DateTime? _lastBackupTime;

  @override
  void initState() {
    super.initState();
    _loadUnitPreference();
    _loadLastBackupTime();
  }

  Future<void> _loadUnitPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('unit_preference') ?? 'bpm/mmHg';
    if (!mounted) return;
    setState(() {
      _selectedUnit = saved;
    });
  }

  Future<void> _loadLastBackupTime() async {
    final provider = context.read<HealthProvider>();
    final lastBackup = await provider.getLastBackupTime();
    if (mounted) {
      setState(() {
        _lastBackupTime = lastBackup;
      });
    }
  }

  Future<void> _onUnitChanged(String newValue) async {
    setState(() {
      _selectedUnit = newValue;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unit_preference', newValue);
  }

  Future<void> _backupToFirebase(BuildContext context) async {
    final provider = context.read<HealthProvider>();

    if (provider.entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No entries to backup'),
            backgroundColor: AppColors.secondaryText,
          ),
        );
      }
      return;
    }

    final email = await _promptForEmail(context, isBackup: true);
    if (email == null) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasConnection = connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet);

    if (!hasConnection) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot backup, no internet connection'),
            backgroundColor: AppColors.deleteDanger,
          ),
        );
      }
      return;
    }

    final success = await provider.backupToFirebase(email);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup completed. Your data is saved to the cloud.'),
            backgroundColor: AppColors.primaryAction,
          ),
        );
        _loadLastBackupTime();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Backup failed. Firebase may not be configured. The app works offline without Firebase.',
            ),
            backgroundColor: AppColors.deleteDanger,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _restoreFromFirebase(BuildContext context) async {
    final provider = context.read<HealthProvider>();

    final email = await _promptForEmail(context, isBackup: false);
    if (email == null) return;

    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text(
          'Restore Backup',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: const Text(
          'This will replace your current local data with the backup from Firebase. Continue?',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Restore',
              style: TextStyle(color: AppColors.primaryAction),
            ),
          ),
        ],
      ),
    );

    if (shouldRestore != true) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasConnection = connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet);

    if (!hasConnection) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot restore, no internet connection'),
            backgroundColor: AppColors.deleteDanger,
          ),
        );
      }
      return;
    }

    final success = await provider.restoreFromFirebase(email);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore successful!'),
            backgroundColor: AppColors.primaryAction,
          ),
        );
        _loadLastBackupTime();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Restore failed. No backup found or Firebase not configured.',
            ),
            backgroundColor: AppColors.deleteDanger,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _formatBackupTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<String?> _promptForEmail(BuildContext context,
      {required bool isBackup}) async {
    final provider = context.read<HealthProvider>();
    final existingEmail = await provider.getSavedBackupEmail();
    final controller = TextEditingController(text: existingEmail ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          title: Text(
            isBackup ? 'Backup Data' : 'Restore Data',
            style: const TextStyle(color: AppColors.primaryText),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your email to link the backup to you.',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.primaryText),
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  hintStyle: TextStyle(color: AppColors.secondaryText),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.secondaryText),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryAction),
                  ),
                ),
              ),
            ],
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
                final email = controller.text.trim();
                final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(email);
                if (!isValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email address.'),
                      backgroundColor: AppColors.deleteDanger,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, email);
              },
              child: Text(
                isBackup ? 'Backup Now' : 'Restore Now',
                style: const TextStyle(color: AppColors.primaryAction),
              ),
            ),
          ],
        );
      },
    );

    return result;
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
          'Settings',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preferences section
            const Text(
              'Preferences',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _SettingsRow(
                label: 'Units',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedUnit,
                    dropdownColor: AppColors.cardSurface,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 14,
                    ),
                    underline: Container(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primaryText,
                      size: 20,
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'bpm/mmHg',
                        child: Text('bpm/mmHg'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'bpm/kPa',
                        child: Text('bpm/kPa'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _onUnitChanged(newValue);
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Backup section
            const Text(
              'Backup & Restore',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _SettingsRow(
                    label: 'Backup',
                    trailing: Consumer<HealthProvider>(
                      builder: (context, provider, child) {
                        if (provider.isBackingUp) {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryAction,
                            ),
                          );
                        }
                        return const Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.primaryAction,
                          size: 20,
                        );
                      },
                    ),
                    onTap: () => _backupToFirebase(context),
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  _SettingsRow(
                    label: 'Restore',
                    trailing: Consumer<HealthProvider>(
                      builder: (context, provider, child) {
                        if (provider.isRestoring) {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryAction,
                            ),
                          );
                        }
                        return const Icon(
                          Icons.cloud_download_outlined,
                          color: AppColors.primaryAction,
                          size: 20,
                        );
                      },
                    ),
                    onTap: () => _restoreFromFirebase(context),
                  ),
                  if (_lastBackupTime != null) ...[
                    const Divider(color: AppColors.divider, height: 1),
                    _SettingsRow(
                      label: 'Last Backup',
                      trailing: Text(
                        _formatBackupTime(_lastBackupTime!),
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            // About section
            const Text(
              'About',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _SettingsRow(
                    label: 'Version',
                    trailing: const Text(
                      '1.0.0',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  _SettingsRow(
                    label: 'Privacy Policy',
                    trailing: const Text(
                      'View Policy',
                      style: TextStyle(
                        color: AppColors.primaryAction,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      // Privacy policy action (placeholder)
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsRow({required this.label, required this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
