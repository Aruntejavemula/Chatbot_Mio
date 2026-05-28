import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/animations.dart';

class ReferralDialog extends StatefulWidget {
  const ReferralDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showMioModal(
      context: context,
      builder: (_) => const ReferralDialog(),
    );
  }

  @override
  State<ReferralDialog> createState() => _ReferralDialogState();
}

class _ReferralDialogState extends State<ReferralDialog> {
  bool _copied = false;
  static const String _referralLink = 'https://mio.app/register?ref=MIO_USER';

  void _copyLink() {
    Clipboard.setData(const ClipboardData(text: _referralLink));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final borderColor = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final cardBg = isDark ? AppColors.darkBgSecondary : Colors.white;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 520,
          constraints: const BoxConstraints(maxHeight: 540),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Invite Friends &\nEarn Credits',
                        style: GoogleFonts.dmSerifDisplay(fontSize: 30, color: textPrimary, height: 1.15),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textMuted, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Share your link and earn 10 credits when friends sign up and start chatting',
                    style: GoogleFonts.dmSans(fontSize: 14, color: textMuted),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Referral link + Copy button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor, width: 1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                              color: isDark ? AppColors.darkBgTertiary : AppColors.bgSecondary,
                            ),
                            child: Text(
                              _referralLink,
                              style: GoogleFonts.dmSans(fontSize: 13, color: textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _copyLink,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: _copied ? AppColors.persian : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _copied ? Icons.check : Icons.copy,
                                  size: 16,
                                  color: _copied ? Colors.white : (isDark ? Colors.black : Colors.white),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _copied ? 'Copied' : 'Copy',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _copied ? Colors.white : (isDark ? Colors.black : Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Copied confirmation
                    if (_copied) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
                          const SizedBox(width: 4),
                          Text(
                            'Copied to clipboard!',
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // How it Works
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How it Works', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 14),
                    _howItWorksRow(Icons.share_outlined, 'Share your unique referral link with friends', textPrimary, textMuted),
                    const SizedBox(height: 12),
                    _howItWorksRow(Icons.card_giftcard_outlined, 'They get **10 credits** when they sign up', textPrimary, textMuted, boldPart: '10 credits'),
                    const SizedBox(height: 12),
                    _howItWorksRow(Icons.card_giftcard_outlined, 'You earn **10 credits** when they start chatting', textPrimary, textMuted, boldPart: '10 credits'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Referrals counter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your Referrals (0/5)',
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                  ),
                ),
              ),
              const Spacer(),
              // Terms & Conditions
              Divider(color: borderColor, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Terms & Conditions',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _howItWorksRow(IconData icon, String text, Color textPrimary, Color textMuted, {String? boldPart}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (boldPart != null) {
      final parts = text.split('**$boldPart**');
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: parts[0], style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary)),
                  TextSpan(text: boldPart, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                  if (parts.length > 1)
                    TextSpan(text: parts[1], style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary))),
      ],
    );
  }
}
