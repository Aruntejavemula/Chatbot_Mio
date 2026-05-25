import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/providers/background_agent_provider.dart';

class BackgroundAgentStatusWidget extends ConsumerWidget {
  const BackgroundAgentStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentState = ref.watch(backgroundAgentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (agentState.isIdle) return const SizedBox.shrink();

    final Color accentColor;
    final IconData icon;
    final String label;

    if (agentState.isRunning) {
      accentColor = AppColors.persian;
      icon = Icons.sync;
      label = 'Agent running...';
    } else if (agentState.isDone) {
      accentColor = AppColors.success;
      icon = Icons.check_circle_outline;
      label = 'Agent completed';
    } else {
      accentColor = AppColors.error;
      icon = Icons.error_outline;
      label = 'Agent failed';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingScreen, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                if (agentState.prompt != null)
                  Text(
                    agentState.prompt!,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (!agentState.isRunning)
            GestureDetector(
              onTap: () => ref.read(backgroundAgentProvider.notifier).dismiss(),
              child: Icon(Icons.close,
                  size: 16,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}
