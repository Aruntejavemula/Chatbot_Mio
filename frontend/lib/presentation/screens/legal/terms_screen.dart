import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const String _lastUpdated = 'May 28, 2026';
  static const String _effectiveDate = 'June 1, 2026';

  static const List<_Section> _sections = [
    _Section(
      number: '1',
      title: 'Acceptance of Terms',
      paragraphs: [
        'By creating an account or using Mio, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree, please discontinue use immediately.',
        'We reserve the right to update these terms at any time. We will notify you of material changes via email or in-app notification at least 30 days before they take effect. Continued use after changes constitutes acceptance.',
      ],
    ),
    _Section(
      number: '2',
      title: 'Account Registration',
      paragraphs: [
        'You must provide accurate and complete information when creating your account. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.',
      ],
      bullets: [
        'You must be at least 13 years old to use Mio.',
        'One person or legal entity per account.',
        'You are responsible for all activity under your account.',
        'Notify us immediately of any unauthorized access.',
      ],
    ),
    _Section(
      number: '3',
      title: 'BYOK & API Keys',
      paragraphs: [
        'Mio operates on a Bring Your Own Key (BYOK) model. You are responsible for obtaining and managing your own API keys from supported providers (OpenAI, Anthropic, Google, DeepSeek, OpenRouter).',
      ],
      bullets: [
        'Usage charges from third-party AI providers are your responsibility.',
        'Mio is not liable for charges incurred through your API keys.',
        'You must comply with each provider\'s terms of service.',
        'Do not share API keys or use keys obtained without authorization.',
      ],
    ),
    _Section(
      number: '4',
      title: 'Subscription & Billing',
      paragraphs: [
        'Mio offers free and paid subscription tiers. Paid plans are billed monthly or annually as selected at checkout.',
      ],
      bullets: [
        'Subscriptions auto-renew unless cancelled before the renewal date.',
        'Refunds are available within 14 days of initial purchase, subject to review.',
        'Price changes will be communicated 30 days in advance.',
        'Downgrading may result in loss of access to premium features.',
        'Credits are non-transferable and expire at the end of each billing cycle.',
      ],
    ),
    _Section(
      number: '5',
      title: 'AI Disclaimer',
      paragraphs: [
        'AI-generated responses may contain inaccuracies, biases, or errors. Mio does not guarantee the accuracy, completeness, or reliability of AI outputs.',
        'You should independently verify any information before relying on it for important decisions. AI responses do not constitute professional, legal, medical, or financial advice of any kind.',
      ],
    ),
    _Section(
      number: '6',
      title: 'Acceptable Use',
      paragraphs: [
        'You agree not to use Mio for any unlawful or prohibited purpose. Specifically, you may not:',
      ],
      bullets: [
        'Generate illegal, harmful, or deceptive content.',
        'Harass, threaten, or impersonate others.',
        'Attempt to circumvent safety measures or content filters.',
        'Reverse-engineer, decompile, or extract source code from the service.',
        'Engage in automated abuse, token farming, or reselling access.',
        'Use Mio to develop competing AI products without written permission.',
        'Upload malware, viruses, or malicious code.',
      ],
    ),
    _Section(
      number: '7',
      title: 'Intellectual Property',
      paragraphs: [
        'You retain ownership of all content you create using Mio. We do not claim any rights to your inputs or the AI-generated outputs produced for you.',
        'The Mio brand, logo, design system, and software are proprietary. You may not use our trademarks without written permission.',
      ],
    ),
    _Section(
      number: '8',
      title: 'Data & Privacy',
      paragraphs: [
        'Your use of Mio is also governed by our Privacy Policy. By using Mio, you consent to the collection and use of information as described in our Privacy Policy.',
        'You can export or delete your data at any time through the settings panel.',
      ],
    ),
    _Section(
      number: '9',
      title: 'Limitation of Liability',
      paragraphs: [
        'Mio is provided "as is" without warranties of any kind. To the maximum extent permitted by law, we disclaim all warranties, express or implied, including merchantability, fitness for a particular purpose, and non-infringement.',
        'Our total liability to you for any claims arising from your use of Mio shall not exceed the amount you paid for the service in the 12 months preceding the claim.',
      ],
    ),
    _Section(
      number: '10',
      title: 'Termination',
      paragraphs: [
        'We may terminate or suspend your account at our discretion if you violate these terms or engage in conduct that we determine is harmful to other users or the service.',
        'You may delete your account at any time through settings. Upon termination, your data will be deleted in accordance with our Privacy Policy within 30 days.',
      ],
    ),
    _Section(
      number: '11',
      title: 'Governing Law',
      paragraphs: [
        'These terms shall be governed by and construed in accordance with the laws of the jurisdiction in which Mio operates, without regard to conflict of law principles. Any disputes arising from these terms shall be resolved through binding arbitration.',
      ],
    ),
    _Section(
      number: '12',
      title: 'Contact',
      paragraphs: [
        'For questions about these terms, please contact us at legal@mio.app. We will respond to all inquiries within 30 business days.',
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
                          const Icon(Icons.description_outlined, size: 36, color: AppColors.persian),
                          const SizedBox(height: 16),
                          Text(
                            'Terms of Service',
                            style: GoogleFonts.dmSerifDisplay(fontSize: 36, color: textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please read these terms carefully before using Mio. They govern your access to and use of the service.',
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
                                  width: 24,
                                  child: Text(s.number, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.persian)),
                                ),
                                Expanded(child: Text(s.title, style: GoogleFonts.dmSans(fontSize: 13, color: textSecondary))),
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
                Expanded(child: Text(section.title, style: GoogleFonts.dmSerifDisplay(fontSize: 19, color: textPrimary))),
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
