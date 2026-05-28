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
  late final AnimationController _shimmerController;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _loadRegion();
    _pageEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
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
    _shimmerController.dispose();
    _floatController.dispose();
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
    if (_currentPage == 4) _savePreferences();
    if (_currentPage == 5 && _apiKeyController.text.isNotEmpty) _saveApiKey();
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    } else {
      _completeOnboarding();
    }
  }

  void _skipToReady() => _goToPage(_totalPages - 1);

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_preferences', _selectedPreferences.join(','));
  }

  Future<void> _saveName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_first_name', _firstNameCtrl.text.trim());
    await prefs.setString('user_last_name', _lastNameCtrl.text.trim());
  }

  Future<void> _saveApiKey() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'pending_api_key', value: _apiKeyController.text);
  }

  Future<void> _completeOnboarding() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'onboarding_complete', value: 'true');
    if (mounted) context.go(AppRoutes.chat);
  }

  String get _firstName => _firstNameCtrl.text.trim();

  String _getReadyText() {
    final name = _firstName;
    final greeting =
        name.isNotEmpty ? "You're all set, $name!" : "You're all set!";
    if (_selectedPreferences.contains('Coding')) return '$greeting\nLet\u2019s code.';
    if (_selectedPreferences.contains('Writing')) return '$greeting\nLet\u2019s write.';
    if (_selectedPreferences.length > 1) return '$greeting\nLet\u2019s create.';
    return '$greeting\nLet\u2019s go.';
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Color _cardBg(bool d) => d ? const Color(0xFF141414) : Colors.white;
  Color _cardBorder(bool d) =>
      d ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6);
  Color _sub(bool d) => d ? AppColors.darkTextSecondary : const Color(0xFF6B7280);
  Color _txt(bool d) => d ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color _inBg(bool d) => d ? AppColors.darkInputBg : const Color(0xFFF9FAFB);
  Color _inBorder(bool d) =>
      d ? AppColors.darkInputBorder : const Color(0xFFE5E7EB);

  BoxDecoration _glass(bool d) => BoxDecoration(
        color: d
            ? _cardBg(d).withOpacity(0.88)
            : _cardBg(d).withOpacity(0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder(d)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(d ? 0.4 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          if (!d)
            BoxShadow(
              color: Colors.white.withOpacity(0.5),
              blurRadius: 0,
              spreadRadius: 0,
              offset: const Offset(0, -1),
            ),
        ],
      );

  Widget _animatedContent({required Widget child, double extraDelay = 0}) {
    final fade = CurvedAnimation(
      parent: _pageEntranceController,
      curve: Interval(extraDelay, (0.6 + extraDelay).clamp(0.0, 1.0),
          curve: Curves.easeOut),
    );
    final slide = CurvedAnimation(
      parent: _pageEntranceController,
      curve: Interval(extraDelay, (0.7 + extraDelay).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: _pageEntranceController,
      builder: (context, _) => Opacity(
        opacity: fade.value,
        child: Transform.translate(
          offset: Offset(0, 28 * (1 - slide.value)),
          child: Transform.scale(
            scale: 0.96 + 0.04 * slide.value,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _stepLabel(String text, bool isDark) {
    return _animatedContent(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.persian.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppColors.persian,
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_ready) {
      return Scaffold(
          backgroundColor:
              isDark ? AppColors.darkBgPrimary : const Color(0xFFB8E4F9));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Snow mountains background with subtle parallax float
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -4 + 8 * _floatController.value),
                child: child,
              ),
              child: Image.asset(
                'assets/images/sky_clouds.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (isDark)
            Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.55))),
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
                          child: _animatedContent(
                            extraDelay: 0.3,
                            child: TextButton(
                              onPressed: _skipToReady,
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    _cardBg(isDark).withOpacity(0.85),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                              child: Text(
                                'Skip',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _sub(isDark),
                                ),
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
          // Celebration
          if (_currentPage == _totalPages - 1)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _celebrationController,
                  builder: (context, _) => CustomPaint(
                    painter:
                        _ConfettiPainter(progress: _celebrationController.value),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomArea(bool isDark) {
    return _animatedContent(
      extraDelay: 0.2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress dots with completion state
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (i) {
                final isActive = i == _currentPage;
                final isDone = i < _currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: isActive ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isActive
                          ? AppColors.persian
                          : isDone
                              ? AppColors.persian.withOpacity(0.45)
                              : (isDark
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.white.withOpacity(0.5)),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            if (_currentPage != 6)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: _currentPage == _totalPages - 1
                      ? _ShimmerButton(
                          controller: _shimmerController,
                          onPressed: _nextPage,
                          label: "Let\u2019s go \u2192",
                        )
                      : ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.persian,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Continue',
                            style: GoogleFonts.dmSans(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                ),
              ),
            const SizedBox(height: 8),
            if (_currentPage > 0)
              TextButton(
                onPressed: () => _goToPage(_currentPage - 1),
                style: TextButton.styleFrom(
                  backgroundColor: _cardBg(isDark).withOpacity(0.6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  '\u2190 Back',
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _txt(isDark)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1 — Welcome / Name
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPageName(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floating mascot with soft glow
            _animatedContent(
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -3 + 6 * _floatController.value),
                  child: child,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.persian.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const ShakingHands(size: 72, animate: true),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _animatedContent(
              extraDelay: 0.1,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(28),
                decoration: _glass(isDark),
                child: Column(
                  children: [
                    Text(
                      _firstName.isNotEmpty
                          ? 'Hey, $_firstName \u{1F44B}'
                          : 'Welcome \u{1F44B}',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _txt(isDark),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let\u2019s set up your AI in 60 seconds',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: _sub(isDark)),
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
                        setState(() {}); // refresh greeting
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
                      Text(_nameError!,
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.error)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.persian,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text('Get started',
                            style: GoogleFonts.dmSans(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
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
      style: GoogleFonts.dmSans(fontSize: 15, color: _txt(isDark)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
            fontSize: 15,
            color: isDark ? AppColors.darkTextMuted : const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: _inBg(isDark),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _inBorder(isDark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _inBorder(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.persian, width: 1.5),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2 — The Problem (other AIs yap)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPageProblem(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            _stepLabel('THE PROBLEM', isDark),
            const SizedBox(height: 16),
            _animatedContent(
              extraDelay: 0.05,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(24),
                decoration: _glass(isDark),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Other AIs be like...',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _txt(isDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _chatBubble(
                      "What's the capital of France?",
                      isUser: true,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _chatBubble(
                      "Great question! I'd be happy to help you with that! "
                      "So, the capital of France is a fascinating topic. "
                      "France, officially known as the French Republic, is a country "
                      "located in Western Europe. Its capital city, which has been the "
                      "center of French culture, politics, and economics for centuries, "
                      "is Paris. I hope that helps! \u{1F60A}",
                      isUser: false,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '\u{1F634} You fell asleep reading that.',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatBubble(String text,
      {required bool isUser, required bool isDark}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: isUser ? 260 : 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.persian
              : (isDark
                  ? AppColors.darkBgSecondary
                  : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: isUser ? Colors.white : _txt(isDark),
            height: 1.45,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 3 — The Solution (Mio is direct)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPageSolution(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            _stepLabel('THE SOLUTION', isDark),
            const SizedBox(height: 16),
            _animatedContent(
              extraDelay: 0.05,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(24),
                decoration: _glass(isDark),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ShakingHands(size: 28, animate: false),
                          const SizedBox(width: 8),
                          Text(
                            'Mio be like...',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _txt(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _chatBubble("What's the capital of France?",
                        isUser: true, isDark: isDark),
                    const SizedBox(height: 12),
                    _chatBubble('Paris.',
                        isUser: false, isDark: isDark),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '\u{26A1} Direct. Fast. No yapping.',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.persian,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...['Your keys, your models', 'Switch providers anytime',
                        'No markup on tokens', 'Run local with Ollama']
                        .asMap()
                        .entries
                        .map((e) => _featureRow(
                            '${e.key + 1}', e.value, isDark)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: ['No filler', 'Straight answers', 'Your keys']
                          .map((l) => _pill(l, isDark))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _inBorder(isDark)),
        color: isDark ? AppColors.darkBgSecondary : null,
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(fontSize: 12, color: _sub(isDark))),
    );
  }

  Widget _featureRow(String number, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.persian.withOpacity(0.15),
                  AppColors.persian.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.persian)),
            ),
          ),
          const SizedBox(width: 12),
          Text(text,
              style: GoogleFonts.dmSans(fontSize: 14, color: _txt(isDark))),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 4 — BYOK
  // ══════════════════════════════════════════════════════════════════════════
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
        child: Column(
          children: [
            _stepLabel('YOUR KEYS', isDark),
            const SizedBox(height: 16),
            _animatedContent(
              extraDelay: 0.05,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(24),
                decoration: _glass(isDark),
                child: Column(
                  children: [
                    Text(
                      'Your AI. Your keys.',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _txt(isDark),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bring your own API keys \u2014 zero markup.',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: _sub(isDark)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Animated provider grid
                    Wrap(
                      spacing: 14,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        ...providers.asMap().entries.map((e) =>
                            _providerChip(e.value, isDark, e.key)),
                        _moreChip(isDark),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Why BYOK comparison
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _inBg(isDark),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _inBorder(isDark)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified_rounded,
                                  size: 16, color: AppColors.persian),
                              const SizedBox(width: 6),
                              Text('Why BYOK?',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _txt(isDark))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...[
                            'Access latest models instantly',
                            'No rate limits from us',
                            'Use local models (Ollama)',
                            'Switch providers anytime',
                          ].map((t) => _checkRow(t, true, isDark)),
                          const SizedBox(height: 8),
                          Divider(color: _inBorder(isDark)),
                          const SizedBox(height: 4),
                          Text('Locked platforms:',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _sub(isDark))),
                          const SizedBox(height: 6),
                          ...[
                            'Stuck on old models',
                            'Heavy rate limits',
                            'Markup on every token',
                          ].map((t) => _checkRow(t, false, isDark)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _providerChip(Map<String, String> p, bool isDark, int index) {
    return _animatedContent(
      extraDelay: 0.05 + index * 0.03,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBgSecondary : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Image.asset(
                    p['asset']!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(p['name']![0],
                          style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.persian)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(p['name']!,
                style:
                    GoogleFonts.dmSans(fontSize: 10, color: _sub(isDark)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _moreChip(bool isDark) {
    return SizedBox(
      width: 68,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgTertiary : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
              border: Border.all(color: _inBorder(isDark)),
            ),
            child: Icon(Icons.more_horiz, color: _sub(isDark), size: 22),
          ),
          const SizedBox(height: 5),
          Text('& more',
              style: GoogleFonts.dmSans(fontSize: 10, color: _sub(isDark)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _checkRow(String text, bool positive, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            positive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 15,
            color: positive ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: positive ? _txt(isDark) : _sub(isDark))),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 5 — Preferences (2-col grid)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPagePreferences(bool isDark) {
    const items = [
      {'label': 'Coding', 'icon': Icons.code, 'emoji': '\u{1F4BB}'},
      {'label': 'Writing', 'icon': Icons.edit_note, 'emoji': '\u{270F}\u{FE0F}'},
      {'label': 'Learning', 'icon': Icons.school, 'emoji': '\u{1F4DA}'},
      {'label': 'Work', 'icon': Icons.work_outline, 'emoji': '\u{1F4BC}'},
      {'label': 'Creative', 'icon': Icons.palette_outlined, 'emoji': '\u{1F3A8}'},
      {'label': 'Research', 'icon': Icons.science_outlined, 'emoji': '\u{1F52C}'},
      {'label': 'Chat', 'icon': Icons.chat_bubble_outline, 'emoji': '\u{1F4AC}'},
      {'label': 'Math', 'icon': Icons.calculate_outlined, 'emoji': '\u{1F9EE}'},
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            _stepLabel('PERSONALIZE', isDark),
            const SizedBox(height: 16),
            _animatedContent(
              extraDelay: 0.05,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(24),
                decoration: _glass(isDark),
                child: Column(
                  children: [
                    Text(
                      'What do you use AI for?',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _txt(isDark),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text('Pick your superpowers',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: _sub(isDark))),
                    const SizedBox(height: 20),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.6,
                      children: items.map((item) {
                        final label = item['label'] as String;
                        final emoji = item['emoji'] as String;
                        final isSelected =
                            _selectedPreferences.contains(label);
                        return GestureDetector(
                          onTap: () => setState(() {
                            isSelected
                                ? _selectedPreferences.remove(label)
                                : _selectedPreferences.add(label);
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.persian.withOpacity(0.1)
                                  : _inBg(isDark),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.persian
                                    : _inBorder(isDark),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            AppColors.persian.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.persian
                                          : _txt(isDark),
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
                    if (_selectedPreferences.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.persian.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\u{2728} ${_selectedPreferences.length} selected \u2014 we\u2019ll tailor your experience',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.persian,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 6 — Add API Key
  // ══════════════════════════════════════════════════════════════════════════
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
        child: Column(
          children: [
            _stepLabel('CONNECT', isDark),
            const SizedBox(height: 16),
            _animatedContent(
              extraDelay: 0.05,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: _glass(isDark),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text('Add your API key',
                          style: GoogleFonts.dmSerifDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _txt(isDark))),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text('Choose a provider and paste your key',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: _sub(isDark))),
                    ),
                    const SizedBox(height: 20),
                    Text('Provider',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _txt(isDark))),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _inBg(isDark),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _inBorder(isDark)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedProvider,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down,
                              color: _sub(isDark)),
                          dropdownColor: _cardBg(isDark),
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: _txt(isDark)),
                          items: providerOptions
                              .map((p) => DropdownMenuItem(
                                    value: p['name']!,
                                    child: Row(children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        child: Image.asset(p['asset']!,
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox(
                                                    width: 20, height: 20)),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(p['name']!,
                                          style: GoogleFonts.dmSans(
                                              fontSize: 14,
                                              color: _txt(isDark))),
                                    ]),
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
                    if (_selectedProvider == 'OpenRouter') ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A1030)
                              : const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isDark
                                  ? const Color(0xFF3D2A6E)
                                  : const Color(0xFFBAE6FD)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  size: 16, color: Color(0xFF8B5CF6)),
                              const SizedBox(width: 6),
                              Text('Recommended for beginners',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF8B5CF6))),
                            ]),
                            const SizedBox(height: 6),
                            Text(
                                'Free access to many models. Add \$10 for premium.',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: _sub(isDark),
                                    height: 1.4)),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () => launchUrl(
                                    Uri.parse('https://openrouter.ai/keys'),
                                    mode: LaunchMode.externalApplication),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5CF6),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                child: Text('Get OpenRouter Key \u2192',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text('API Key',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _txt(isDark))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: !_isKeyVisible,
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: _txt(isDark)),
                      onChanged: (_) {
                        if (_keyError != null) {
                          setState(() => _keyError = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Paste your $_selectedProvider API key',
                        hintStyle: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : const Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: _inBg(isDark),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: _keyError != null
                                    ? AppColors.error
                                    : _inBorder(isDark))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: _keyError != null
                                    ? AppColors.error
                                    : _inBorder(isDark))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.persian, width: 1.5)),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _isKeyVisible = !_isKeyVisible),
                          icon: Icon(
                            _isKeyVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: _sub(isDark),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    if (_keyError != null) ...[
                      const SizedBox(height: 6),
                      Text(_keyError!,
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.error)),
                    ],
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => OllamaSetupSheet.show(context),
                      child: Row(children: [
                        Icon(Icons.computer,
                            size: 14, color: _sub(isDark)),
                        const SizedBox(width: 6),
                        Text('Or run locally with Ollama',
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: AppColors.persian)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 7 — Pricing (make Pro irresistible)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPagePricing(bool isDark) {
    final proPrice = _isAnnualOnboarding
        ? '\$${(AppConstants.basicAnnualPrice / 12).toStringAsFixed(2)}/mo'
        : '\$${AppConstants.basicMonthlyPrice.toStringAsFixed(2)}/mo';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            _stepLabel('CHOOSE YOUR PLAN', isDark),
            const SizedBox(height: 16),
            _animatedContent(
              extraDelay: 0.05,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(24),
                decoration: _glass(isDark),
                child: Column(
                  children: [
                    Text('Unlock the full experience',
                        style: GoogleFonts.dmSerifDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _txt(isDark)),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text('Cancel anytime. No questions asked.',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: _sub(isDark))),
                    const SizedBox(height: 16),
                    _buildBillingToggle(isDark),
                    const SizedBox(height: 20),

                    // ── Pro card (featured, first) ──
                    GestureDetector(
                      onTap: () => setState(() => _selectedPlan = 'pro'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: _selectedPlan == 'pro'
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.persian.withOpacity(0.12),
                                    AppColors.persian.withOpacity(0.04),
                                  ],
                                )
                              : null,
                          color: _selectedPlan == 'pro'
                              ? null
                              : _inBg(isDark),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedPlan == 'pro'
                                ? AppColors.persian
                                : _inBorder(isDark),
                            width: _selectedPlan == 'pro' ? 2 : 1,
                          ),
                          boxShadow: _selectedPlan == 'pro'
                              ? [
                                  BoxShadow(
                                    color:
                                        AppColors.persian.withOpacity(0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.persian,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('PRO',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 1)),
                                ),
                                const SizedBox(width: 10),
                                Text(proPrice,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: _txt(isDark))),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                      '${AppConstants.trialDurationDays}-day free trial',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success)),
                                ),
                                if (_selectedPlan == 'pro') ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check_circle,
                                      size: 22, color: AppColors.persian),
                                ],
                              ],
                            ),
                            const SizedBox(height: 14),
                            _proFeature(
                                Icons.bolt_rounded,
                                '${AppConstants.basicTokenCapDisplay} tokens/day',
                                isDark),
                            _proFeature(
                                Icons.devices_rounded,
                                '${AppConstants.basicDeviceLimit} devices with sync',
                                isDark),
                            _proFeature(Icons.cloud_upload_rounded,
                                'File uploads & voice input', isDark),
                            _proFeature(Icons.sync_rounded,
                                'iCloud & Google Drive', isDark),
                            _proFeature(Icons.hub_rounded,
                                'All AI providers', isDark),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Free card (minimal) ──
                    GestureDetector(
                      onTap: () => setState(() => _selectedPlan = 'free'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedPlan == 'free'
                              ? _inBg(isDark)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedPlan == 'free'
                                ? _txt(isDark).withOpacity(0.3)
                                : _inBorder(isDark),
                            width: _selectedPlan == 'free' ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text('Free',
                                style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: _sub(isDark))),
                            const SizedBox(width: 8),
                            Text('\u2014 ${AppConstants.freeTokenCapDisplay} tokens/5hr, 1 device',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12, color: _sub(isDark))),
                            const Spacer(),
                            if (_selectedPlan == 'free')
                              Icon(Icons.check_circle,
                                  size: 20,
                                  color: _txt(isDark).withOpacity(0.5)),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedPlan != null) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: _selectedPlan == 'pro'
                            ? _ShimmerButton(
                                controller: _shimmerController,
                                onPressed: () {
                                  _completeOnboarding();
                                  context.go(AppRoutes.subscription);
                                },
                                label:
                                    'Start ${AppConstants.trialDurationDays}-day free trial \u2192',
                              )
                            : ElevatedButton(
                                onPressed: () =>
                                    _goToPage(_totalPages - 1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isDark ? Colors.white : AppColors.textPrimary,
                                  foregroundColor:
                                      isDark ? Colors.black : Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: Text('Continue with Free',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _proFeature(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.persian),
          const SizedBox(width: 10),
          Text(text,
              style: GoogleFonts.dmSans(fontSize: 13, color: _txt(isDark))),
        ],
      ),
    );
  }

  Widget _buildBillingToggle(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Monthly',
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: !_isAnnualOnboarding ? _txt(isDark) : _sub(isDark))),
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
                  : _inBorder(isDark),
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
                    color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('Annual',
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _isAnnualOnboarding ? _txt(isDark) : _sub(isDark))),
        if (_isAnnualOnboarding) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Save 20%',
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success)),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 8 — Ready (celebration!)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPageReady(bool isDark) {
    return _animatedContent(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing mascot with glow
            AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, child) {
                final bounce = math.sin(
                        _celebrationController.value * math.pi * 3) *
                    0.04;
                return Transform.scale(
                    scale: 1.0 + bounce, child: child);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.persian.withOpacity(0.25),
                      blurRadius: 50,
                      spreadRadius: 10,
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
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: isDark ? AppColors.darkTextPrimary : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _cardBg(isDark).withOpacity(isDark ? 0.8 : 0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder(isDark)),
              ),
              child: Text(
                'Your AI assistant is ready. No yapping. \u{26A1}',
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _txt(isDark)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shimmer CTA button — draws attention to Pro actions
// ══════════════════════════════════════════════════════════════════════════════
class _ShimmerButton extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onPressed;
  final String label;
  const _ShimmerButton({
    required this.controller,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * controller.value, 0),
              end: Alignment(1.0 + 2.0 * controller.value, 0),
              colors: const [
                AppColors.persian,
                Color(0xFFE87020),
                AppColors.persian,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.persian.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Confetti painter
// ══════════════════════════════════════════════════════════════════════════════
class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter({required this.progress});

  static final List<_Particle> _particles = List.generate(60, (i) {
    final rng = math.Random(i);
    return _Particle(
      x: rng.nextDouble(),
      startY: -0.1 - rng.nextDouble() * 0.4,
      speed: 0.25 + rng.nextDouble() * 0.6,
      drift: (rng.nextDouble() - 0.5) * 0.3,
      size: 3 + rng.nextDouble() * 6,
      rotation: rng.nextDouble() * math.pi * 2,
      color: [
        const Color(0xFFCC5801),
        const Color(0xFF22C55E),
        const Color(0xFF3B82F6),
        const Color(0xFFF59E0B),
        const Color(0xFFEC4899),
        const Color(0xFF8B5CF6),
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
      final opacity = (1.0 - progress * 0.7).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * math.pi * 3);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.5),
        Paint()..color = p.color.withOpacity(opacity * 0.85),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

class _Particle {
  final double x, startY, speed, drift, size, rotation;
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
