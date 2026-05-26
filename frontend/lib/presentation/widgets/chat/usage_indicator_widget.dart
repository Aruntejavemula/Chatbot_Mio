import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/providers/usage_provider.dart';

class UsageIndicatorWidget extends ConsumerWidget {
  const UsageIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageState = ref.watch(usageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (usageState.error != null) {
      return const SizedBox.shrink();
    }

    if (usageState.isLoading) {
      return const SizedBox.shrink();
    }

    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final bgTertiary = isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary;

    final double ratio = usageState.dailyLimit > 0
        ? (usageState.dailyUsed / usageState.dailyLimit).clamp(0.0, 1.0)
        : 0.0;
    final int percentage = (ratio * 100).round();
    final Color progressColor = _getProgressColor(ratio);
    final String milestone = _getMilestoneMessage(ratio);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.bolt,
              size: 16,
              color: AppColors.persian,
            ),
            const SizedBox(width: 6),
            Text(
              'Daily tokens',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: bgTertiary,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          milestone,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double ratio) {
    if (ratio > 0.9) {
      return AppColors.error;
    } else if (ratio >= 0.7) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  String _getMilestoneMessage(double ratio) {
    if (ratio >= 0.75) {
      return 'Almost at limit';
    } else if (ratio >= 0.50) {
      return 'Heavy usage';
    } else if (ratio >= 0.25) {
      return 'Making progress';
    }
    return 'Getting started';
  }
}
