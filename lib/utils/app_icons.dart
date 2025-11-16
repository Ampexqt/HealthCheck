import 'package:flutter/material.dart';

/// Custom icon constants for HealthCheck app
class AppIcons {
  // Using Material Icons (outline style when available)
  static const IconData heart = Icons.favorite_border;
  static const IconData heartFilled = Icons.favorite;
  static const IconData bloodPressure = Icons.monitor_heart_outlined;
  static const IconData symptoms = Icons.description_outlined;
  static const IconData clock = Icons.access_time_outlined;
  static const IconData profile = Icons.person_outline;
  static const IconData add = Icons.add;
  static const IconData close = Icons.close;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline;
  static const IconData home = Icons.home_outlined;
  static const IconData history = Icons.history_outlined;
  static const IconData settings = Icons.settings_outlined;

  // ECG wave-like icon (using trending up as approximation)
  static const IconData ecgWave = Icons.show_chart;
}
