import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TimelineBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final ValueChanged<int> onStepTap;
  final List<String> stepTitles;

  const TimelineBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onStepTap,
    required this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: currentStep > 0 ? () => onStepTap(currentStep - 1) : null,
            child: Icon(
              Icons.chevron_left_rounded,
              color: currentStep > 0
                  ? AppColors.primaryBlue
                  : AppColors.grey400.withValues(alpha: 0.3),
              size: 24,
            ),
          ),
          const SizedBox(width: 4),

          // Progress dots + title
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalSteps, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: i == currentStep ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == currentStep
                            ? AppColors.primaryBlue
                            : (i < currentStep
                                ? AppColors.success
                                : AppColors.grey400.withValues(alpha: 0.25)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  currentStep < stepTitles.length
                      ? stepTitles[currentStep]
                      : '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.grey300 : AppColors.grey600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),
          // Next button
          GestureDetector(
            onTap: currentStep < totalSteps - 1
                ? () => onStepTap(currentStep + 1)
                : null,
            child: Icon(
              Icons.chevron_right_rounded,
              color: currentStep < totalSteps - 1
                  ? AppColors.primaryBlue
                  : AppColors.grey400.withValues(alpha: 0.3),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
