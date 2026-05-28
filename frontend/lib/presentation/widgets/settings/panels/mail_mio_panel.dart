import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class MailMioPanel extends ConsumerStatefulWidget {
  const MailMioPanel({super.key});

  @override
  ConsumerState<MailMioPanel> createState() => _MailMioPanelState();
}

class _MailMioPanelState extends ConsumerState<MailMioPanel> {
  int _activeTab = 0; // 0 = Settings, 1 = Inbox

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E4DE);
    final cardBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F6F2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.email_outlined, size: 18, color: textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Create tasks by email. CC others to collaborate.',
                    style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Learn more', style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
                      const SizedBox(width: 2),
                      Icon(Icons.open_in_new, size: 12, color: textMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              _tabButton('Settings', 0, textPrimary, textMuted, borderColor),
              const SizedBox(width: 16),
              _tabButton('Inbox', 1, textPrimary, textMuted, borderColor),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Divider(color: borderColor, height: 1),
        ),
        // Content
        Expanded(
          child: _activeTab == 0
              ? _buildSettingsTab(textPrimary, textMuted, borderColor, cardBg)
              : _buildInboxTab(textPrimary, textMuted, borderColor),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(Color textPrimary, Color textMuted, Color borderColor, Color cardBg) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      children: [
        // Mio's email
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Mio's email", style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(height: 2),
                  Text('Send emails to this address to create tasks.', style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('you@mio.bot', style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
                const SizedBox(width: 6),
                Icon(Icons.edit_outlined, size: 16, color: textMuted),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: borderColor, height: 1),
        const SizedBox(height: 20),
        // Workflow email
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Workflow email', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                      const SizedBox(width: 4),
                      Icon(Icons.info_outline, size: 14, color: textMuted),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Customize email addresses and instructions to process different tasks.', style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: Text('Add workflow email', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: borderColor, height: 1),
        const SizedBox(height: 20),
        // Approved senders
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Approved senders', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(height: 2),
                  Text('Only emails from these addresses can create tasks.', style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: Text('Add approved sender', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Empty approved senders
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('No approved senders yet', style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
          ),
        ),
      ],
    );
  }

  Widget _buildInboxTab(Color textPrimary, Color textMuted, Color borderColor) {
    return Column(
      children: [
        // Table header
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Sender', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted))),
                Expanded(flex: 3, child: Text('Content', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted))),
                SizedBox(
                  width: 100,
                  child: Row(
                    children: [
                      Text('Date', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted)),
                      const Spacer(),
                      Icon(Icons.refresh, size: 14, color: textMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text('No emails received yet', style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
          ),
        ),
      ],
    );
  }

  Widget _tabButton(String label, int index, Color textPrimary, Color textMuted, Color borderColor) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? textPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? textPrimary : textMuted,
          ),
        ),
      ),
    );
  }
}
