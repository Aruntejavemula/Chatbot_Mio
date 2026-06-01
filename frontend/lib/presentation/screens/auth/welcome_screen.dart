import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/common/shaking_hands.dart';

enum _AuthMode { signIn, signUp, forgot }

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  _AuthMode _mode = _AuthMode.signIn;
  bool _isLoading = false;
  bool _isLoadingGoogle = false;
  bool _isLoadingApple = false;
  bool _forgotSent = false;
  bool _obscurePassword = true;

  late final AnimationController _entranceController;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _showApple {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  void _switchMode(_AuthMode m) {
    setState(() {
      _mode = m;
      _forgotSent = false;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoadingGoogle = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle('');
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoadingApple = true);
    try {
      await ref.read(authRepositoryProvider).signInWithApple('');
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingApple = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      if (_mode == _AuthMode.forgot) {
        await repo.forgotPassword(_emailCtrl.text.trim());
        if (mounted) setState(() => _forgotSent = true);
        return;
      }
      if (_mode == _AuthMode.signUp) {
        await repo.signUpWithEmail(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
        if (mounted) {
          context.go(
              '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(_emailCtrl.text.trim())}');
        }
      } else {
        await repo.signInWithEmail(
            email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
        if (mounted) context.go(AppRoutes.chat);
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data is Map
            ? (e.response!.data as Map)['detail']?.toString() ??
                'Something went wrong'
            : 'Something went wrong';
        _showError(msg);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Widget _staggered({required double delay, required Widget child}) {
    final begin = delay;
    final end = (delay + 0.4).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - curved.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 840;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: isWide
          ? Row(
              children: [
                Expanded(child: _leftPane(isDark)),
                Expanded(
                    child: _InteractiveRightPanel(
                        entrance: _entranceController)),
              ],
            )
          : SafeArea(
              child: Center(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 48),
                    child: _mobileContent(isDark),
                  ),
                ),
              ),
            ),
    );
  }

  // ── Mobile layout (Claude-style centered) ──────────────────────────────────
  Widget _mobileContent(bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _staggered(
            delay: 0.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const ShakingHands(size: 48, animate: false),
                const SizedBox(width: 12),
                Text(
                  AppStrings.appName,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 36,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _staggered(
            delay: 0.1,
            child: Text(
              _headlineForMode,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 30,
                height: 1.25,
                letterSpacing: -0.5,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 40),
          _staggered(delay: 0.25, child: _authSection(isDark)),
          const SizedBox(height: 32),
          _staggered(delay: 0.5, child: _legalText(isDark)),
        ],
      ),
    );
  }

  // ── Desktop left pane ──────────────────────────────────────────────────────
  Widget _leftPane(bool isDark) {
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    return Container(
      color: bg,
      child: SafeArea(
        child: Center(
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _staggered(
                      delay: 0.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ShakingHands(size: 44, animate: false),
                          const SizedBox(width: 10),
                          Text(
                            AppStrings.appName,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 28,
                              color: AppColors.persian,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 64),
                    _staggered(
                      delay: 0.1,
                      child: Text(
                        _headlineForMode,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 34,
                          height: 1.2,
                          letterSpacing: -0.5,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _staggered(
                      delay: 0.15,
                      child: Text(
                        _subtitleForMode,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          height: 1.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    _staggered(delay: 0.25, child: _authSection(isDark)),
                    const SizedBox(height: 32),
                    _staggered(delay: 0.5, child: _legalText(isDark)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _headlineForMode {
    switch (_mode) {
      case _AuthMode.signIn:
        return 'Think faster,\nbuild smarter';
      case _AuthMode.signUp:
        return 'Start thinking\nwith ${AppStrings.appName}';
      case _AuthMode.forgot:
        return 'Reset your\npassword';
    }
  }

  String get _subtitleForMode {
    switch (_mode) {
      case _AuthMode.signIn:
        return 'Your AI that cuts through the noise \u2014 focused, fast, no filler.';
      case _AuthMode.signUp:
        return 'Join thousands who think better with ${AppStrings.appName} by their side.';
      case _AuthMode.forgot:
        return 'A fresh start is one link away.';
    }
  }

  // ── Auth section (shared mobile/desktop) ───────────────────────────────────
  Widget _authSection(bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_mode != _AuthMode.forgot) ...[
            _socialButton(
              label: _mode == _AuthMode.signUp
                  ? 'Sign up with Google'
                  : AppStrings.continueGoogle,
              icon: SizedBox(
                  width: 20,
                  height: 20,
                  child: CustomPaint(painter: _GooglePainter())),
              isLoading: _isLoadingGoogle,
              onTap: _signInWithGoogle,
              isDark: isDark,
              filled: true,
            ),
            if (_showApple) ...[
              const SizedBox(height: 12),
              _socialButton(
                label: AppStrings.continueApple,
                icon: Icon(Icons.apple,
                    size: 22,
                    color: isDark ? Colors.black : Colors.white),
                isLoading: _isLoadingApple,
                onTap: _signInWithApple,
                isDark: isDark,
                filled: true,
              ),
            ],
            const SizedBox(height: 20),
            _orDivider(isDark),
            const SizedBox(height: 20),
          ],
          if (_mode == _AuthMode.signUp) ...[
            _inputField(
              ctrl: _nameCtrl,
              hint: 'Your full name',
              isDark: isDark,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
          ],
          _inputField(
            ctrl: _emailCtrl,
            hint: 'Personal or work email',
            isDark: isDark,
            keyboardType: TextInputType.emailAddress,
            onSubmit: _mode == _AuthMode.forgot ? _submit : null,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                return 'Invalid email';
              }
              return null;
            },
          ),
          if (_mode != _AuthMode.forgot) ...[
            const SizedBox(height: 14),
            _inputField(
              ctrl: _passwordCtrl,
              hint: 'Password',
              isDark: isDark,
              obscureText: _obscurePassword,
              onSubmit: _submit,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 8) return 'Min 8 characters';
                return null;
              },
            ),
            if (_mode == _AuthMode.signIn) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _switchMode(_AuthMode.forgot),
                  child: Text('Forgot password?',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppColors.persian)),
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          if (_forgotSent)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Reset link sent \u2014 check your inbox.',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: const Color(0xFF065F46))),
            )
          else
            _submitButton(isDark),
          const SizedBox(height: 20),
          _switchModeRow(textPrimary, textMuted),
        ],
      ),
    );
  }

  Widget _socialButton({
    required String label,
    required Widget icon,
    required bool isLoading,
    required VoidCallback onTap,
    required bool isDark,
    bool filled = false,
  }) {
    final bgColor = isDark ? Colors.white : const Color(0xFF1A1814);
    final textColor = isDark ? Colors.black : Colors.white;
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: textColor))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Text(label,
                      style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
      ),
    );
  }

  Widget _submitButton(bool isDark) {
    final label = _mode == _AuthMode.signIn
        ? 'Sign In'
        : _mode == _AuthMode.signUp
            ? 'Create Account'
            : 'Send Reset Link';
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.persian,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController ctrl,
    required String hint,
    required bool isDark,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffix,
    VoidCallback? onSubmit,
  }) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final inputBg = isDark ? AppColors.darkInputBg : Colors.white;
    final border =
        isDark ? AppColors.darkInputBorder : const Color(0xFFE8E4DE);
    final focusBorder =
        isDark ? AppColors.darkInputFocusBorder : AppColors.textPrimary;

    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction:
          onSubmit != null ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: onSubmit != null ? (_) => onSubmit() : null,
      style: GoogleFonts.dmSans(fontSize: 15, color: textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(fontSize: 15, color: textMuted),
        filled: true,
        fillColor: inputBg,
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: focusBorder)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lightError)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lightError)),
      ),
    );
  }

  Widget _orDivider(bool isDark) {
    final border =
        isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final text = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Row(children: [
      Expanded(child: Divider(color: border, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('OR',
            style: GoogleFonts.dmSans(
                fontSize: 12, letterSpacing: 0.5, color: text)),
      ),
      Expanded(child: Divider(color: border, thickness: 1)),
    ]);
  }

  Widget _switchModeRow(Color textPrimary, Color textMuted) {
    if (_mode == _AuthMode.signIn) {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text("Don't have an account? ",
            style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
        GestureDetector(
          onTap: () => _switchMode(_AuthMode.signUp),
          child: Text('Sign up',
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  decoration: TextDecoration.underline)),
        ),
      ]);
    } else if (_mode == _AuthMode.signUp) {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Already have an account? ',
            style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
        GestureDetector(
          onTap: () => _switchMode(_AuthMode.signIn),
          child: Text('Log in',
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  decoration: TextDecoration.underline)),
        ),
      ]);
    } else {
      return Center(
        child: GestureDetector(
          onTap: () => _switchMode(_AuthMode.signIn),
          child: Text('\u2190 Back to sign in',
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: textPrimary,
                  decoration: TextDecoration.underline)),
        ),
      );
    }
  }

  Widget _legalText(bool isDark) {
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final linkColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.dmSans(fontSize: 12, color: textMuted),
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
                text: 'Terms',
                style: TextStyle(
                    color: linkColor,
                    decoration: TextDecoration.underline)),
            const TextSpan(text: ' and '),
            TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(
                    color: linkColor,
                    decoration: TextDecoration.underline)),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Interactive right panel — living chat mockup with smooth Apple-level slides
