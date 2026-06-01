import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/common/shaking_hands.dart';

class EmailSignInScreen extends ConsumerStatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  ConsumerState<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends ConsumerState<EmailSignInScreen>
    with SingleTickerProviderStateMixin {
  bool _isSignUp = false;
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      if (_isSignUp) {
        await authRepo.signUpWithEmail(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          context.go(
            '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(_emailController.text.trim())}',
          );
        }
      } else {
        await authRepo.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) context.go(AppRoutes.chat);
      }
    } on DioException catch (e) {
      if (mounted) {
        final message = e.response?.data is Map
            ? (e.response?.data as Map<String, Object?>)['detail']?.toString() ??
                'Something went wrong'
            : 'Something went wrong';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _animated({required Widget child, double delay = 0}) {
    final fade = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(delay, (0.6 + delay).clamp(0, 1), curve: Curves.easeOut),
    );
    final slide = CurvedAnimation(
      parent: _entranceController,
      curve:
          Interval(delay, (0.7 + delay).clamp(0, 1), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (_, __) => Opacity(
        opacity: fade.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - slide.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mascot with glow
                _animated(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.persian.withValues(alpha: 0.12),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const ShakingHands(size: 64, animate: true),
                  ),
                ),
                const SizedBox(height: 20),
                // Glass card
                _animated(
                  delay: 0.1,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(28),
                    decoration: _glass(isDark),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text(
                            _isSignUp ? 'Create account' : 'Welcome back',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _txt(isDark),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isSignUp
                                ? 'Sign up to get started'
                                : 'Sign in to your account',
                            style: GoogleFonts.dmSans(
                                fontSize: 14, color: _sub(isDark)),
                          ),
                          const SizedBox(height: 24),
                          if (_isSignUp) ...[
                            _field(
                              controller: _nameController,
                              label: 'Name',
                              hint: 'Enter your name',
                              validator: _validateName,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 14),
                          ],
                          _field(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'Enter your email',
                            validator: _validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Enter your password',
                            validator: _validatePassword,
                            obscureText: true,
                            isDark: isDark,
                          ),
                          if (!_isSignUp) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    context.go(AppRoutes.forgotPassword),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13, color: AppColors.persian),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.persian,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.persian.withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : Text(
                                      _isSignUp ? 'Sign up' : 'Sign in',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSignUp
                                    ? 'Already have an account?'
                                    : "Don't have an account?",
                                style: GoogleFonts.dmSans(
                                    fontSize: 14, color: _sub(isDark)),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isSignUp = !_isSignUp),
                                child: Text(
                                  _isSignUp ? 'Sign in' : 'Sign up',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.persian),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _animated(
                  delay: 0.2,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.welcome),
                    style: TextButton.styleFrom(
                      backgroundColor: _cardBg(isDark).withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      '\u2190 Back to welcome',
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _sub(isDark)),
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _txt(isDark))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: GoogleFonts.dmSans(fontSize: 15, color: _txt(isDark)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark ? AppColors.darkTextMuted : const Color(0xFF9CA3AF)),
            filled: true,
            fillColor: isDark ? AppColors.darkInputBg : const Color(0xFFF9FAFB),
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
              borderSide:
                  const BorderSide(color: AppColors.persian, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Color _cardBg(bool d) => d ? const Color(0xFF141414) : Colors.white;
  Color _txt(bool d) => d ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color _sub(bool d) => d ? AppColors.darkTextSecondary : const Color(0xFF6B7280);
  Color _inBorder(bool d) =>
      d ? AppColors.darkInputBorder : const Color(0xFFE5E7EB);

  BoxDecoration _glass(bool d) => BoxDecoration(
        color: d
            ? _cardBg(d).withValues(alpha: 0.92)
            : _cardBg(d).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: d
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: d ? 0.4 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      );
}
