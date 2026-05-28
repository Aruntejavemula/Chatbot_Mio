import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../widgets/common/shaking_hands.dart';

class SubscriptionWelcomeScreen extends ConsumerStatefulWidget {
  final String plan;

  const SubscriptionWelcomeScreen({super.key, required this.plan});

  @override
  ConsumerState<SubscriptionWelcomeScreen> createState() => _SubscriptionWelcomeScreenState();
}

class _SubscriptionWelcomeScreenState extends ConsumerState<SubscriptionWelcomeScreen> {
  int _page = 0; // 0 = Welcome, 1 = Features showcase

  String get _planName {
    switch (widget.plan) {
      case 'pro':
        return 'Pro';
      case 'max':
        return 'Max';
      default:
        return 'Pro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      body: _page == 0 ? _buildWelcomePage(isDark) : _buildShowcasePage(isDark),
    );
  }

  Widget _buildWelcomePage(bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return SafeArea(
      child: Column(
        children: [
          // Top bar with "Back to Mio"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/chat'),
                child: Text('Back to Mio', style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary)),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'Your ticket to thinking,\nfaster',
                    style: GoogleFonts.dmSerifDisplay(fontSize: 40, color: textPrimary, height: 1.1),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You just got access to Mio $_planName',
                    style: GoogleFonts.dmSans(fontSize: 16, color: textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Ticket-style card
                  _buildTicketCard(isDark, textPrimary, textMuted),
                  const SizedBox(height: 36),
                  // CTA buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.go('/chat'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        ),
                        child: Text('Not now', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary)),
                      ),
                      const SizedBox(width: 14),
                      FilledButton(
                        onPressed: () => setState(() => _page = 1),
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        ),
                        child: Text(
                          'Explore features',
                          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.black : Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Scroll down indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: GestureDetector(
              onTap: () => setState(() => _page = 1),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.persian,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.persian.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(bool isDark, Color textPrimary, Color textMuted) {
    final borderColor = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final cardBg = isDark ? AppColors.darkBgSecondary : Colors.white;

    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ADMIT ONE', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 2)),
              Text('VALID FOR: MIO $_planName'.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 24),
          // Center content
          const ShakingHands(size: 48, animate: true),
          const SizedBox(height: 12),
          Text(
            'Mio $_planName',
            style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Immediate access',
            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.persian),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildShowcasePage(bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final borderColor = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final cardBg = isDark ? AppColors.darkBgSecondary : Colors.white;

    final showcaseItems = [
      {
        'title': 'Research & Deep Analysis',
        'tag': 'Research',
        'tagColor': const Color(0xFF6366F1),
        'description': 'Deep research and analysis across complex topics with citations and sources.',
      },
      {
        'title': 'Code Generation',
        'tag': 'Engineering',
        'tagColor': const Color(0xFF10B981),
        'description': 'Generate, review, and debug code across multiple languages and frameworks.',
      },
      {
        'title': 'Content Creation',
        'tag': 'Writing',
        'tagColor': const Color(0xFFF59E0B),
        'description': 'Write, edit, and refine content with professional quality and consistency.',
      },
      {
        'title': 'Data Analysis',
        'tag': 'Analytics',
        'tagColor': const Color(0xFFEF4444),
        'description': 'Analyze datasets, create visualizations, and extract actionable insights.',
      },
      {
        'title': 'Task Automation',
        'tag': 'Productivity',
        'tagColor': const Color(0xFF8B5CF6),
        'description': 'Automate repetitive tasks with scheduled workflows and connectors.',
      },
      {
        'title': 'Creative Projects',
        'tag': 'Design',
        'tagColor': const Color(0xFFEC4899),
        'description': 'Brainstorm, prototype, and iterate on creative ideas and designs.',
      },
    ];

    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/chat'),
                child: Text('Back to Mio', style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'See what you can build',
            style: GoogleFonts.dmSerifDisplay(fontSize: 32, color: textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      mainAxisExtent: 140,
                    ),
                    itemCount: showcaseItems.length,
                    itemBuilder: (context, index) {
                      final item = showcaseItems[index];
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['title'] as String,
                                    style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (item['tagColor'] as Color).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item['tag'] as String,
                                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: item['tagColor'] as Color),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['description'] as String,
                              style: GoogleFonts.dmSans(fontSize: 13, color: textMuted),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          // Bottom CTA
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go('/chat'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.persian,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Start using Mio $_planName', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