// ══════════════════════════════════════════════════════════════════════════════
class _InteractiveRightPanel extends StatefulWidget {
  final AnimationController entrance;
  const _InteractiveRightPanel({required this.entrance});

  @override
  State<_InteractiveRightPanel> createState() => _InteractiveRightPanelState();
}

class _InteractiveRightPanelState extends State<_InteractiveRightPanel>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  int _currentConversation = 0;
  Timer? _cycleTimer;

  static const _conversations = [
    _ConversationData(
      userMessage: "Help me write a product launch email",
      aiMessage:
          "Here\u2019s a compelling launch email that highlights your key value props, creates urgency, and includes a clear CTA...",
      topic: "Writing",
    ),
    _ConversationData(
      userMessage: "Explain quantum computing simply",
      aiMessage:
          "Think of regular computers as light switches \u2014 on or off. Quantum computers are like dimmer switches that can be anywhere in between...",
      topic: "Learning",
    ),
    _ConversationData(
      userMessage: "Debug this React useEffect hook",
      aiMessage:
          "The issue is a missing dependency in your effect. Adding the callback to the deps array and wrapping it with useCallback will fix the infinite re-render...",
      topic: "Coding",
    ),
    _ConversationData(
      userMessage: "Create a workout plan for beginners",
      aiMessage:
          "Week 1-2: Foundation phase. 3 days/week, alternating push-pull-legs. Start with bodyweight movements before adding resistance...",
      topic: "Health",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _cycleTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _currentConversation =
              (_currentConversation + 1) % _conversations.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conversation = _conversations[_currentConversation];

    final panelEntrance = CurvedAnimation(
      parent: widget.entrance,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: panelEntrance,
      builder: (context, child) => Opacity(
        opacity: panelEntrance.value,
        child: Transform.translate(
          offset: Offset(40 * (1 - panelEntrance.value), 0),
          child: child,
        ),
      ),
      child: Stack(
        children: [
          // Same snow mountains background as onboarding
          Positioned.fill(
            child: Image.asset(
              'assets/images/sky_clouds.png',
              fit: BoxFit.cover,
            ),
          ),
          if (isDark)
            Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: 0.55))),
          Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Topic pill — smooth crossfade
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.92, end: 1.0).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Container(
                    key: ValueKey('topic-${conversation.topic}'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.persian.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      conversation.topic,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.persian,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Chat card — smooth slide transition
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final glow = 0.02 + 0.03 * _pulseController.value;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.persian.withValues(alpha: glow),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF141414).withValues(alpha: 0.88)
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0.06, 0),
                          end: Offset.zero,
                        ).animate(anim);
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: slide,
                            child: child,
                          ),
                        );
                      },
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topLeft,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: _ChatContent(
                        key: ValueKey('chat-$_currentConversation'),
                        conversation: conversation,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Prompt bar — glass morphism
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF141414).withValues(alpha: 0.88)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "What\u2019s on your mind?",
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.persian,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_conversations.length, (i) {
                    final isActive = i == _currentConversation;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.persian
                            : (isDark
                                ? AppColors.persian.withValues(alpha: 0.2)
                                : const Color(0xFFD6D0C6)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
          ),
        ],
      ),
    );
  }
}

