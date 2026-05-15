import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StepPanel extends StatelessWidget {
  final String title;
  final String content;
  final int stepNumber;
  final bool isActive;

  const StepPanel({
    super.key,
    required this.title,
    required this.content,
    required this.stepNumber,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? (isActive ? AppColors.darkCard : AppColors.darkSurface)
            : (isActive ? Colors.white : AppColors.grey100),
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                width: 1,
              )
            : Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: isActive
                  ? AppColors.primaryGradient
                  : null,
              color: isActive ? null : AppColors.grey300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.grey600,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1C20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? AppColors.grey300 : AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
