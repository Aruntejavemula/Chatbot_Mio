import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// A visual drop zone overlay for file drag-and-drop.
///
/// This is a placeholder widget since the desktop_drop package is not included.
/// When desktop_drop is added, wrap the chat area with DropTarget and show
/// this overlay when files are dragged over.
class DropZoneWidget extends StatelessWidget {
  final bool isVisible;
  final VoidCallback? onDismiss;

  const DropZoneWidget({
    super.key,
    this.isVisible = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: (isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary)
            .withValues(alpha: 0.9),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.persian,
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.upload_file_rounded,
                  size: 48,
                  color: AppColors.persian,
                ),
                const SizedBox(height: 16),
                Text(
                  'Drop files to attach',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Images, documents, and code files supported',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
