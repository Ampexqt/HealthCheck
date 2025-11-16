import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Widget for displaying empty state message
class EmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;

  const EmptyState({super.key, required this.message, this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 64, color: AppColors.placeholder),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
