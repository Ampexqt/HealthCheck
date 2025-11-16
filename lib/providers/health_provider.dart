import 'package:flutter/foundation.dart';
import '../models/health_entry.dart';
import '../services/health_service.dart';
import '../services/backup_service.dart';

/// Provider for managing health entries state
class HealthProvider with ChangeNotifier {
  final HealthService _service = HealthService();
  final BackupService _backupService = BackupService();
  List<HealthEntry> _entries = [];
  bool _isLoading = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  List<HealthEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;

  /// Get entries for today
  List<HealthEntry> get todayEntries {
    return _entries.where((entry) => entry.isToday).toList();
  }

  /// Get latest entry
  HealthEntry? get latestEntry {
    return _entries.isNotEmpty ? _entries.first : null;
  }

  /// Load all entries
  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      _entries = await _service.getAllEntries();
    } catch (e) {
      _entries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new entry
  Future<void> addEntry(HealthEntry entry) async {
    await _service.saveEntry(entry);
    await loadEntries();
  }

  /// Update an existing entry
  Future<void> updateEntry(HealthEntry entry) async {
    await _service.saveEntry(entry);
    await loadEntries();
  }

  /// Delete an entry
  Future<void> deleteEntry(String id) async {
    await _service.deleteEntry(id);
    await loadEntries();
  }

  /// Backup entries to Firebase
  Future<bool> backupToFirebase(String email) async {
    _isBackingUp = true;
    notifyListeners();

    try {
      final success = await _backupService.backupToFirebase(_entries, email);
      return success;
    } catch (e) {
      return false;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  /// Restore entries from Firebase
  Future<bool> restoreFromFirebase(String email) async {
    _isRestoring = true;
    notifyListeners();

    try {
      final restoredEntries = await _backupService.restoreFromFirebase(email);
      if (restoredEntries.isNotEmpty) {
        // Save restored entries to local storage
        for (final entry in restoredEntries) {
          await _service.saveEntry(entry);
        }
        await loadEntries();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  /// Get last backup time
  Future<DateTime?> getLastBackupTime() async {
    return await _backupService.getLastBackupTime();
  }

  /// Get last used backup email if available.
  Future<String?> getSavedBackupEmail() async {
    return _backupService.getSavedEmail();
  }
}
