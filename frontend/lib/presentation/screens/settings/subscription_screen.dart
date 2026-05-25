import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/region_service.dart';
import '../../widgets/common/ghost_mascot.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String _country = 'US';
  // ignore: prefer_final_fields
  bool _isSubscribed = false;
  // ignore: prefer_final_fields
  String _subscribedVia = '';
  bool _isAnnual = false;

  @override
  void initState() {
    super.initState();
    _loadRegion();
  }

  Future<void> _loadRegion() async {
    final country = await RegionService.getRegion();
    if (mounted) setState(() => _country = country);
  }

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
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (RegionService.isIndian(_country)) {
      return _isSubscribed
          ? _buildIndianSubscribed(isDark)
          : _buildIndianNotSubscribed(isDark);
    }
    return _isSubscribed
        ? _buildGlobalSubscribed(isDark)
        : _buildGlobalNotSubscribed(isDark);
  }

  Widget _buildIndianNotSubscribed(bool isDark) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingCard),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              const PenguinMascot(size: 80, animate: true),
              const SizedBox(height: 24),
              Text(
                'Subscribe to Mio',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 28,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'To subscribe, visit:',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SelectableText(
                'mio.app/subscribe',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22,
                  color: AppColors.persian,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Basic ${RegionService.getPriceDisplay(_country, 'basic', false)} \u00B7 Pro ${RegionService.getPriceDisplay(_country, 'pro', false)}',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Annual plans available on our website.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndianSubscribed(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentPlanCard(isDark),
          const SizedBox(height: 16),
          Text(
            'Manage your subscription at mio.app/account',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalNotSubscribed(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentPlanCard(isDark),
          const SizedBox(height: 24),
          if (RegionService.hasAnnualOption(_country)) ...[
            _buildBillingToggle(isDark),
            const SizedBox(height: 16),
          ],
          _buildPlanCard(
            isDark: isDark,
            name: 'Basic',
            price: RegionService.getPriceDisplay(
              _country, 'basic', _isAnnual,
            ),
            features: [
              _FeatureItem('BYOK support', true),
              _FeatureItem('2 devices', true),
              _FeatureItem('100 messages per day', true),
              _FeatureItem('Google Drive sync', true),
              _FeatureItem('All models', true),
              _FeatureItem('Encrypted storage', true),
            ],
            borderColor: isDark
                ? AppColors.darkBorderDefault
                : AppColors.borderDefault,
          ),
          const SizedBox(height: 12),
          _buildPlanCard(
            isDark: isDark,
            name: 'Pro',
            price: RegionService.getPriceDisplay(
              _country, 'pro', _isAnnual,
            ),
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
            borderColor: AppColors.persian,
            isPro: true,
          ),
          const SizedBox(height: 24),
          _buildAppStoreOption(isDark),
          const SizedBox(height: 12),
          _buildWebsiteOption(isDark),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGlobalSubscribed(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentPlanCard(isDark),
          const SizedBox(height: 16),
          Text(
            _getManagementText(),
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _getManagementText() {
    switch (_subscribedVia) {
      case 'stripe':
      case 'razorpay':
        return 'Manage at mio.app/account';
      case 'apple':
        return 'Manage in App Store Settings';
      case 'google':
        return 'Manage in Play Store Subscriptions';
      default:
        return 'Manage at mio.app/account';
    }
  }

  Widget _buildAppStoreOption(bool isDark) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coming soon \u2014 use website option for now'),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
          border: Border.all(
            color: isDark
                ? AppColors.darkBorderDefault
                : AppColors.borderDefault,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.phone_iphone,
              size: 24,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Store / Play Store',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    RegionService.getPriceDisplay(_country, 'pro', _isAnnual),
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

  Widget _buildWebsiteOption(bool isDark) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(
          'https://mio.app/subscribe?country=$_country',
        );
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open browser')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.persian.withValues(alpha: 0.1),
          border: Border.all(
            color: AppColors.persian,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.language,
              size: 24,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscribe via Website',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Save more with website pricing',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.persian,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                'BEST DEAL',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingToggle(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Monthly',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: !_isAnnual
                ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          toggled: _isAnnual,
          label: 'Billing period toggle',
          child: GestureDetector(
            onTap: () => setState(() => _isAnnual = !_isAnnual),
            child: Container(
              width: 56,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              padding: const EdgeInsets.all(2),
              child: AnimatedAlign(
                alignment:
                    _isAnnual ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.persian,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Annual',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _isAnnual
                ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          ),
        ),
      ],
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
    required Color borderColor,
    bool isPro = false,
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
          const SizedBox(height: 4),
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
