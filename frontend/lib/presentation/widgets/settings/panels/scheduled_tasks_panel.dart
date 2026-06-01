import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class ScheduledTasksPanel extends ConsumerStatefulWidget {
  const ScheduledTasksPanel({super.key});

  @override
  ConsumerState<ScheduledTasksPanel> createState() => _ScheduledTasksPanelState();
}

class _ScheduledTasksPanelState extends ConsumerState<ScheduledTasksPanel> {
  int _activeTab = 0; // 0 = Scheduled, 1 = Completed

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E4DE);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
          child: Row(
            children: [
              _tabButton('Scheduled', 0, textPrimary, textMuted, borderColor, isDark),
              const SizedBox(width: 4),
              _tabButton('Completed', 1, textPrimary, textMuted, borderColor, isDark),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Create a scheduled task from any chat')),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text('New schedule', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500)),
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        // Table header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    _activeTab == 0 ? 'Title' : 'Name',
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _activeTab == 0 ? 'Schedule at' : 'Time',
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted),
                  ),
                ),
                if (_activeTab == 0) ...[
                  SizedBox(
                    width: 60,
                    child: Text('Status', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted)),
                  ),
                  const SizedBox(width: 32),
                ],
              ],
            ),
          ),
        ),
        // Empty state
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_outlined, size: 40, color: textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  _activeTab == 0 ? 'No scheduled tasks yet' : 'No completed tasks yet',
                  style: GoogleFonts.dmSans(fontSize: 14, color: textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  _activeTab == 0 ? 'Create a schedule to automate your tasks' : 'Completed tasks will appear here',
                  style: GoogleFonts.dmSans(fontSize: 12, color: textMuted.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabButton(String label, int index, Color textPrimary, Color textMuted, Color borderColor, bool isDark) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? const Color(0xFF1A1A1A) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: borderColor, width: 1) : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? textPrimary : textMuted,
          ),
        ),
      ),
    );
  }
}
