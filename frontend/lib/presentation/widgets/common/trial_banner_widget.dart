import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/router.dart';

enum _TrialState { loading, active, expired, hidden }

class TrialBannerWidget extends ConsumerStatefulWidget {
  const TrialBannerWidget({super.key});

  @override
  ConsumerState<TrialBannerWidget> createState() => _TrialBannerWidgetState();
}

class _TrialBannerWidgetState extends ConsumerState<TrialBannerWidget> {
  static const int _trialDurationDays = 14;
  static const String _trialStartDateKey = 'trial_start_date';

  _TrialState _state = _TrialState.loading;
  int _daysRemaining = 0;
  int _daysElapsed = 0;

  @override
  void initState() {
    super.initState();
    _loadTrialData();
  }

  Future<void> _loadTrialData() async {
    try {
      const storage = FlutterSecureStorage();
      final trialStartString = await storage.read(key: _trialStartDateKey);

      if (!mounted) return;

      if (trialStartString == null) {
        setState(() => _state = _TrialState.hidden);
        return;
      }

      final trialStart = DateTime.tryParse(trialStartString);
      if (trialStart == null) {
        setState(() => _state = _TrialState.hidden);
        return;
      }

      final elapsed = DateTime.now().difference(trialStart).inDays;
      final remaining = _trialDurationDays - elapsed;

      setState(() {
        _daysElapsed = elapsed.clamp(0, _trialDurationDays);
        _daysRemaining = remaining;
        _state = remaining > 0 ? _TrialState.active : _TrialState.expired;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _state = _TrialState.hidden);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (_state) {
      case _TrialState.loading:
        return const SizedBox.shrink();
      case _TrialState.hidden:
        return const SizedBox.shrink();
      case _TrialState.active:
        return _buildActiveBanner(isDark);
      case _TrialState.expired:
        return _buildExpiredBanner(isDark);
    }
  }

  Widget _buildActiveBanner(bool isDark) {
    final progress = _daysElapsed / _trialDurationDays;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingCard,
        vertical: 8,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingCard),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.persian.withValues(alpha: 0.2),
              isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
            ],
          ),
          border: Border.all(color: AppColors.persian),
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pro Trial Active',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 20,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_daysRemaining',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 36,
                    color: AppColors.persian,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _daysRemaining == 1 ? 'day remaining' : 'days remaining',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '\$9.99/month after trial',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark
                    ? AppColors.darkBgTertiary
                    : AppColors.bgTertiary,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.persian),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.subscription),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.persian,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Upgrade',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredBanner(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingCard,
        vertical: 8,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingCard),
        decoration: BoxDecoration(
          color: const Color(0x1AEF4444),
          border: Border.all(color: AppColors.error),
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your trial ended',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 20,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upgrade to continue using Pro features.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.subscription),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.persian,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Upgrade now',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
