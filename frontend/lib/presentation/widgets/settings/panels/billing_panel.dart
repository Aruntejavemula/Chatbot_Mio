import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/router.dart';

class BillingPanel extends ConsumerWidget {
  const BillingPanel({super.key});

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
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.subscription);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: Text('Manage', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.subscription);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: Text('Upgrade plan', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.black : Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 16),
              // Credits
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: textMuted),
                  const SizedBox(width: 10),
                  Text('Credits', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline, size: 14, color: textMuted),
                  const Spacer(),
                  Text('0', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                ],
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
              Row(
                children: [
                  Icon(Icons.refresh, size: 18, color: textMuted),
                  const SizedBox(width: 10),
                  Text('Daily refresh credits', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline, size: 14, color: textMuted),
                  const Spacer(),
                  Text('0', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text('Refresh to 0 at 00:00 every day', style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // Recent activity
        Row(
          children: [
            Text('Recent activity', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
            const Spacer(),
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No invoices to display yet')),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View all invoices', style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: textMuted),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Invoice table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('Date', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted))),
              Expanded(flex: 2, child: Text('Amount', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted))),
              const Expanded(flex: 1, child: SizedBox()),
            ],
          ),
        ),
        // Empty state
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text('No billing history yet', style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
          ),
        ),
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
}
