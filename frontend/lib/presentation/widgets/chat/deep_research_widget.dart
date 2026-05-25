import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class DeepResearchWidget extends StatelessWidget {
  final String query;
  final String status;
  final String? taskId;

  const DeepResearchWidget({
    super.key,
    required this.query,
    required this.status,
    this.taskId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (status == 'idle') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border.all(color: AppColors.persian.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.biotech_outlined, size: 20, color: AppColors.persian),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deep Research', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.persian)),
                    Text(
                      status == 'processing' ? 'Searching and synthesizing...' : 'Research complete',
                      style: GoogleFonts.dmSans(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (status == 'processing')
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.persian)),
              if (status == 'done')
                const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
            ],
          ),
          if (status == 'processing') ...[
            const SizedBox(height: 12),
            _buildProgressSteps(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressSteps(bool isDark) {
    const steps = ['Searching the web', 'Reading sources', 'Cross-referencing', 'Synthesizing'];
    return Column(
      children: steps.map((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 6, color: AppColors.persian),
              const SizedBox(width: 8),
              Text(step, style: GoogleFonts.dmSans(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
