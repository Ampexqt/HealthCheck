import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_entry.dart';

/// Service for backing up and restoring health data to/from Firebase
class BackupService {
  static const String _backupCollection = 'health_backups';
  static const String _emailKey = 'backup_email';

  /// Get Firestore instance, returns null if Firebase is not initialized
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  /// Check if Firebase is available
  bool get _isFirebaseAvailable {
    try {
      Firebase.app();
      return _firestore != null;
    } catch (e) {
      return false;
    }
  }

  /// Get or persist the email used for backups
  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// Backup all health entries to Firebase using the provided email as key.
  Future<bool> backupToFirebase(List<HealthEntry> entries, String email) async {
    if (!_isFirebaseAvailable) {
      print('Firebase is not initialized or not available');
      return false;
    }

    try {
      final firestore = _firestore;
      if (firestore == null) {
        return false;
      }

      final backupData = {
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
        'entries': entries.map((entry) => entry.toJson()).toList(),
        'entryCount': entries.length,
      };

      await firestore
          .collection(_backupCollection)
          .doc(email)
          .set(backupData, SetOptions(merge: true));

      // Also save backup timestamp locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emailKey, email);
      await prefs.setString(
        'last_backup_timestamp',
        DateTime.now().toIso8601String(),
      );

      return true;
    } catch (e) {
      print('Error backing up to Firebase: $e');
      return false;
    }
  }

  /// Restore health entries from Firebase for the given email.
  Future<List<HealthEntry>> restoreFromFirebase(String email) async {
    if (!_isFirebaseAvailable) {
      print('Firebase is not initialized or not available');
      return [];
    }

    try {
      final firestore = _firestore;
      if (firestore == null) {
        return [];
      }

      final docSnapshot = await firestore
          .collection(_backupCollection)
          .doc(email)
          .get();

      if (!docSnapshot.exists) {
        return [];
      }

      final data = docSnapshot.data();
      if (data == null || data['entries'] == null) {
        return [];
      }

      final List<dynamic> entriesJson = data['entries'] as List<dynamic>;
      final entries = entriesJson
          .map((entry) => HealthEntry.fromJson(entry as Map<String, dynamic>))
          .toList();

      return entries;
    } catch (e) {
      print('Error restoring from Firebase: $e');
      return [];
    }
  }

  /// Get last backup timestamp
  Future<DateTime?> getLastBackupTime() async {
    if (!_isFirebaseAvailable) {
      return null;
    }

    try {
      final firestore = _firestore;
      if (firestore == null) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_emailKey);
      if (email == null) {
        return null;
      }
      final docSnapshot = await firestore
          .collection(_backupCollection)
          .doc(email)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data();
      if (data == null || data['timestamp'] == null) {
        return null;
      }

      final timestamp = data['timestamp'] as Timestamp;
      return timestamp.toDate();
    } catch (e) {
      print('Error getting last backup time: $e');
      return null;
    }
  }

  /// Export data as JSON string (for manual backup)
  String exportToJson(List<HealthEntry> entries) {
    final exportData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'entryCount': entries.length,
    };
    return json.encode(exportData);
  }

  /// Import data from JSON string (for manual restore)
  List<HealthEntry> importFromJson(String jsonString) {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final List<dynamic> entriesJson = data['entries'] as List<dynamic>;
      return entriesJson
          .map((entry) => HealthEntry.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error importing from JSON: $e');
      return [];
    }
  }
}
