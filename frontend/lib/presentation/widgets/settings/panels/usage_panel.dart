import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class UsagePanel extends ConsumerWidget {
  const UsagePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E4DE);
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        // Plan card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mio Free', style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary)),
                        const SizedBox(height: 2),
                        Text('Renewal date  —', style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: Text('Manage', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: Text('Add credits', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.black : Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 16),
              // Credits row
              _creditRow(
                icon: Icons.auto_awesome,
                label: 'Credits',
                value: '0',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Column(
                  children: [
                    _subRow('Free credits', '0', textMuted),
                    _subRow('Monthly credits', '0 / 0', textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 16),
              _creditRow(
                icon: Icons.refresh,
                label: 'Daily refresh credits',
                value: '0',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text('Refresh to 0 at 00:00 every day', style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Usage history
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.language, size: 18, color: textMuted),
              const SizedBox(width: 10),
              Expanded(child: Text('Website usage & billing', style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary))),
              Icon(Icons.chevron_right, size: 18, color: textMuted),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Recent usage table
        _buildUsageTable(textPrimary, textMuted, borderColor),
      ],
    );
  }

  Widget _creditRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
              const SizedBox(width: 4),
              Icon(Icons.info_outline, size: 14, color: textMuted),
            ],
          ),
        ),
        Text(value, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
      ],
    );
  }

  Widget _subRow(String label, String value, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: textMuted))),
          Text(value, style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)),
        ],
      ),
    );
  }

  Widget _buildUsageTable(Color textPrimary, Color textMuted, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('Details', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted))),
              Expanded(flex: 2, child: Text('Date', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted))),
              Expanded(flex: 1, child: Text('Credits change', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted), textAlign: TextAlign.right)),
            ],
          ),
        ),
        // Empty state
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text('No usage history yet', style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
          ),
        ),
      ],
    );
  }
}
