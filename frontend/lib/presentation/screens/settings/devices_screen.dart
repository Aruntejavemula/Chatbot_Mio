import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/funny_warnings.dart';
import '../../widgets/common/funny_snackbar.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Devices',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Device limit banner
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorderDefault
                      : AppColors.borderDefault,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1 of 1 devices used',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    child: LinearProgressIndicator(
                      value: 1.0,
                      color: AppColors.persian,
                      backgroundColor: isDark
                          ? AppColors.darkBgTertiary
                          : AppColors.bgTertiary,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      FunnySnackbar.show(context, FunnyWarnings.deviceLimit, type: SnackbarType.info);
                    },
                    child: Text(
                      'Free plan: 1 device maximum',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Device list
          Expanded(
            child: ListView(
              children: [
                // Current device
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_android,
                        size: 24,
                        color: AppColors.persian,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Device',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.persian,
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusFull),
                                  ),
                                  child: Text(
                                    'This device',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Active now',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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
