import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/common/ghost_mascot.dart';

enum _AuthMode { signIn, signUp, forgot }

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> with TickerProviderStateMixin {
  _AuthMode _mode = _AuthMode.signIn;
  bool _isLoading = false;
  bool _isLoadingGoogle = false;
  bool _isLoadingApple = false;
  bool _forgotSent = false;
  bool _obscurePassword = true;
  bool _ready = false;
  late AnimationController _snowController;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _snowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  late AnimationController _entranceController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _precacheImages();
    }
  }

  Future<void> _precacheImages() async {
    await Future.wait([
      precacheImage(const AssetImage('assets/images/snow_mountains.png'), context),
      precacheImage(const AssetImage('assets/images/snow_forest.png'), context),
    ]);
    if (mounted) {
      setState(() => _ready = true);
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _snowController.dispose();
    _entranceController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _showApple {
    if (kIsWeb) return false;
    try { return Platform.isIOS; } catch (_) { return false; }
  }

  void _switchMode(_AuthMode m) {
    setState(() { _mode = m; _forgotSent = false; });
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
        if (mounted) context.go('${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(_emailCtrl.text.trim())}');
      } else {
        await repo.signInWithEmail(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
        if (mounted) context.go(AppRoutes.chat);
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data is Map
            ? (e.response!.data as Map)['detail']?.toString() ?? 'Something went wrong'
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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 840;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;

    if (!_ready) {
      return Scaffold(backgroundColor: bg);
    }

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Main content
          isWide
              ? Row(children: [Expanded(child: _leftPane(isDark)), Expanded(child: _RightPanel(mode: _mode))])
              : SafeArea(
                  child: Center(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                        child: _leftContent(isDark),
                      ),
                    ),
                  ),
                ),
          // Snowfall overlay
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _snowController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SnowPainter(progress: _snowController.value, isDark: isDark),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leftPane(bool isDark) {
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;
    return Container(
      color: bg,
      child: SafeArea(
        child: Center(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: _leftContent(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _leftContent(bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo top-left
          _staggered(
            delay: 0.0,
            child: Row(
              children: [
                const PenguinMascot(size: 44, animate: false),
                const SizedBox(width: 10),
                Text('Mio', style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: AppColors.persian)),
              ],
            ),
          ),
          const SizedBox(height: 80),
          // Headline — centered
          _staggered(
            delay: 0.15,
            child: Center(
              child: Text(
                _mode == _AuthMode.signIn
                    ? 'Sign in to your account'
                    : _mode == _AuthMode.signUp
                        ? 'Create your account'
                        : 'Reset your password',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 32,
                  height: 1.2,
                  letterSpacing: -0.5,
                  color: textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _staggered(
            delay: 0.3,
            child: _authForm(isDark),
          ),
          const SizedBox(height: 48),
          _staggered(
            delay: 0.5,
            child: _legalText(),
          ),
        ],
      ),
    );
  }

  Widget _staggered({required double delay, required Widget child}) {
    final begin = delay;
    final end = (delay + 0.5).clamp(0.0, 1.0);
    final curvedAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, _) {
        return Opacity(
          opacity: curvedAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curvedAnimation.value)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _authForm(bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final borderColor = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final cardBg = isDark ? AppColors.darkCardBg : AppColors.cardBg;
    final inputBg = isDark ? AppColors.darkInputBg : AppColors.inputBg;
    final inputBorder = isDark ? AppColors.darkInputBorder : AppColors.inputBorder;
    final focusBorder = isDark ? AppColors.darkInputFocusBorder : AppColors.inputFocusBorder;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_mode != _AuthMode.forgot) ...[
            _googleBtn(),
            if (_showApple) ...[const SizedBox(height: 10), _appleBtn()],
            const SizedBox(height: 20),
            _OrDivider(),
            const SizedBox(height: 20),
          ],
          if (_mode == _AuthMode.signUp) ...[
            _field(ctrl: _nameCtrl, label: 'Name', hint: 'Your full name',
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
            const SizedBox(height: 16),
          ],
          _field(
            ctrl: _emailCtrl,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            onSubmit: _mode == _AuthMode.forgot ? _submit : null,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return 'Invalid email';
              return null;
            },
          ),
          if (_mode != _AuthMode.forgot) ...[
            const SizedBox(height: 16),
            _field(
              ctrl: _passwordCtrl,
              label: 'Password',
              hint: '••••••••',
              obscureText: _obscurePassword,
              onSubmit: _submit,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18, color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.persian)),
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
          if (_forgotSent)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Reset link sent — check your inbox.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF065F46))),
            )
          else
            _submitBtn(),
          const SizedBox(height: 20),
          if (_mode == _AuthMode.signIn) ...[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Don't have an account? ",
                  style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
              GestureDetector(
                onTap: () => _switchMode(_AuthMode.signUp),
                child: Text('Sign up',
                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary, decoration: TextDecoration.underline)),
              ),
            ]),
          ] else if (_mode == _AuthMode.signUp) ...[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Already have a Mio account? ',
                  style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
              GestureDetector(
                onTap: () => _switchMode(_AuthMode.signIn),
                child: Text('Log in',
                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary, decoration: TextDecoration.underline)),
              ),
            ]),
          ] else ...[
            Center(
              child: GestureDetector(
                onTap: () => _switchMode(_AuthMode.signIn),
                child: Text('← Back to sign in',
                    style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary, decoration: TextDecoration.underline)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _googleBtn() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = _mode == _AuthMode.signUp ? 'Sign up with Google' : 'Sign in with Google';
    final bg = isDark ? AppColors.darkBgSecondary : Colors.white;
    final border = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: _isLoadingGoogle ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: textColor,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoadingGoogle
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 18, height: 18, child: CustomPaint(painter: _GooglePainter())),
                const SizedBox(width: 10),
                Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
              ]),
      ),
    );
  }

  Widget _appleBtn() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: _isLoadingApple ? null : _signInWithApple,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderDefault),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoadingApple
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.apple, size: 20, color: Colors.black),
                const SizedBox(width: 10),
                Text('Sign in with Apple',
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ]),
      ),
    );
  }

  Widget _submitBtn() {
    final label = _mode == _AuthMode.signIn
        ? 'Sign In'
        : _mode == _AuthMode.signUp
            ? 'Sign Up'
            : 'Send Reset Link';
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.persian,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffix,
    VoidCallback? onSubmit,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final inputBg = isDark ? AppColors.darkInputBg : Colors.white;
    final border = isDark ? AppColors.darkInputBorder : AppColors.borderDefault;
    final focusBorder = isDark ? AppColors.darkInputFocusBorder : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: onSubmit != null ? TextInputAction.done : TextInputAction.next,
          onFieldSubmitted: onSubmit != null ? (_) => onSubmit() : null,
          style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(fontSize: 14, color: textMuted),
            filled: true,
            fillColor: inputBg,
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: focusBorder)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightError)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightError)),
          ),
        ),
      ],
    );
  }

  Widget _legalText() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final linkColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final action = _mode == _AuthMode.signUp ? 'Sign Up' : 'Sign In';
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.dmSans(fontSize: 12, color: textMuted),
          children: [
            TextSpan(text: 'By clicking "$action", you agree to our '),
            TextSpan(text: 'Terms of Service',
                style: TextStyle(color: linkColor, decoration: TextDecoration.underline)),
            const TextSpan(text: ' and '),
            TextSpan(text: 'Privacy Policy',
                style: TextStyle(color: linkColor, decoration: TextDecoration.underline)),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}

