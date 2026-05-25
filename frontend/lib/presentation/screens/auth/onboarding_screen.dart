import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/router.dart';
import '../../widgets/common/ghost_mascot.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _totalPages = 8;

  final PageController _pageController = PageController();
  final TextEditingController _apiKeyController = TextEditingController();

  int _currentPage = 0;
  bool _isKeyVisible = false;
  bool _isAnnualOnboarding = false;
  final Set<String> _selectedPreferences = {};

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = page);
  }

  void _nextPage() {
    if (_currentPage == 4) {
      _savePreferences();
    }
    if (_currentPage == 5 && _apiKeyController.text.isNotEmpty) {
      _saveApiKey();
    }
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    } else {
      _completeOnboarding();
    }
  }

  void _skipToReady() {
    _goToPage(_totalPages - 1);
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'user_preferences',
      _selectedPreferences.join(','),
    );
  }

  Future<void> _saveApiKey() async {
    const storage = FlutterSecureStorage();
    await storage.write(
      key: 'pending_api_key',
      value: _apiKeyController.text,
    );
  }

  Future<void> _completeOnboarding() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'onboarding_complete', value: 'true');
    if (mounted) {
      context.go(AppRoutes.chat);
    }
  }

  String _getReadyText() {
    if (_selectedPreferences.contains('Coding')) {
      return 'Ready to code?';
    } else if (_selectedPreferences.contains('Writing')) {
      return 'Ready to write?';
    } else if (_selectedPreferences.length > 1) {
      return 'Ready to create?';
    }
    return 'Ready to go?';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPageHook(isDark),
                      _buildPageProblem(isDark),
                      _buildPageSolution(isDark),
                      _buildPageBYOK(isDark),
                      _buildPagePreferences(isDark),
                      _buildPageAddKey(isDark),
                      _buildPagePricing(isDark),
                      _buildPageReady(isDark),
                    ],
                  ),
                  if (_currentPage <= 5)
                    Positioned(
                      top: 12,
                      right: 16,
                      child: TextButton(
                        onPressed: _skipToReady,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _buildBottomArea(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomArea(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingScreen,
        vertical: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalPages, (index) {
              final isActive = index == _currentPage;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive
                        ? AppColors.persian
                        : (isDark
                            ? AppColors.darkBorderDefault
                            : AppColors.borderDefault),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.persian,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentPage == _totalPages - 1 ? "Let's go" : 'Next',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_currentPage <= 5) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _skipToReady,
              child: Text(
                'Skip',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageHook(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PenguinMascot(size: 80, animate: true),
          const SizedBox(height: 24),
          Text(
            'Meet Mio.',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "The AI that doesn't yap.",
            style: GoogleFonts.dmSans(
              fontSize: 18,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'No greetings. No filler. Just answers.',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Text(
            'By continuing, you agree to our Terms of Service',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageProblem(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 80),
          Text(
            'Other AIs be like...',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBgSecondary
                    : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Text(
                "Hello! I'd be happy to help you with that! So, the answer "
                'to your question about the meaning of life, the universe, '
                'and everything is actually quite fascinating when you think '
                'about it from multiple perspectives...',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'You fell asleep reading that.',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageSolution(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 80),
          Text(
            'Mio be like...',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.persian,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Text(
                'The answer is 42.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Direct. Fast. No yapping.',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeaturePill('No filler', isDark),
              const SizedBox(width: 8),
              _buildFeaturePill('Straight answers', isDark),
              const SizedBox(width: 8),
              _buildFeaturePill('Your keys', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorderDefault
              : AppColors.borderDefault,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPageBYOK(bool isDark) {
    final providers = <_ProviderInfo>[
      _ProviderInfo(label: 'O', name: 'OpenAI', color: const Color(0xFF10A37F)),
      _ProviderInfo(label: 'A', name: 'Anthropic', color: const Color(0xFFD97757)),
      _ProviderInfo(label: 'D', name: 'DeepSeek', color: const Color(0xFF4D6BFE)),
      _ProviderInfo(label: 'G', name: 'Gemini', color: const Color(0xFF4285F4)),
      _ProviderInfo(label: 'G', name: 'Groq', color: const Color(0xFFF97316)),
      _ProviderInfo(label: 'M', name: 'Mistral', color: const Color(0xFF6366F1)),
      _ProviderInfo(label: 'R', name: 'OpenRouter', color: const Color(0xFF8B5CF6)),
      _ProviderInfo(label: 'O', name: 'Ollama', color: const Color(0xFF0EA5E9)),
      _ProviderInfo(
        label: '+',
        name: 'More',
        color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 80),
          Text(
            'Your AI. Your keys.',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              final isMore = provider.label == '+';
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: provider.color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        provider.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isMore
                              ? (isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textMuted)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    provider.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'No markup. No middleman.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPagePreferences(bool isDark) {
    const chips = [
      'Coding',
      'Writing',
      'Learning',
      'Work',
      'Creative',
      'Research',
      'Chat',
      'Math',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What do you use AI for?',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: chips.map((chip) {
              final isSelected = _selectedPreferences.contains(chip);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedPreferences.remove(chip);
                    } else {
                      _selectedPreferences.add(chip);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.persian
                        : (isDark
                            ? AppColors.darkBgSecondary
                            : AppColors.bgSecondary),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.persian
                          : (isDark
                              ? AppColors.darkBorderDefault
                              : AppColors.borderDefault),
                    ),
                  ),
                  child: Text(
                    chip,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageAddKey(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 80),
          Text(
            'Add your first key',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We recommend starting with OpenAI',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingCard),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorderDefault
                    : AppColors.borderDefault,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10A37F),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'O',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OpenAI',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.persian.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: Text(
                          'Most popular',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.persian,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            obscureText: !_isKeyVisible,
            decoration: InputDecoration(
              hintText: 'Paste your API key here',
              hintStyle: GoogleFonts.dmSans(
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.textMuted,
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkBorderDefault
                      : AppColors.borderDefault,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkBorderDefault
                      : AppColors.borderDefault,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                borderSide: const BorderSide(color: AppColors.persian),
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _isKeyVisible = !_isKeyVisible);
                },
                icon: Icon(
                  _isKeyVisible ? Icons.visibility_off : Icons.visibility,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted,
                ),
              ),
            ),
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'Or use Ollama locally',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagePricing(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Text(
            '14 days free.',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Then pick what works for you.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildOnboardingBillingToggle(isDark),
          const SizedBox(height: 16),
          _buildPlanCard(
            isDark: isDark,
            title: 'Free',
            price: '\$0',
            features: ['40K tokens/5hr', '1 device', 'Community models'],
            isHighlighted: false,
          ),
          const SizedBox(height: 12),
          _buildPlanCard(
            isDark: isDark,
            title: 'Basic',
            price: _isAnnualOnboarding ? '\$49.99/yr' : '\$4.99/mo',
            features: [
              '100K tokens/day',
              '3 devices',
              'File uploads',
              'Voice input',
              'All providers',
            ],
            isHighlighted: false,
            savingsText: _isAnnualOnboarding ? 'Save 17%' : null,
          ),
          const SizedBox(height: 12),
          _buildPlanCard(
            isDark: isDark,
            title: 'Pro',
            price: _isAnnualOnboarding ? '\$99.99/yr' : '\$9.99/mo',
            features: [
              'Unlimited*',
              '10 devices',
              'Everything in Basic',
              'Connectors',
              'Priority support',
              'Deep Research',
              'Image Gen',
            ],
            isHighlighted: true,
            savingsText: _isAnnualOnboarding ? 'Save 17%' : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOnboardingBillingToggle(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Monthly',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: !_isAnnualOnboarding
                ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          toggled: _isAnnualOnboarding,
          label: 'Billing period toggle',
          child: GestureDetector(
            onTap: () => setState(() => _isAnnualOnboarding = !_isAnnualOnboarding),
            child: Container(
              width: 56,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              padding: const EdgeInsets.all(2),
              child: AnimatedAlign(
                alignment: _isAnnualOnboarding
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
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
            color: _isAnnualOnboarding
                ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required bool isDark,
    required String title,
    required String price,
    required List<String> features,
    required bool isHighlighted,
    String? savingsText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingCard),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: isHighlighted
              ? AppColors.persian
              : (isDark
                  ? AppColors.darkBorderDefault
                  : AppColors.borderDefault),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (savingsText != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.persian.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        savingsText,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.persian,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Text(
                  price,
                  key: ValueKey<String>(price),
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.persian,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
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

  Widget _buildPageReady(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PenguinMascot(size: 100, animate: true),
          const SizedBox(height: 24),
          Text(
            _getReadyText(),
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProviderInfo {
  final String label;
  final String name;
  final Color color;

  const _ProviderInfo({
    required this.label,
    required this.name,
    required this.color,
  });
}
