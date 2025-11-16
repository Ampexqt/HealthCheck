import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Custom input field for vitals with icon
class VitalsInputField extends StatelessWidget {
  final String label;
  final String? placeholder;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Function(String)? onChanged;

  const VitalsInputField({
    super.key,
    required this.label,
    this.placeholder,
    required this.icon,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryText),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.primaryText),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: AppColors.placeholder),
            filled: true,
            fillColor: AppColors.cardSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.divider, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.divider, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primaryAction,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
