import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  static const String _stripePortalUrl =
      'https://billing.stripe.com/p/login/placeholder';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Subscription',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentPlanCard(isDark),
            const SizedBox(height: 24),
            _buildPlanCard(
              isDark: isDark,
              name: 'Free',
              price: '\$0 / month',
              features: [
                _FeatureItem('BYOK support', true),
                _FeatureItem('1 device', true),
                _FeatureItem('20 messages per day', true),
                _FeatureItem('Cloud sync', false),
                _FeatureItem('All models', false),
                _FeatureItem('Included tokens', false),
              ],
              buttonText: 'Current Plan',
              isCurrentPlan: true,
              borderColor: isDark
                  ? AppColors.darkBorderDefault
                  : AppColors.borderDefault,
            ),
            const SizedBox(height: 12),
            _buildPlanCard(
              isDark: isDark,
              name: 'Basic',
              price: '\$4.99 / month',
              features: [
                _FeatureItem('BYOK support', true),
                _FeatureItem('2 devices', true),
                _FeatureItem('100 messages per day', true),
                _FeatureItem('Google Drive sync', true),
                _FeatureItem('All models', true),
                _FeatureItem('Encrypted storage', true),
              ],
              buttonText: 'Upgrade to Basic',
              borderColor: AppColors.persian,
              onButtonPressed: () => debugPrint('upgrade to basic'),
            ),
            const SizedBox(height: 12),
            _buildPlanCard(
              isDark: isDark,
              name: 'Pro',
              price: '\$9.99 / month',
              features: [
                _FeatureItem('Everything in Basic', true),
                _FeatureItem('5 devices', true),
                _FeatureItem('Unlimited messages', true),
                _FeatureItem('Full cloud sync', true),
                _FeatureItem('3M tokens per month', true),
                _FeatureItem('Skills and connectors', true),
                _FeatureItem('Memory', true),
                _FeatureItem('Export chats', true),
              ],
              buttonText: 'Upgrade to Pro',
              borderColor: AppColors.persian,
              isPro: true,
              onButtonPressed: () => debugPrint('upgrade to pro'),
            ),
            const SizedBox(height: 32),
            _buildManageSection(isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingScreen),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border.all(
          color:
              isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Plan',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color:
                        isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Free',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text(
              'FREE',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required bool isDark,
    required String name,
    required String price,
    required List<_FeatureItem> features,
    required String buttonText,
    required Color borderColor,
    bool isCurrentPlan = false,
    bool isPro = false,
    VoidCallback? onButtonPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingScreen),
      decoration: BoxDecoration(
        color: isPro ? const Color(0x0DCC5801) : null,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 20,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              if (isPro) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.persian,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    'Best Value',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            price,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      feature.included ? Icons.check : Icons.close,
                      size: 16,
                      color: feature.included
                          ? AppColors.success
                          : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feature.text,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isCurrentPlan
                ? ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkBgTertiary
                          : AppColors.bgTertiary,
                      disabledBackgroundColor: isDark
                          ? AppColors.darkBgTertiary
                          : AppColors.bgTertiary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                  )
                : isPro
                    ? ElevatedButton(
                        onPressed: onButtonPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.persian,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          buttonText,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: onButtonPressed,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.persian,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w500,
                            color: AppColors.persian,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'MANAGE',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
        ),
        _buildManageTile(
          icon: Icons.receipt_long_outlined,
          title: 'Manage Subscription',
          subtitle: 'Open Stripe billing portal',
          isDark: isDark,
          onTap: _openStripePortal,
        ),
        const SizedBox(height: 4),
        _buildManageTile(
          icon: Icons.cancel_outlined,
          title: 'Cancel Subscription',
          isDark: isDark,
          titleColor: AppColors.error,
          iconColor: AppColors.error,
          onTap: () => _showCancelDialog(isDark),
        ),
      ],
    );
  }

  Widget _buildManageTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isDark,
    Color? titleColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: iconColor ??
                  (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ??
                          (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStripePortal() async {
    try {
      final uri = Uri.parse(_stripePortalUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open billing portal')),
        );
      }
    }
  }

  void _showCancelDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        title: Text(
          'Cancel Subscription',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel your subscription? You will lose access to premium features at the end of your billing period.',
          style: GoogleFonts.dmSans(
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Keep Subscription',
              style: GoogleFonts.dmSans(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              debugPrint('cancel subscription confirmed');
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String text;
  final bool included;

  _FeatureItem(this.text, this.included);
}
