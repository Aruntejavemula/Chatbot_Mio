import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          'Terms of Service',
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
            title: 'Acceptance',
            body:
                'By using Mio Cloud, you agree to these terms of service. If you do '
                'not agree, please discontinue use immediately. We reserve the right '
                'to update these terms at any time, and continued use constitutes '
                'acceptance of any changes.',
            isDark: isDark,
          ),
          _LegalSection(
            title: 'BYOK and API keys',
            body:
                'Mio Cloud operates on a Bring Your Own Key (BYOK) model. You are '
                'responsible for obtaining and managing your own API keys from '
                'supported providers. Usage charges from third-party AI providers '
                'are your responsibility. Mio Cloud is not liable for charges '
                'incurred through your API keys.',
            isDark: isDark,
          ),
          _LegalSection(
            title: 'AI disclaimer',
            body:
                'AI-generated responses may contain inaccuracies, biases, or errors. '
                'Mio Cloud does not guarantee the accuracy, completeness, or '
                'reliability of AI outputs. You should independently verify any '
                'information before relying on it for important decisions. AI '
                'responses do not constitute professional advice of any kind.',
            isDark: isDark,
          ),
          _LegalSection(
            title: 'Prohibited use',
            body:
                'You may not use Mio Cloud to generate illegal content, harass others, '
                'attempt to circumvent safety measures, or reverse-engineer the service. '
                'Automated abuse, token farming, or reselling access is strictly '
                'prohibited. We reserve the right to suspend accounts that violate '
                'these terms.',
            isDark: isDark,
          ),
          _LegalSection(
            title: 'Termination',
            body:
                'We may terminate or suspend your account at our discretion if you '
                'violate these terms. You may delete your account at any time through '
                'settings. Upon termination, your data will be deleted in accordance '
                'with our privacy policy.',
            isDark: isDark,
          ),
          _LegalSection(
            title: 'Contact',
            body:
                'For questions about these terms, please contact us at legal@miocloud.app.',
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