// ── Chat content widget (keyed for AnimatedSwitcher) ─────────────────────────
class _ChatContent extends StatelessWidget {
  final _ConversationData conversation;
  final bool isDark;

  const _ChatContent({
    super.key,
    required this.conversation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ChatBubble(
          text: conversation.userMessage,
          isUser: true,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _ChatBubble(
          text: conversation.aiMessage,
          isUser: false,
          isDark: isDark,
        ),
      ],
    );
  }
}

// ── Chat bubble widget ───────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isDark;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.persian.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: ShakingHands(size: 22, animate: false),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.persian
                  : (isDark
                      ? AppColors.darkBgSecondary
                      : AppColors.bgSecondary),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.5,
                color: isUser
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary),
              ),
            ),
          ),
        ),
        if (isUser) const SizedBox(width: 44),
      ],
    );
  }
}

class _ConversationData {
  final String userMessage;
  final String aiMessage;
  final String topic;
  const _ConversationData({
    required this.userMessage,
    required this.aiMessage,
    required this.topic,
  });
}

// ── Google G painter ─────────────────────────────────────────────────────────
class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final sw = size.width * 0.17;

    void arc(double start, double sweep, Color color) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - sw / 2),
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.butt,
      );
    }

    const pi = math.pi;
    arc(-pi / 2, -pi * 0.22, const Color(0xFFEA4335));
    arc(-pi / 2, pi * 1.28, const Color(0xFF4285F4));
    arc(pi * 0.78, pi * 0.44, const Color(0xFF34A853));
    arc(pi * 1.22, pi * 0.28, const Color(0xFFFBBC05));

    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + r * 0.85, c.dy),
      Paint()
        ..color = Colors.white
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.square,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
