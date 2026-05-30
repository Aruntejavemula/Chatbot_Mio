import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/animations.dart';
import '../../../core/utils/region_service.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String _country = 'US';
  int _activeTab = 0; // 0 = Individual, 1 = Team and Enterprise
  bool _isAnnual = true;

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
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: textPrimary, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'Plans that grow with you',
                style: GoogleFonts.dmSerifDisplay(fontSize: 32, color: textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Individual / Team toggle
              _buildTabToggle(isDark, textPrimary),
              const SizedBox(height: 32),
              // Plan cards
              if (_activeTab == 0)
                _buildIndividualPlans(isDark, textPrimary)
              else
                _buildTeamPlans(isDark, textPrimary),
              const SizedBox(height: 24),
              // Disclaimer
              Text(
                '*Usage limits apply. Prices shown don\'t include applicable tax.',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabToggle(bool isDark, Color textPrimary) {
    final borderColor = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final activeBg = isDark ? AppColors.darkBgSecondary : Colors.white;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgTertiary : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tabChip('Individual', 0, activeBg, textPrimary, isDark),
          _tabChip('Team and Enterprise', 1, activeBg, textPrimary, isDark),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int index, Color activeBg, Color textPrimary, bool isDark) {
    final isActive = _activeTab == index;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? textPrimary : textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildIndividualPlans(bool isDark, Color textPrimary) {
    final borderColor = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final cardBg = isDark ? AppColors.darkBgSecondary : Colors.white;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          final cards = [
            _buildPlanCard(
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textMuted: textMuted,
              name: 'Free',
              tagline: 'Meet Mio',
              price: '\$0',
              priceSuffix: '',
              ctaLabel: 'Use Mio for free',
              ctaFilled: false,
              showBillingToggle: false,
              features: [
                'Chat on web, iOS, Android, and desktop',
                'Generate code and visualize data',
                'Connect services and integrations',
                'Extended thinking for complex work',
              ],
              moreFeatures: 6,
              onCta: () => Navigator.of(context).pop(),
            ),
            _buildPlanCard(
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textMuted: textMuted,
              name: 'Pro',
              tagline: 'Research, code, and organize',
              price: _isAnnual
                  ? RegionService.getPriceDisplay(_country, 'basic', true)
                  : RegionService.getPriceDisplay(_country, 'basic', false),
              priceSuffix: _isAnnual ? 'billed annually' : 'billed monthly',
              ctaLabel: 'Get Pro plan',
              ctaFilled: true,
              showBillingToggle: true,
              features: [
                'Everything in Free and:',
                'Full code access in your codebase',
                'Power through tasks with connectors',
                'Higher usage limits',
                'Deep research and analysis',
              ],
              moreFeatures: 5,
              headerText: 'Everything in Free and:',
              onCta: () => context.go('/settings/subscription/checkout?plan=pro&annual=$_isAnnual'),
            ),
            _buildPlanCard(
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textMuted: textMuted,
              name: 'Max',
              tagline: 'Higher limits, priority access',
              price: 'From ${RegionService.getPriceDisplay(_country, 'pro', false)}',
              priceSuffix: 'billed monthly',
              ctaLabel: 'Get Max plan',
              ctaFilled: true,
              showBillingToggle: false,
              features: [
                'Everything in Pro, plus:',
                'Up to 20x more usage than Pro*',
                'Early access to advanced features',
                'Higher output limits for all tasks',
                'Priority access at high traffic times',
                'Advanced integrations',
              ],
              headerText: 'Everything in Pro, plus:',
              onCta: () => context.go('/settings/subscription/checkout?plan=max&annual=$_isAnnual'),
            ),
          ];

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(cards.length, (i) => Expanded(
                child: StaggeredListItem(
                  index: i,
                  slideOffset: 30,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: cards[i],
                  ),
                ),
              )),
            );
          }
          return Column(
            children: List.generate(cards.length, (i) => StaggeredListItem(
              index: i,
              slideOffset: 30,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: cards[i],
              ),
            )),
          );
        },
      ),
    );
  }

  Widget _buildTeamPlans(bool isDark, Color textPrimary) {
    final borderColor = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final cardBg = isDark ? AppColors.darkBgSecondary : Colors.white;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.business_outlined, size: 48, color: textMuted),
            const SizedBox(height: 16),
            Text(
              'Team and Enterprise plans',
              style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Collaborate with your team with shared workspaces, admin controls, and advanced security.',
              style: GoogleFonts.dmSans(fontSize: 14, color: textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => launchUrl(
                Uri.parse('mailto:sales@mio.bot?subject=Team%20%26%20Enterprise%20plan%20inquiry'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              child: Text(
                'Contact Sales',
                style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.black : Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textMuted,
    required String name,
    required String tagline,
    required String price,
    required String priceSuffix,
    required String ctaLabel,
    required bool ctaFilled,
    required bool showBillingToggle,
    required List<String> features,
    int moreFeatures = 0,
    String? headerText,
    required VoidCallback onCta,
  }) {
    final checkColor = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;

    return HoverLift(
      builder: (isHovered) => AnimatedContainer(
        duration: MioAnimations.fast,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered ? AppColors.persian.withValues(alpha: 0.4) : borderColor,
            width: isHovered ? 1.5 : 1,
          ),
          boxShadow: isHovered
              ? [BoxShadow(color: AppColors.persian.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))]
              : [],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Billing toggle (Pro card only)
          if (showBillingToggle) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _billingChip('Monthly', !_isAnnual, isDark, textPrimary, textMuted, () => setState(() => _isAnnual = false)),
                const SizedBox(width: 4),
                _billingChip('Yearly', _isAnnual, isDark, textPrimary, textMuted, () => setState(() => _isAnnual = true)),
                if (_isAnnual) ...[
                  const SizedBox(width: 6),
                  Text('· Save 17%', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.persian)),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          // Plan name + tagline
          Text(name, style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: textPrimary)),
          const SizedBox(height: 2),
          Text(tagline, style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
          const SizedBox(height: 16),
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(price, style: GoogleFonts.dmSerifDisplay(fontSize: 32, color: textPrimary)),
              if (priceSuffix.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(priceSuffix, style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // CTA button
          SizedBox(
            width: double.infinity,
            child: ctaFilled
                ? FilledButton(
                    onPressed: onCta,
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(ctaLabel, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.black : Colors.white)),
                  )
                : OutlinedButton(
                    onPressed: onCta,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(ctaLabel, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                  ),
          ),
          const SizedBox(height: 20),
          // Features
          if (headerText != null) ...[
            Text(headerText, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
            const SizedBox(height: 8),
          ],
          ...features.where((f) => f != headerText).map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check, size: 16, color: checkColor),
                const SizedBox(width: 8),
                Expanded(child: Text(feature, style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary))),
              ],
            ),
          )),
          if (moreFeatures > 0) ...[
            const SizedBox(height: 8),
            Text('+$moreFeatures more features', style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
          ],
        ],
      ),
    ),
    );
  }

  Widget _billingChip(String label, bool isActive, bool isDark, Color textPrimary, Color textMuted, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.darkBgTertiary : AppColors.bgSecondary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? textPrimary : textMuted,
          ),
        ),
      ),
    );
  }
}
