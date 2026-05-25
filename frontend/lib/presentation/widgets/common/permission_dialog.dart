import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class PermissionDialog {
  PermissionDialog._();

  /// Shows a permission dialog and returns true if user taps Allow, false if Deny
  static Future<bool> show({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String reason,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkBgSecondary : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.persian,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                reason,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorderDefault
                                : AppColors.borderDefault,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                        ),
                        child: Text(
                          'Deny',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.persian,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                        ),
                        child: Text(
                          'Allow',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  /// Show microphone permission dialog
  static Future<bool> microphone(BuildContext context) {
    return show(
      context: context,
      icon: Icons.mic_outlined,
      title: 'Microphone Access',
      reason: 'Mio needs microphone access to transcribe your voice into text.',
    );
  }

  /// Show camera permission dialog
  static Future<bool> camera(BuildContext context) {
    return show(
      context: context,
      icon: Icons.camera_alt_outlined,
      title: 'Camera Access',
      reason: 'Mio needs camera access to capture photos for your chat.',
    );
  }

  /// Show notifications permission dialog
  static Future<bool> notifications(BuildContext context) {
    return show(
      context: context,
      icon: Icons.notifications_outlined,
      title: 'Notifications',
      reason: 'Allow notifications to get updates on your AI responses.',
    );
  }

  /// Show photos/gallery permission dialog
  static Future<bool> photos(BuildContext context) {
    return show(
      context: context,
      icon: Icons.photo_library_outlined,
      title: 'Photo Library',
      reason: 'Mio needs access to your photos to attach images to chat.',
    );
  }
}
