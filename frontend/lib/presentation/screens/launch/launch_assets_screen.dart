import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class LaunchAssetsScreen extends StatelessWidget {
  const LaunchAssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Launch Assets',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingScreen),
        children: [
          _AssetSection(
            title: 'ProductHunt Tagline',
            content:
                'Your AI companion that adapts to you - private, fast, and beautifully simple.',
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _AssetSection(
            title: 'ProductHunt Description',
            content:
                'Mio is a privacy-first AI chatbot that brings together the best language models in one beautiful interface. Switch between providers, keep your data secure, and enjoy a thoughtful experience designed for real conversations.',
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _AssetSection(
            title: 'Twitter/X Post',
            content:
                'Introducing Mio - your new AI companion.\n\n'
                'Private. Fast. Beautiful.\n\n'
                'One app, multiple AI models, zero data tracking.\n\n'
                'Try it free today.',
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _AssetSection(
            title: 'Reddit Post',
            content:
                'Hey everyone! We just launched Mio, a privacy-focused AI chatbot that lets you use multiple language models through one clean interface.\n\n'
                'Key features:\n'
                '- Switch between AI providers (OpenAI, Anthropic, Google, etc.)\n'
                '- End-to-end privacy - we never store or train on your data\n'
                '- Beautiful, minimal UI that stays out of your way\n'
                '- Works offline with on-device models\n\n'
                'Would love to hear your feedback!',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _AssetSection extends StatelessWidget {
  final String title;
  final String content;
  final bool isDark;

  const _AssetSection({
    required this.title,
    required this.content,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingCard),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color:
              isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.copy,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title copied to clipboard'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Copy',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppSizes.minTouchTarget,
                  minHeight: AppSizes.minTouchTarget,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            content,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              height: 1.5,
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
