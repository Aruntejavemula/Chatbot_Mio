import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
          'Privacy Policy',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _LegalSection(
            title: 'What we collect',
            body:
                'We collect minimal data required to provide the Mio Cloud service. '
                'This includes your email address for authentication, usage metrics '
                'for billing purposes, and conversation metadata for sync functionality. '
                'We do not store the content of your conversations on our servers '
                'beyond what is needed for real-time delivery.',
            isDark: isDark,
          ),
          _LegalSection(
            title: 'Your API keys',
            body:
                'When you provide your own API keys (BYOK mode), they are encrypted '
                'at rest and only decrypted in memory during request processing. '
                'We never log, share, or retain your API keys beyond your active session. '
                'You may revoke or rotate your keys at any time through the settings.',
            isDark: isDark,
          ),
          _LegalSection(
            title: 'Third party services',
            body:
                'Mio connects to third-party AI providers (OpenRouter, DeepSeek, OpenAI, '
                'Anthropic, Google) to process your messages. Each provider has its own '
                'privacy policy governing how they handle data sent to their APIs. '
                'We recommend reviewing their policies. We do not sell or share your '
                'data with advertisers or data brokers.',
            isDark: isDark,
          ),
          _LegalSection(
            title: 'Your rights',
            body:
                'You have the right to access, export, or delete your data at any time. '
                'You can request a full data export from the settings screen. Account '
                'deletion permanently removes all associated data from our systems '
                'within 30 days. We comply with GDPR and applicable data protection '
                'regulations.',
            isDark: isDark,
          ),
          _LegalSection(
            title: 'Contact',
            body:
                'For privacy-related inquiries, please contact us at privacy@miocloud.app. '
                'We will respond to all requests within 30 days.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String title;
  final String body;
  final bool isDark;

  const _LegalSection({
    required this.title,
    required this.body,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 18,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.6,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
