import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';


class IntegrationsPanel extends ConsumerWidget {
  const IntegrationsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E4DE);
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    final integrations = [
      {
        'title': 'Build with Mio API',
        'subtitle': 'Use Mio API to build custom integrations',
        'icon': Icons.settings_outlined,
        'color': const Color(0xFF6366F1),
      },
      {
        'title': 'Use Mio in Zapier',
        'subtitle': 'Connect Mio to thousands of apps with Zapier',
        'icon': Icons.bolt_outlined,
        'color': const Color(0xFFFF4A00),
      },
      {
        'title': 'Use Mio in Slack',
        'subtitle': 'Use @Mio in Slack to assign tasks to Mio',
        'icon': Icons.tag,
        'color': const Color(0xFF4A154B),
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: integrations.map((integration) {
            return SizedBox(
              width: 240,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (integration['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(integration['icon'] as IconData, size: 20, color: integration['color'] as Color),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      integration['title'] as String,
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      integration['subtitle'] as String,
                      style: GoogleFonts.dmSans(fontSize: 12, color: textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Go to configure', style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16, color: textMuted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
