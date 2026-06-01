import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class DataControlsPanel extends ConsumerWidget {
  const DataControlsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E4DE);

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        _controlRow(context, 'My shared chats', textPrimary, borderColor),
        _controlRow(context, 'My shared files', textPrimary, borderColor),
        _controlRow(context, 'My deployed websites', textPrimary, borderColor),
        _controlRow(context, 'My purchased domains', textPrimary, borderColor),
      ],
    );
  }

  Widget _controlRow(BuildContext context, String label, Color textPrimary, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary)),
          ),
          OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label — nothing to manage yet')),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text('Manage', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
          ),
        ],
      ),
    );
  }
}
