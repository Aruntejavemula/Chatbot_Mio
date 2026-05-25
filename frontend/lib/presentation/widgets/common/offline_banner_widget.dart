import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/connectivity_service.dart';

/// An animated banner that slides in when the device goes offline.
///
/// Listens to [ConnectivityService] and shows/hides with an animation.
class OfflineBannerWidget extends StatelessWidget {
  const OfflineBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, isOnline, child) {
        return _OfflineBanner(isOffline: !isOnline);
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final bool isOffline;

  const _OfflineBanner({required this.isOffline});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isOffline ? 40 : 0,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkWarning.withValues(alpha: 0.15)
            : AppColors.warning.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 16,
              color: isDark ? AppColors.darkWarning : AppColors.warning,
            ),
            const SizedBox(width: 8),
            Text(
              'You are offline. Messages will be sent when reconnected.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkWarning : AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
