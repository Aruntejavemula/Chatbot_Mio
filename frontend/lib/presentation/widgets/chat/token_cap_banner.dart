import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/funny_warnings.dart';

class TokenCapBanner extends StatelessWidget {
  final String capType;
  final int used;
  final int limit;
  final String resetsIn;
  final VoidCallback onAddKey;

  const TokenCapBanner({
    super.key,
    required this.capType,
    required this.used,
    required this.limit,
    required this.resetsIn,
    required this.onAddKey,
  });

  double get percentage => limit > 0 ? used / limit.toDouble() : 0.0;

  String get displayName {
    switch (capType) {
      case 'five_hour':
        return AppConstants.fiveHourCapDisplay;
      case 'daily':
        return AppConstants.dailyCapDisplay;
      case 'weekly':
        return AppConstants.weeklyCapDisplay;
      case 'monthly':
        return AppConstants.monthlyCapDisplay;
      default:
        return capType;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (percentage < 0.7) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (percentage >= 1.0) {
      return _buildBlockedState(isDark);
    }

    return _buildWarningState(isDark);
  }

  Widget _buildWarningState(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.1),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            size: 14,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${FunnyWarnings.tokenWarning} ${(percentage * 100).toInt()}% used. Resets $resetsIn',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: onAddKey,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Add key',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.persian,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedState(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        border: Border.all(color: const Color(0xFFEF4444), width: 1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Icon(
            Icons.block,
            size: 14,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FunnyWarnings.tokenBlocked,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  'Add your own API key to continue',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onAddKey,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
            ),
            child: Text(
              'Add key',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
