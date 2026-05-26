import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class TaskProgressBarWidget extends StatelessWidget {
  final int currentStep;
  final int totalEstimatedSteps;
  final String? currentAction;

  const TaskProgressBarWidget({
    super.key,
    required this.currentStep,
    required this.totalEstimatedSteps,
    this.currentAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = totalEstimatedSteps > 0
        ? (currentStep / totalEstimatedSteps).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingScreen, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.persian),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentAction ?? 'Processing step $currentStep of $totalEstimatedSteps...',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$currentStep/$totalEstimatedSteps',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor:
                  isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.persian),
            ),
          ),
        ],
      ),
    );
  }
}
