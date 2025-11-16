import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'health_entry.g.dart';

/// Model representing a health entry with vitals
@HiveType(typeId: 0)
class HealthEntry extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final int? heartRate; // bpm
  @HiveField(2)
  final int? systolicBP; // mmHg
  @HiveField(3)
  final int? diastolicBP; // mmHg
  @HiveField(4)
  final String? symptoms;
  @HiveField(5)
  final DateTime timestamp;
  @HiveField(6)
  final bool isSynced;
  @HiveField(7)
  final DateTime? lastSyncedAt;

  HealthEntry({
    required this.id,
    this.heartRate,
    this.systolicBP,
    this.diastolicBP,
    this.symptoms,
    required this.timestamp,
    this.isSynced = false,
    this.lastSyncedAt,
  });

  /// Create a copy with optional modifications
  HealthEntry copyWith({
    String? id,
    int? heartRate,
    int? systolicBP,
    int? diastolicBP,
    String? symptoms,
    DateTime? timestamp,
    bool? isSynced,
    DateTime? lastSyncedAt,
  }) {
    return HealthEntry(
      id: id ?? this.id,
      heartRate: heartRate ?? this.heartRate,
      systolicBP: systolicBP ?? this.systolicBP,
      diastolicBP: diastolicBP ?? this.diastolicBP,
      symptoms: symptoms ?? this.symptoms,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'heartRate': heartRate,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'symptoms': symptoms,
      'timestamp': timestamp.toIso8601String(),
      'isSynced': isSynced,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory HealthEntry.fromJson(Map<String, dynamic> json) {
    return HealthEntry(
      id: json['id'] as String,
      heartRate: json['heartRate'] as int?,
      systolicBP: json['systolicBP'] as int?,
      diastolicBP: json['diastolicBP'] as int?,
      symptoms: json['symptoms'] as String?,
      timestamp: _parseDate(json['timestamp']) ?? DateTime.now(),
      isSynced: json['isSynced'] as bool? ?? false,
      lastSyncedAt: _parseDate(json['lastSyncedAt']),
    );
  }

  /// Format timestamp for display
  String get formattedTime {
    return DateFormat('h:mm a').format(timestamp);
  }

  /// Format full date and time
  String get formattedDateTime {
    return DateFormat('MMM d, y, h:mm a').format(timestamp);
  }

  /// Format date for grouping
  String get formattedDate {
    return DateFormat('MMM d, y').format(timestamp);
  }

  /// Check if entry is from today
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
