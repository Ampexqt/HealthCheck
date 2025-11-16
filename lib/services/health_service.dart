import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_entry.dart';

/// Service for managing health entries using Hive for offline-first storage.
class HealthService {
  static const String _entriesBoxName = 'health_entries';
  static const String _settingsBoxName = 'health_settings';
  static const String _legacyEntriesKey = 'health_entries';
  static const String _migrationFlagKey = 'legacy_migration_done';

  /// Ensure Hive boxes are ready and migrate any legacy data.
  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(_entriesBoxName)) {
      await Hive.openBox<HealthEntry>(_entriesBoxName);
    }
    if (!Hive.isBoxOpen(_settingsBoxName)) {
      await Hive.openBox<dynamic>(_settingsBoxName);
    }

    await _migrateFromSharedPreferences();
  }

  /// Retrieve all entries sorted by most recent first.
  Future<List<HealthEntry>> getAllEntries() async {
    final box = await _ensureEntriesBox();
    final entries = box.values.toList();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  /// Retrieve entries logged today.
  Future<List<HealthEntry>> getTodayEntries() async {
    final allEntries = await getAllEntries();
    return allEntries.where((entry) => entry.isToday).toList();
  }

  /// Retrieve entries that have not been synced to Firebase yet.
  Future<List<HealthEntry>> getUnsyncedEntries() async {
    final box = await _ensureEntriesBox();
    return box.values.where((entry) => !entry.isSynced).toList();
  }

  /// Persist or update an entry locally.
  Future<void> saveEntry(HealthEntry entry, {bool markSynced = false}) async {
    final box = await _ensureEntriesBox();
    final entryToSave = markSynced
        ? entry
        : entry.copyWith(isSynced: false, lastSyncedAt: null);
    await box.put(entry.id, entryToSave);
  }

  /// Delete an entry from local storage.
  Future<void> deleteEntry(String id) async {
    final box = await _ensureEntriesBox();
    await box.delete(id);
  }

  /// Replace all saved entries, typically after a restore.
  Future<void> replaceAllEntries(List<HealthEntry> entries,
      {bool markSynced = false, DateTime? syncTime}) async {
    final box = await _ensureEntriesBox();
    await box.clear();
    final timestamp = syncTime ?? DateTime.now();
    for (final entry in entries) {
      final entryToSave = markSynced
          ? entry.copyWith(isSynced: true, lastSyncedAt: timestamp)
          : entry;
      await box.put(entryToSave.id, entryToSave);
    }
  }

  /// Mark specific entries as synced at the provided time.
  Future<void> markEntriesSynced(Iterable<String> ids, DateTime syncedAt) async {
    final box = await _ensureEntriesBox();
    for (final id in ids) {
      final entry = box.get(id);
      if (entry != null) {
        final updated = entry.copyWith(isSynced: true, lastSyncedAt: syncedAt);
        await box.put(id, updated);
      }
    }
  }

  /// Count entries waiting to sync.
  Future<int> pendingSyncCount() async {
    final box = await _ensureEntriesBox();
    return box.values.where((entry) => !entry.isSynced).length;
  }

  Future<Box<HealthEntry>> _ensureEntriesBox() async {
    if (!Hive.isBoxOpen(_entriesBoxName)) {
      await Hive.openBox<HealthEntry>(_entriesBoxName);
    }
    return Hive.box<HealthEntry>(_entriesBoxName);
  }

  static Future<void> _migrateFromSharedPreferences() async {
    final settingsBox = Hive.box<dynamic>(_settingsBoxName);
    final migrationDone = settingsBox.get(_migrationFlagKey) as bool? ?? false;
    if (migrationDone) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyJson = prefs.getString(_legacyEntriesKey);
    if (legacyJson != null) {
      try {
        final List<dynamic> decoded = json.decode(legacyJson) as List<dynamic>;
        final entries = decoded
            .map((entry) =>
                HealthEntry.fromJson(entry as Map<String, dynamic>).copyWith(
                      isSynced: false,
                      lastSyncedAt: null,
                    ))
            .toList();

        final entriesBox = Hive.box<HealthEntry>(_entriesBoxName);
        for (final entry in entries) {
          await entriesBox.put(entry.id, entry);
        }
      } catch (_) {
        // Ignore migration errors and fall back to fresh storage.
      }

      await prefs.remove(_legacyEntriesKey);
    }

    await settingsBox.put(_migrationFlagKey, true);
  }
}