// ── Or divider ────────────────────────────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final text = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Row(children: [
      Expanded(child: Divider(color: border, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text('OR', style: GoogleFonts.dmSans(fontSize: 11, letterSpacing: 0.5, color: text)),
      ),
      Expanded(child: Divider(color: border, thickness: 1)),
    ]);
  }
}

// ── Right panel — snow image + contextual marketing ──────────────────────────
class _RightPanel extends StatelessWidget {
  final _AuthMode mode;
  const _RightPanel({required this.mode});

  static const _headlines = {
    _AuthMode.signIn: 'Clear thoughts.\nZero noise.',
    _AuthMode.signUp: 'Think smarter.\nCreate freely.',
    _AuthMode.forgot: 'No worries.\nWe\'ve got you.',
  };

  static const _subtitles = {
    _AuthMode.signIn: 'Your AI that cuts through the clutter — focused, fast, no filler.',
    _AuthMode.signUp: 'Join thousands who think better with Mio by their side.',
    _AuthMode.forgot: 'A fresh start is one link away. Your thoughts are safe.',
  };

  String get _imagePath {
    switch (mode) {
      case _AuthMode.signIn:
        return 'assets/images/snow_mountains.png';
      case _AuthMode.signUp:
        return 'assets/images/snow_forest.png';
      case _AuthMode.forgot:
        return 'assets/images/snow_forest.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.darkBgPrimary : Colors.white,
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1A1A2E),
              ),
            ),
            // Dark gradient overlay for text readability
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
            // Marketing text
            Positioned(
              left: 40,
              right: 40,
              bottom: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _headlines[mode]!,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 34,
                      height: 1.2,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _subtitles[mode]!,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Floating prompt bar on image
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            mode == _AuthMode.signIn
                                ? 'What\'s on your mind?'
                                : mode == _AuthMode.signUp
                                    ? 'What would you build today?'
                                    : 'Ask me anything...',
                            style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                          ),
                        ),
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.persian,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 16),
                        ),
                      ],
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
}

// ── Google G painter ──────────────────────────────────────────────────────────
class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final sw = size.width * 0.17;

    void arc(double start, double sweep, Color color) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - sw / 2),
        start, sweep, false,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.butt,
      );
    }

    const pi = math.pi;
    arc(-pi / 2, -pi * 0.22, const Color(0xFFEA4335));
    arc(-pi / 2,  pi * 1.28, const Color(0xFF4285F4));
    arc( pi * 0.78, pi * 0.44, const Color(0xFF34A853));
    arc( pi * 1.22, pi * 0.28, const Color(0xFFFBBC05));

    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + r * 0.85, c.dy),
      Paint()..color = Colors.white..strokeWidth = sw..strokeCap = StrokeCap.square,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Snow painter ──────────────────────────────────────────────────────────────
class _SnowPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  _SnowPainter({required this.progress, required this.isDark});

  static final List<_Snowflake> _flakes = List.generate(80, (i) {
    final rng = math.Random(i);
    return _Snowflake(
      x: rng.nextDouble(),
      startY: rng.nextDouble(),
      radius: 1.5 + rng.nextDouble() * 2.5,
      speed: 0.3 + rng.nextDouble() * 0.7,
      drift: (rng.nextDouble() - 0.5) * 0.15,
      opacity: 0.2 + rng.nextDouble() * 0.5,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in _flakes) {
      final y = ((f.startY + progress * f.speed) % 1.0) * size.height;
      final x = (f.x + math.sin(progress * math.pi * 2 + f.startY * 10) * f.drift) * size.width;

      canvas.drawCircle(
        Offset(x, y),
        f.radius,
        Paint()..color = (isDark ? Colors.white : const Color(0xFFCCCCCC)).withOpacity(f.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter old) => old.progress != progress;
}

class _Snowflake {
  final double x;
  final double startY;
  final double radius;
  final double speed;
  final double drift;
  final double opacity;

  const _Snowflake({
    required this.x,
    required this.startY,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.opacity,
  });
}
