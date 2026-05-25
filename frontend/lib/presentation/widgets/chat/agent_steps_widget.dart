import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/agent_step_model.dart';

class AgentStepsWidget extends StatelessWidget {
  final List<AgentStepModel> steps;
  final bool isRunning;

  const AgentStepsWidget({
    super.key,
    required this.steps,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (steps.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border.all(color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRunning ? Icons.sync : Icons.check_circle_outline,
                size: 14,
                color: isRunning ? AppColors.persian : AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                isRunning ? 'Working on it...' : 'Done in ${steps.length} steps',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isRunning ? AppColors.persian : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...steps.map((step) => _buildStep(step, isDark)),
        ],
      ),
    );
  }

  Widget _buildStep(AgentStepModel step, bool isDark) {
    final isExecuting = step.status == 'executing';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.stepNumber}',
                style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.tool.replaceAll('_', ' '),
                  style: GoogleFonts.dmSans(fontSize: 13, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
                if (step.preview != null)
                  Text(
                    step.preview!,
                    style: GoogleFonts.dmSans(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (isExecuting)
            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.persian))
          else
            const Icon(Icons.check_outlined, size: 14, color: AppColors.success),
        ],
      ),
    );
  }
}
