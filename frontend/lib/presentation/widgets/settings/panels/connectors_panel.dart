import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class ConnectorsPanel extends ConsumerWidget {
  const ConnectorsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E4DE);

    final connectors = [
      {
        'name': 'Gmail',
        'description': 'Draft replies, search your inbox, and summarize email threads instantly',
        'icon': Icons.mail_outline,
        'color': const Color(0xFFEA4335),
      },
      {
        'name': 'Google Calendar',
        'description': 'Understand your schedule, manage events, and optimize your time effectively',
        'icon': Icons.calendar_today_outlined,
        'color': const Color(0xFF4285F4),
      },
      {
        'name': 'Google Drive',
        'description': 'Access and organize your files, documents, and spreadsheets',
        'icon': Icons.folder_outlined,
        'color': const Color(0xFF34A853),
      },
      {
        'name': 'Notion',
        'description': 'Read and update your Notion pages, databases, and workspace',
        'icon': Icons.description_outlined,
        'color': const Color(0xFF000000),
      },
    ];

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
            itemCount: connectors.length,
            separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
            itemBuilder: (context, index) {
              final connector = connectors[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: (connector['color'] as Color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(connector['icon'] as IconData, size: 18, color: connector['color'] as Color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(connector['name'] as String, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                              const SizedBox(height: 2),
                              Text(
                                connector['description'] as String,
                                style: GoogleFonts.dmSans(fontSize: 12, color: textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 18, color: textMuted),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Add connectors button
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: Text('Add connectors', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
