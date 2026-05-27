import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/region_service.dart';
import '../../../core/utils/router.dart';
import '../../widgets/common/ghost_mascot.dart';
import '../../widgets/settings/ollama_setup_sheet.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _totalPages = 8;

  final PageController _pageController = PageController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();

  int _currentPage = 0;
  bool _isKeyVisible = false;
  bool _isAnnualOnboarding = false;
  String _userCountry = 'US';
  String _selectedProvider = 'OpenRouter';
  String? _keyError;
  String? _nameError;
  String? _selectedPlan;
  bool _ready = false;
  final Set<String> _selectedPreferences = {};

  @override
  void initState() {
    super.initState();
    _loadRegion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) _precacheBackground();
  }

  Future<void> _precacheBackground() async {
    await precacheImage(const AssetImage('assets/images/sky_clouds.png'), context);
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _loadRegion() async {
    final country = await RegionService.getRegion();
    if (mounted) setState(() => _userCountry = country);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentPage = page);
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_firstNameCtrl.text.trim().isEmpty) {
        setState(() => _nameError = 'Please enter your name to continue');
        return;
      }
      _saveName();
    }
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

  Future<void> _saveName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_first_name', _firstNameCtrl.text.trim());
    await prefs.setString('user_last_name', _lastNameCtrl.text.trim());
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
    if (!_ready) {
      return const Scaffold(backgroundColor: Color(0xFFB8E4F9));
    }
    return Scaffold(
      body: Stack(
        children: [
          // Sky photo background
          Positioned.fill(
            child: Image.asset(
              'assets/images/sky_clouds.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildPageName(),
                          _buildPageProblem(false),
                          _buildPageSolution(false),
                          _buildPageBYOK(false),
                          _buildPagePreferences(false),
                          _buildPageAddKey(false),
                          _buildPagePricing(false),
                          _buildPageReady(false),
                        ],
                      ),
                      if (_currentPage > 0 && _currentPage <= 5)
                        Positioned(
                          top: 12,
                          right: 16,
                          child: TextButton(
                            onPressed: _skipToReady,
                            child: Text(
                              'Skip',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_currentPage > 0) _buildBottomArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomArea() {
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
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          // Hide continue on pricing page (it's inside the card)
          if (_currentPage != 6)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.persian,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == _totalPages - 1 ? "Let's go" : 'Continue',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_currentPage > 0)
                TextButton(
                  onPressed: () => _goToPage(_currentPage - 1),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    '← Back',
                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageName() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PenguinMascot(size: 56, animate: true),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "What's your name?",
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _onboardingField(
                    controller: _firstNameCtrl,
                    hint: 'First name',
                    action: TextInputAction.next,
                    onChanged: () { if (_nameError != null) setState(() => _nameError = null); },
                  ),
                  const SizedBox(height: 12),
                  _onboardingField(
                    controller: _lastNameCtrl,
                    hint: 'Last name',
                    action: TextInputAction.done,
                    onSubmit: _nextPage,
                  ),
                  if (_nameError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _nameError!,
                      style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFFEF4444)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.persian,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _onboardingField({
    required TextEditingController controller,
    required String hint,
    TextInputAction action = TextInputAction.next,
    VoidCallback? onSubmit,
    VoidCallback? onChanged,
  }) {
    return TextField(
      controller: controller,
      textInputAction: action,
      onSubmitted: (_) => onSubmit?.call(),
      onChanged: (_) => onChanged?.call(),
      style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(fontSize: 15, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.persian, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPageProblem(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Other AIs be like...',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // User message
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.persian,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "What's the capital of France?",
                    style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Verbose AI response
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "Great question! I'd be happy to help you with that! "
                    "So, the capital of France is a fascinating topic. "
                    "France, officially known as the French Republic, is a country "
                    "located in Western Europe. Its capital city, which has been the "
                    "center of French culture, politics, and economics for centuries, "
                    "is Paris. Paris is renowned for its art, fashion, gastronomy, "
                    "and landmarks such as the Eiffel Tower, the Louvre Museum, "
                    "and Notre-Dame Cathedral. The city has served as the capital "
                    "since the 10th century and continues to be one of the most "
                    "visited cities in the world. I hope that helps! Let me know "
                    "if you have any other questions! 😊",
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'You fell asleep reading that.',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageSolution(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Mio be like...',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Same user message
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.persian,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "What's the capital of France?",
                    style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Mio's concise response
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Paris.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Direct. Fast. No yapping.',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Feature points
              _featurePoint('1', 'Your keys, your models'),
              _featurePoint('2', 'Switch providers anytime'),
              _featurePoint('3', 'No markup on tokens'),
              _featurePoint('4', 'Run local with Ollama'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFeaturePill('No filler'),
                  const SizedBox(width: 8),
                  _buildFeaturePill('Straight answers'),
                  const SizedBox(width: 8),
                  _buildFeaturePill('Your keys'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'We don\'t own the LLMs — Mio is a router.',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _featurePoint(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.persian.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.persian),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildPageBYOK(bool isDark) {
    final providers = <Map<String, String>>[
      {'name': 'OpenAI', 'asset': 'assets/icons/providers/openai.png'},
      {'name': 'Anthropic', 'asset': 'assets/icons/providers/anthropic.png'},
      {'name': 'DeepSeek', 'asset': 'assets/icons/providers/deepseek.png'},
      {'name': 'Google Gemini', 'asset': 'assets/icons/providers/google.png'},
      {'name': 'Mistral', 'asset': 'assets/icons/providers/mistral.png'},
      {'name': 'OpenRouter', 'asset': 'assets/icons/providers/openrouter.png'},
      {'name': 'Kimi', 'asset': 'assets/icons/providers/kimi.png'},
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Your AI. Your keys.',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bring your own API keys — no markup, no middleman.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Provider grid with real icons
              Wrap(
                spacing: 12,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  ...providers.map((p) => SizedBox(
                    width: 72,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                p['asset']!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    p['name']![0],
                                    style: GoogleFonts.dmSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.persian,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p['name']!,
                          style: GoogleFonts.dmSans(fontSize: 10, color: const Color(0xFF6B7280)),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )),
                  // Many more
                  SizedBox(
                    width: 72,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
                          ),
                          child: const Center(
                            child: Icon(Icons.more_horiz, color: Color(0xFF9CA3AF), size: 20),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '& many more',
                          style: GoogleFonts.dmSans(fontSize: 9, color: const Color(0xFF9CA3AF)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // BYOK vs Locked comparison
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why BYOK?',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _comparisonRow('Access latest models instantly', true),
                    _comparisonRow('No rate limits from us', true),
                    _comparisonRow('Use local models (Ollama)', true),
                    _comparisonRow('Switch providers anytime', true),
                    _comparisonRow('No vendor lock-in', true),
                    const SizedBox(height: 10),
                    Text(
                      'Locked platforms:',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _comparisonRow('Stuck on old models', false),
                    _comparisonRow('Heavy rate limits', false),
                    _comparisonRow('Pay markup on every token', false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comparisonRow(String text, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: isPositive ? AppColors.textPrimary : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagePreferences(bool isDark) {
    const items = [
      {'label': 'Coding', 'icon': Icons.code},
      {'label': 'Writing', 'icon': Icons.edit_note},
      {'label': 'Learning', 'icon': Icons.school},
      {'label': 'Work', 'icon': Icons.work_outline},
      {'label': 'Creative', 'icon': Icons.palette_outlined},
      {'label': 'Research', 'icon': Icons.science_outlined},
      {'label': 'Chat', 'icon': Icons.chat_bubble_outline},
      {'label': 'Math', 'icon': Icons.calculate_outlined},
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'What do you use AI for?',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Select all that apply',
                style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              ...items.map((item) {
                final label = item['label'] as String;
                final icon = item['icon'] as IconData;
                final isSelected = _selectedPreferences.contains(label);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedPreferences.remove(label);
                        } else {
                          _selectedPreferences.add(label);
                        }
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.persian.withValues(alpha: 0.08) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.persian : const Color(0xFFE5E7EB),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: isSelected ? AppColors.persian : const Color(0xFF6B7280)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? AppColors.persian : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, size: 18, color: AppColors.persian),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageAddKey(bool isDark) {
    final providerOptions = <Map<String, String>>[
      {'name': 'OpenRouter', 'asset': 'assets/icons/providers/openrouter.png'},
      {'name': 'OpenAI', 'asset': 'assets/icons/providers/openai.png'},
      {'name': 'Anthropic', 'asset': 'assets/icons/providers/anthropic.png'},
      {'name': 'DeepSeek', 'asset': 'assets/icons/providers/deepseek.png'},
      {'name': 'Gemini', 'asset': 'assets/icons/providers/google.png'},
      {'name': 'Groq', 'asset': 'assets/icons/providers/groq.png'},
      {'name': 'Mistral', 'asset': 'assets/icons/providers/mistral.png'},
      {'name': 'Ollama', 'asset': 'assets/icons/providers/ollama.png'},
      {'name': 'Kimi', 'asset': 'assets/icons/providers/kimi.png'},
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Add your API key',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Choose a provider and paste your key',
                  style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6B7280)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Provider selector as styled dropdown
              Text(
                'Provider',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedProvider,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
                    dropdownColor: Colors.white,
                    style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
                    items: providerOptions.map((p) => DropdownMenuItem(
                      value: p['name']!,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              p['asset']!,
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox(width: 20, height: 20),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(p['name']!, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary)),
                        ],
                      ),
                    )).toList(),
                    onChanged: (v) => setState(() {
                      _selectedProvider = v!;
                      _keyError = null;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // OpenRouter recommendation
              if (_selectedProvider == 'OpenRouter') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFF8B5CF6)),
                          const SizedBox(width: 6),
                          Text(
                            'Recommended for beginners',
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF8B5CF6)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'OpenRouter gives you free access to many models. Add \$10 credit for higher rate limits and access to premium models.',
                        style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF4B5563), height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () => launchUrl(Uri.parse('https://openrouter.ai/keys'), mode: LaunchMode.externalApplication),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Get OpenRouter API Key →',
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // API key input
              Text(
                'API Key',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _apiKeyController,
                obscureText: !_isKeyVisible,
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
                onChanged: (_) {
                  if (_keyError != null) setState(() => _keyError = null);
                },
                decoration: InputDecoration(
                  hintText: 'Paste your $_selectedProvider API key',
                  hintStyle: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _keyError != null ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _keyError != null ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.persian, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _isKeyVisible = !_isKeyVisible),
                    icon: Icon(
                      _isKeyVisible ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF9CA3AF),
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Inline error
              if (_keyError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _keyError!,
                  style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFFEF4444)),
                ),
              ],
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => OllamaSetupSheet.show(context),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(
                      'Or use Ollama locally (no key needed)',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.persian),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagePricing(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Choose your plan',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick what works for you. Cancel anytime.',
                style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              _buildBillingToggle(),
              const SizedBox(height: 16),
              // Side-by-side plan cards
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _selectablePlanCard(
                    id: 'free',
                    title: 'Free',
                    price: '\$0',
                    features: [
                      '1M tokens/month',
                      '1 device',
                      'Community models',
                      'Basic chat',
                    ],
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _selectablePlanCard(
                    id: 'basic',
                    title: 'Basic',
                    price: _isAnnualOnboarding ? '\$3.99/mo' : '\$4.99/mo',
                    badge: 'Try 14 days free',
                    features: [
                      '1M tokens/month',
                      '5 devices',
                      'Cross sync',
                      'iCloud & Google Drive',
                      'All providers',
                      'File uploads',
                      'Voice input',
                    ],
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _selectablePlanCard(
                    id: 'pro',
                    title: 'Pro',
                    price: _isAnnualOnboarding ? '\$7.99/mo' : '\$9.99/mo',
                    features: [
                      'Everything in Basic',
                      'Cross sync',
                      'iCloud & Google Drive',
                      'Mio Cloud',
                      'DeepSeek V4 Pro access',
                      '5 devices',
                      'Deep Research',
                      'Image Gen',
                    ],
                  )),
                ],
              ),
              if (_selectedPlan != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedPlan == 'free') {
                        _goToPage(_totalPages - 1);
                      } else {
                        _completeOnboarding();
                        context.go(AppRoutes.subscription);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.persian,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      _selectedPlan == 'free'
                          ? 'Continue with Free'
                          : _selectedPlan == 'basic'
                              ? 'Try 14 days free'
                              : 'Subscribe',
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Monthly',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: !_isAnnualOnboarding ? AppColors.textPrimary : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => setState(() => _isAnnualOnboarding = !_isAnnualOnboarding),
          child: Container(
            width: 48,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(13),
            ),
            padding: const EdgeInsets.all(2),
            child: AnimatedAlign(
              alignment: _isAnnualOnboarding ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.persian,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Annual',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _isAnnualOnboarding ? AppColors.textPrimary : const Color(0xFF9CA3AF),
          ),
        ),
        if (_isAnnualOnboarding) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-20%',
              style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF10B981)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _selectablePlanCard({
    required String id,
    required String title,
    required String price,
    required List<String> features,
    String? badge,
  }) {
    final isSelected = _selectedPlan == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.persian.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.persian : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.dmSerifDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, size: 18, color: AppColors.persian),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            if (badge != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF10B981)),
                ),
              ),
            ],
            const SizedBox(height: 10),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check, size: 12, color: AppColors.persian),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      f,
                      style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF4B5563), height: 1.3),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
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

