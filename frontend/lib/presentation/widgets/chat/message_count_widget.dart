import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class MessageCountWidget extends StatelessWidget {
  final int count;
  final int limit;

  const MessageCountWidget({
    super.key,
    required this.count,
    required this.limit,
  });

  Color _getProgressColor(bool isDark) {
    final ratio = limit > 0 ? count / limit : 0.0;
    if (ratio <= 0.5) {
      return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
    } else if (ratio <= 0.75) {
      return isDark ? AppColors.darkWarning : AppColors.lightWarning;
    } else {
      return isDark ? AppColors.darkError : AppColors.lightError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = _getProgressColor(isDark);
    final ratio = limit > 0 ? count / limit : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Free plan',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count/$limit messages',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: isDark
                ? AppColors.darkBgTertiary
                : AppColors.bgTertiary,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }
}
