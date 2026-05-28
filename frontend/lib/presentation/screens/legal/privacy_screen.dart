import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const String _lastUpdated = 'May 28, 2026';
  static const String _effectiveDate = 'June 1, 2026';

  static const List<_Section> _sections = [
    _Section(
      number: '1',
      title: 'Information We Collect',
      paragraphs: [
        'We collect minimal data required to provide the Mio service. This includes:',
      ],
      bullets: [
        'Account information — email address, display name, and profile preferences you provide during registration.',
        'Usage data — message counts, session duration, and feature usage metrics for billing and service improvement.',
        'Conversation metadata — timestamps, model selections, and conversation titles for sync functionality. We do not store the content of your conversations on our servers beyond what is needed for real-time delivery.',
        'Device information — device type, operating system, and app version for compatibility and troubleshooting.',
        'Payment information — processed securely through Stripe or Razorpay. We do not store your full card details.',
      ],
    ),
    _Section(
      number: '2',
      title: 'Your API Keys',
      paragraphs: [
        'When you provide your own API keys (BYOK mode), they are encrypted at rest using AES-256 and only decrypted in memory during request processing. We never log, share, or retain your API keys beyond your active session.',
        'You may revoke or rotate your keys at any time through the settings panel. We recommend rotating keys periodically as a security best practice.',
      ],
    ),
    _Section(
      number: '3',
      title: 'How We Use Your Information',
      paragraphs: [
        'We use collected information solely to:',
      ],
      bullets: [
        'Provide, maintain, and improve the Mio service.',
        'Process subscriptions and manage billing.',
        'Send important service updates and security notifications.',
        'Analyze aggregate usage patterns to improve performance.',
        'Prevent fraud, abuse, and violations of our terms.',
      ],
    ),
    _Section(
      number: '4',
      title: 'Third-Party Services',
      paragraphs: [
        'Mio connects to third-party AI providers (OpenRouter, DeepSeek, OpenAI, Anthropic, Google) to process your messages. Each provider has its own privacy policy governing how they handle data sent to their APIs. We recommend reviewing their policies.',
        'We do not sell or share your data with advertisers or data brokers. We will never monetize your personal information.',
      ],
    ),
    _Section(
      number: '5',
      title: 'Data Security',
      paragraphs: [
        'We implement industry-standard security measures including:',
      ],
      bullets: [
        'TLS 1.3 encryption for all data in transit.',
        'AES-256 encryption for sensitive data at rest.',
        'Regular security audits and penetration testing.',
        'SOC 2 Type II compliance (in progress).',
        'Incident response procedures with 24-hour notification.',
      ],
    ),
    _Section(
      number: '6',
      title: 'Your Rights',
      paragraphs: [
        'You have the right to access, export, or delete your data at any time. You can request a full data export from the settings screen. Account deletion permanently removes all associated data from our systems within 30 days.',
        'We comply with GDPR, CCPA, and applicable data protection regulations worldwide. If you are located in the EU, you have additional rights under GDPR including data portability and the right to lodge a complaint with a supervisory authority.',
      ],
    ),
    _Section(
      number: '7',
      title: 'Cookies & Tracking',
      paragraphs: [
        'We use essential cookies for authentication and session management. We do not use third-party tracking cookies or advertising pixels. Analytics are collected using privacy-respecting, first-party tools only.',
      ],
    ),
    _Section(
      number: '8',
      title: 'Children\'s Privacy',
      paragraphs: [
        'Mio is not intended for use by children under 13. We do not knowingly collect personal information from children. If you believe a child has provided us with personal data, please contact us for immediate removal.',
      ],
    ),
    _Section(
      number: '9',
      title: 'Changes to This Policy',
      paragraphs: [
        'We may update this privacy policy from time to time. We will notify you of any material changes via email or in-app notification at least 30 days before they take effect. Continued use of the service after changes constitutes acceptance.',
      ],
    ),
    _Section(
      number: '10',
      title: 'Contact Us',
      paragraphs: [
        'For privacy-related inquiries, data requests, or concerns, please contact us at privacy@mio.app. We will respond to all requests within 30 days.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final cardBg = isDark ? AppColors.darkBgSecondary : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: textPrimary, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Hero header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                              : [const Color(0xFFFFF8F3), const Color(0xFFFAF5EF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_outlined, size: 36, color: AppColors.persian),
                          const SizedBox(height: 16),
                          Text(
                            'Privacy Policy',
                            style: GoogleFonts.dmSerifDisplay(fontSize: 36, color: textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your privacy is fundamental to everything we build at Mio. This policy explains how we collect, use, and protect your information.',
                            style: GoogleFonts.dmSans(fontSize: 15, height: 1.5, color: textSecondary),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _dateBadge('Effective: $_effectiveDate', isDark, borderColor, textMuted),
                              const SizedBox(width: 8),
                              _dateBadge('Updated: $_lastUpdated', isDark, borderColor, textMuted),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Table of contents
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
                          Text('Contents', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                          const SizedBox(height: 12),
                          ..._sections.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  child: Text(s.number, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.persian)),
                                ),
                                Text(s.title, style: GoogleFonts.dmSans(fontSize: 13, color: textSecondary)),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sections
                    ..._sections.map((s) => _buildSectionCard(s, isDark, cardBg, borderColor, textPrimary, textSecondary, textMuted)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateBadge(String text, bool isDark, Color borderColor, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(text, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: textMuted)),
    );
  }

  Widget _buildSectionCard(_Section section, bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textSecondary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
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
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.persian.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(section.number, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.persian)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(section.title, style: GoogleFonts.dmSerifDisplay(fontSize: 19, color: textPrimary)),
              ],
            ),
            const SizedBox(height: 14),
            ...section.paragraphs.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(p, style: GoogleFonts.dmSans(fontSize: 14, height: 1.6, color: textSecondary)),
            )),
            if (section.bullets != null)
              ...section.bullets!.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: textMuted),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(b, style: GoogleFonts.dmSans(fontSize: 14, height: 1.6, color: textSecondary))),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}

class _Section {
  final String number;
  final String title;
  final List<String> paragraphs;
  final List<String>? bullets;

  const _Section({
    required this.number,
    required this.title,
    required this.paragraphs,
    this.bullets,
  });
}
