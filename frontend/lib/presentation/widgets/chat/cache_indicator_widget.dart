import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class CacheIndicatorWidget extends StatelessWidget {
  final int cachedTokens;
  final int totalInputTokens;
  final String provider;

  const CacheIndicatorWidget({
    super.key,
    required this.cachedTokens,
    required this.totalInputTokens,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    if (cachedTokens <= 0) return const SizedBox.shrink();

    final savings = _calculateSavings();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_outlined,
            size: 12,
            color: AppColors.persian.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            '$cachedTokens cached · ~$savings saved',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateSavings() {
    final double discount;
    final providerLower = provider.toLowerCase();
    if (providerLower.contains('anthropic') ||
        providerLower.contains('claude')) {
      discount = 0.9;
    } else if (providerLower.contains('deepseek')) {
      discount = 0.9;
    } else if (providerLower.contains('openai') ||
        providerLower.contains('gpt')) {
      discount = 0.5;
    } else {
      discount = 0.0;
    }
    final saved = (cachedTokens * discount).round();
    if (saved >= 1000) {
      return '${(saved / 1000).toStringAsFixed(1)}K tokens';
    }
    return '$saved tokens';
  }
}
