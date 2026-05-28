import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/region_service.dart';
import '../../../core/utils/router.dart';
import '../../widgets/common/shaking_hands.dart';
import '../../widgets/settings/ollama_setup_sheet.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
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

  late final AnimationController _pageEntranceController;
  late final AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _loadRegion();
    _pageEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) _precacheBackground();
  }

  Future<void> _precacheBackground() async {
    await precacheImage(
        const AssetImage('assets/images/sky_clouds.png'), context);
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
    _pageEntranceController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentPage = page);
    _pageEntranceController.reset();
    _pageEntranceController.forward();
    if (page == _totalPages - 1) {
      _celebrationController.forward();
    }
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
    final name = _firstNameCtrl.text.trim();
    final greeting = name.isNotEmpty ? 'You\'re all set, $name!' : 'You\'re all set!';
    if (_selectedPreferences.contains('Coding')) {
      return '$greeting\nLet\'s code.';
    } else if (_selectedPreferences.contains('Writing')) {
      return '$greeting\nLet\'s write.';
    } else if (_selectedPreferences.length > 1) {
      return '$greeting\nLet\'s create.';
    }
    return '$greeting\nLet\'s go.';
  }

  Widget _animatedContent({required Widget child}) {
    final fade = CurvedAnimation(
      parent: _pageEntranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    final slide = CurvedAnimation(
      parent: _pageEntranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );
    final scale = CurvedAnimation(
      parent: _pageEntranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: _pageEntranceController,
      builder: (context, _) => Opacity(
        opacity: fade.value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - slide.value)),
          child: Transform.scale(
            scale: 0.95 + 0.05 * scale.value,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_ready) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBgPrimary : const Color(0xFFB8E4F9),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Snow mountains background
          Positioned.fill(
            child: Image.asset(
              'assets/images/sky_clouds.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay for dark mode readability
          if (isDark)
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.5)),
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
                          _buildPageName(isDark),
                          _buildPageProblem(isDark),
                          _buildPageSolution(isDark),
                          _buildPageBYOK(isDark),
                          _buildPagePreferences(isDark),
                          _buildPageAddKey(isDark),
                          _buildPagePricing(isDark),
                          _buildPageReady(isDark),
                        ],
                      ),
                      if (_currentPage > 0 && _currentPage <= 5)
                        Positioned(
                          top: 12,
                          right: 16,
                          child: TextButton(
                            onPressed: _skipToReady,
                            style: TextButton.styleFrom(
                              backgroundColor: _cardBg(isDark).withOpacity(0.8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(
                              'Skip',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_currentPage > 0) _buildBottomArea(isDark),
              ],
            ),
          ),
          // Celebration particles on ready page
          if (_currentPage == _totalPages - 1)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _celebrationController,
                  builder: (context, _) => CustomPaint(
                    painter: _ConfettiPainter(
                        progress: _celebrationController.value),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _cardBg(bool isDark) =>
      isDark ? const Color(0xFF1A1A1A) : Colors.white;
  Color _cardBorder(bool isDark) =>
      isDark ? AppColors.darkBorderDefault : Colors.white.withOpacity(0.6);
  Color _subtitleColor(bool isDark) =>
      isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280);
  Color _textPrimary(bool isDark) =>
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color _inputBg(bool isDark) =>
      isDark ? AppColors.darkInputBg : const Color(0xFFF9FAFB);
  Color _inputBorder(bool isDark) =>
      isDark ? AppColors.darkInputBorder : const Color(0xFFE5E7EB);

  BoxDecoration _cardDecoration(bool isDark) => BoxDecoration(
        color: isDark
            ? _cardBg(isDark).withOpacity(0.92)
            : _cardBg(isDark).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  Widget _buildBottomArea(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalPages, (index) {
              final isActive = index == _currentPage;
              final isCompleted = index < _currentPage;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive
                        ? AppColors.persian
                        : isCompleted
                            ? AppColors.persian.withOpacity(0.4)
                            : (isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.white.withOpacity(0.6)),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          // Continue button (hidden on pricing page)
          if (_currentPage != 6)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.persian,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == _totalPages - 1 ? "Let's go" : 'Continue',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _goToPage(_currentPage - 1),
              style: TextButton.styleFrom(
                backgroundColor:
                    _cardBg(isDark).withOpacity(isDark ? 0.6 : 0.7),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                '\u2190 Back',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary(isDark),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Step 1: Name ───────────────────────────────────────────────────────────
  Widget _buildPageName(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _animatedContent(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ShakingHands(size: 64, animate: true),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(28),
                decoration: _cardDecoration(isDark),
                child: Column(
                  children: [
                    Text(
                      "What's your name?",
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary(isDark),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _onboardingField(
                      controller: _firstNameCtrl,
                      hint: 'First name',
                      isDark: isDark,
                      action: TextInputAction.next,
                      onChanged: () {
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _onboardingField(
                      controller: _lastNameCtrl,
                      hint: 'Last name (optional)',
                      isDark: isDark,
                      action: TextInputAction.done,
                      onSubmit: _nextPage,
                    ),
                    if (_nameError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _nameError!,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.persian,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Widget _onboardingField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputAction action = TextInputAction.next,
    VoidCallback? onSubmit,
    VoidCallback? onChanged,
  }) {
    return TextField(
      controller: controller,
      textInputAction: action,
      onSubmitted: (_) => onSubmit?.call(),
      onChanged: (_) => onChanged?.call(),
      style: GoogleFonts.dmSans(fontSize: 15, color: _textPrimary(isDark)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
            fontSize: 15,
            color: isDark ? AppColors.darkTextMuted : const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: _inputBg(isDark),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _inputBorder(isDark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _inputBorder(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.persian, width: 1.5),
        ),
      ),
    );
  }

  // ── Step 2: Problem ────────────────────────────────────────────────────────
  Widget _buildPageProblem(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _animatedContent(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Other AIs be like...',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary(isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // User message
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 260),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.persian,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "What's the capital of France?",
                      style:
                          GoogleFonts.dmSans(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Verbose AI response
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBgSecondary
                          : const Color(0xFFF3F4F6),
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
                      "if you have any other questions! \u{1F60A}",
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: _textPrimary(isDark),
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
                      color: _subtitleColor(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 3: Solution ───────────────────────────────────────────────────────
  Widget _buildPageSolution(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _animatedContent(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Mio be like...',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary(isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Same user message
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 260),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.persian,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "What's the capital of France?",
                      style:
                          GoogleFonts.dmSans(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Mio's concise response
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBgSecondary
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Paris.',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: _textPrimary(isDark),
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
                      color: _subtitleColor(isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _featurePoint('1', 'Your keys, your models', isDark),
                _featurePoint('2', 'Switch providers anytime', isDark),
                _featurePoint('3', 'No markup on tokens', isDark),
                _featurePoint('4', 'Run local with Ollama', isDark),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildFeaturePill('No filler', isDark),
                    _buildFeaturePill('Straight answers', isDark),
                    _buildFeaturePill('Your keys', isDark),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'We don\'t own the LLMs \u2014 Mio is a router.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: _subtitleColor(isDark),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _inputBorder(isDark)),
        color: isDark ? AppColors.darkBgSecondary : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          color: _subtitleColor(isDark),
        ),
      ),
    );
  }

  Widget _featurePoint(String number, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.persian.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.persian),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.dmSans(
                fontSize: 14, color: _textPrimary(isDark)),
          ),
        ],
      ),
    );
  }

  // ── Step 4: BYOK ──────────────────────────────────────────────────────────
  Widget _buildPageBYOK(bool isDark) {
    final providers = <Map<String, String>>[
      {'name': 'OpenAI', 'asset': 'assets/icons/providers/openai.png'},
      {'name': 'Anthropic', 'asset': 'assets/icons/providers/anthropic.png'},
      {'name': 'DeepSeek', 'asset': 'assets/icons/providers/deepseek.png'},
      {'name': 'Gemini', 'asset': 'assets/icons/providers/google.png'},
      {'name': 'Mistral', 'asset': 'assets/icons/providers/mistral.png'},
      {'name': 'OpenRouter', 'asset': 'assets/icons/providers/openrouter.png'},
      {'name': 'Kimi', 'asset': 'assets/icons/providers/kimi.png'},
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _animatedContent(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(isDark),
            child: Column(
              children: [
                Text(
                  'Your AI. Your keys.',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary(isDark),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bring your own API keys \u2014 no markup, no middleman.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: _subtitleColor(isDark),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Provider grid
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
                                  color: isDark
                                      ? AppColors.darkBgSecondary
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(isDark ? 0.2 : 0.08),
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
                                style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    color: _subtitleColor(isDark)),
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
                              color: isDark
                                  ? AppColors.darkBgTertiary
                                  : const Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                              border: Border.all(color: _inputBorder(isDark)),
                            ),
                            child: Icon(Icons.more_horiz,
                                color: _subtitleColor(isDark), size: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '& many more',
                            style: GoogleFonts.dmSans(
                                fontSize: 9,
                                color: _subtitleColor(isDark)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // BYOK comparison
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _inputBg(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _inputBorder(isDark)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why BYOK?',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _comparisonRow(
                          'Access latest models instantly', true, isDark),
                      _comparisonRow('No rate limits from us', true, isDark),
                      _comparisonRow('Use local models (Ollama)', true, isDark),
                      _comparisonRow('Switch providers anytime', true, isDark),
                      _comparisonRow('No vendor lock-in', true, isDark),
                      const SizedBox(height: 10),
                      Text(
                        'Locked platforms:',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _subtitleColor(isDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _comparisonRow('Stuck on old models', false, isDark),
                      _comparisonRow('Heavy rate limits', false, isDark),
                      _comparisonRow(
                          'Pay markup on every token', false, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _comparisonRow(String text, bool isPositive, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: isPositive ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: isPositive
                    ? _textPrimary(isDark)
                    : _subtitleColor(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Preferences ────────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _animatedContent(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(isDark),
            child: Column(
              children: [
                Text(
                  'What do you use AI for?',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary(isDark),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Select all that apply',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: _subtitleColor(isDark)),
                ),
                const SizedBox(height: 20),
                // 2-column grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.8,
                  children: items.map((item) {
                    final label = item['label'] as String;
                    final icon = item['icon'] as IconData;
                    final isSelected =
                        _selectedPreferences.contains(label);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedPreferences.remove(label);
                          } else {
                            _selectedPreferences.add(label);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.persian.withOpacity(0.08)
                              : _inputBg(isDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.persian
                                : _inputBorder(isDark),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(icon,
                                size: 18,
                                color: isSelected
                                    ? AppColors.persian
                                    : _subtitleColor(isDark)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                label,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.persian
                                      : _textPrimary(isDark),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  size: 16, color: AppColors.persian),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 6: Add Key ────────────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _animatedContent(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Add your API key',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary(isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Choose a provider and paste your key',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: _subtitleColor(isDark)),
                  ),
                ),
                const SizedBox(height: 20),
                // Provider selector
                Text(
                  'Provider',
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary(isDark)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _inputBg(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _inputBorder(isDark)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedProvider,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down,
                          color: _subtitleColor(isDark)),
                      dropdownColor: _cardBg(isDark),
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: _textPrimary(isDark)),
                      items: providerOptions
                          .map((p) => DropdownMenuItem(
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
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox(
                                                width: 20, height: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(p['name']!,
                                        style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            color: _textPrimary(isDark))),
                                  ],
                                ),
                              ))
                          .toList(),
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
                      color: isDark
                          ? const Color(0xFF1A1030)
                          : const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark
                              ? const Color(0xFF3D2A6E)
                              : const Color(0xFFBAE6FD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: Color(0xFF8B5CF6)),
                            const SizedBox(width: 6),
                            Text(
                              'Recommended for beginners',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8B5CF6)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'OpenRouter gives you free access to many models. '
                          'Add \$10 credit for higher rate limits and access to premium models.',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : const Color(0xFF4B5563),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () => launchUrl(
                                Uri.parse('https://openrouter.ai/keys'),
                                mode: LaunchMode.externalApplication),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Get OpenRouter API Key \u2192',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, fontWeight: FontWeight.w600),
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
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary(isDark)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _apiKeyController,
                  obscureText: !_isKeyVisible,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: _textPrimary(isDark)),
                  onChanged: (_) {
                    if (_keyError != null) setState(() => _keyError = null);
                  },
                  decoration: InputDecoration(
                    hintText: 'Paste your $_selectedProvider API key',
                    hintStyle: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : const Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: _inputBg(isDark),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: _keyError != null
                              ? AppColors.error
                              : _inputBorder(isDark)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: _keyError != null
                              ? AppColors.error
                              : _inputBorder(isDark)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.persian, width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _isKeyVisible = !_isKeyVisible),
                      icon: Icon(
                        _isKeyVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: _subtitleColor(isDark),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                if (_keyError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _keyError!,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => OllamaSetupSheet.show(context),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: _subtitleColor(isDark)),
                      const SizedBox(width: 6),
                      Text(
                        'Or use Ollama locally (no key needed)',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.persian),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 7: Pricing (Free + Pro only) ──────────────────────────────────────
  Widget _buildPagePricing(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _animatedContent(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(isDark),
            child: Column(
              children: [
                Text(
                  'Choose your plan',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick what works for you. Cancel anytime.',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: _subtitleColor(isDark)),
                ),
                const SizedBox(height: 16),
                _buildBillingToggle(isDark),
                const SizedBox(height: 16),
                // Two plan cards stacked on mobile
                _selectablePlanCard(
                  id: 'free',
                  title: 'Free',
                  price: '\$0',
                  isDark: isDark,
                  features: [
                    '${AppConstants.freeTokenCapDisplay} tokens/5hr',
                    '${AppConstants.freeDeviceLimit} device',
                    'Community models',
                    'Basic chat',
                  ],
                ),
                const SizedBox(height: 12),
                _selectablePlanCard(
                  id: 'pro',
                  title: 'Pro',
                  price: _isAnnualOnboarding
                      ? '\$${AppConstants.basicAnnualPrice ~/ 12}/mo'
                      : '\$${AppConstants.basicMonthlyPrice.toStringAsFixed(2)}/mo',
                  isDark: isDark,
                  badge: 'Try ${AppConstants.trialDurationDays} days free',
                  features: [
                    '${AppConstants.basicTokenCapDisplay} tokens/day',
                    '${AppConstants.basicDeviceLimit} devices',
                    'Cross sync',
                    'iCloud & Google Drive',
                    'All providers',
                    'File uploads',
                    'Voice input',
                  ],
                ),
                if (_selectedPlan != null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        _selectedPlan == 'free'
                            ? 'Continue with Free'
                            : 'Try ${AppConstants.trialDurationDays} days free',
                        style: GoogleFonts.dmSans(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: !_isAnnualOnboarding
                ? _textPrimary(isDark)
                : _subtitleColor(isDark),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () =>
              setState(() => _isAnnualOnboarding = !_isAnnualOnboarding),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 26,
            decoration: BoxDecoration(
              color: _isAnnualOnboarding
                  ? AppColors.persian
                  : _inputBorder(isDark),
              borderRadius: BorderRadius.circular(13),
            ),
            padding: const EdgeInsets.all(2),
            child: AnimatedAlign(
              alignment: _isAnnualOnboarding
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
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
            color: _isAnnualOnboarding
                ? _textPrimary(isDark)
                : _subtitleColor(isDark),
          ),
        ),
        if (_isAnnualOnboarding) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-20%',
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success),
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
    required bool isDark,
    required List<String> features,
    String? badge,
  }) {
    final isSelected = _selectedPlan == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.persian.withOpacity(isDark ? 0.1 : 0.05)
              : _inputBg(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.persian : _inputBorder(isDark),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.dmSerifDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary(isDark)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        price,
                        style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary(isDark)),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: features
                        .map((f) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check,
                                    size: 12, color: AppColors.persian),
                                const SizedBox(width: 4),
                                Text(
                                  f,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: _subtitleColor(isDark)),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.check_circle,
                    size: 22, color: AppColors.persian),
              ),
          ],
        ),
      ),
    );
  }

  // ── Step 8: Ready (Celebration!) ───────────────────────────────────────────
  Widget _buildPageReady(bool isDark) {
    return _animatedContent(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated mascot with glow
            AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, child) {
                final scale =
                    1.0 + 0.05 * math.sin(_celebrationController.value * math.pi * 2);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.persian.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const ShakingHands(size: 120, animate: true),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _getReadyText(),
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: isDark ? AppColors.darkTextPrimary : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _cardBg(isDark).withOpacity(isDark ? 0.8 : 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Your AI assistant is ready. No yapping.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: _textPrimary(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Confetti painter ─────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter({required this.progress});

  static final List<_Particle> _particles = List.generate(50, (i) {
    final rng = math.Random(i);
    return _Particle(
      x: rng.nextDouble(),
      startY: -0.1 - rng.nextDouble() * 0.3,
      speed: 0.3 + rng.nextDouble() * 0.7,
      drift: (rng.nextDouble() - 0.5) * 0.3,
      size: 3 + rng.nextDouble() * 5,
      rotation: rng.nextDouble() * math.pi * 2,
      color: [
        const Color(0xFFCC5801), // Persian Orange
        const Color(0xFF22C55E), // Green
        const Color(0xFF3B82F6), // Blue
        const Color(0xFFF59E0B), // Amber
        const Color(0xFFEC4899), // Pink
        const Color(0xFF8B5CF6), // Purple
      ][i % 6],
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.01) return;
    for (final p in _particles) {
      final y = (p.startY + progress * p.speed) * size.height;
      if (y > size.height || y < -20) continue;
      final x = (p.x +
              math.sin(progress * math.pi * 4 + p.rotation) * p.drift) *
          size.width;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * math.pi * 2);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        Paint()..color = p.color.withOpacity(opacity * 0.8),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

class _Particle {
  final double x;
  final double startY;
  final double speed;
  final double drift;
  final double size;
  final double rotation;
  final Color color;
  const _Particle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.drift,
    required this.size,
    required this.rotation,
    required this.color,
  });
}
