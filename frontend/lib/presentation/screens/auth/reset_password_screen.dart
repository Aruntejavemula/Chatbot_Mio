import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/common/shaking_hands.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSuccess = false;

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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).resetPassword(
            token: widget.token,
            newPassword: _passwordController.text,
          );
      if (mounted) setState(() => _isSuccess = true);
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

    // Invalid token state
    if (widget.token.isEmpty) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _animated(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(28),
                  decoration: _glass(isDark),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.error_outline,
                            size: 28, color: AppColors.error),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Invalid reset link',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _txt(isDark),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The reset link is missing or expired.',
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: _sub(isDark)),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => context.go(AppRoutes.emailSignIn),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.persian,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text('Go to sign in',
                              style: GoogleFonts.dmSans(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                _animated(
                  delay: 0.1,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(28),
                    decoration: _glass(isDark),
                    child: _isSuccess
                        ? _buildSuccess(isDark)
                        : _buildForm(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.persian.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded,
                size: 28, color: AppColors.persian),
          ),
          const SizedBox(height: 20),
          Text(
            'Reset password',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _txt(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your new password',
            style: GoogleFonts.dmSans(fontSize: 14, color: _sub(isDark)),
          ),
          const SizedBox(height: 24),
          _field(
            controller: _passwordController,
            label: 'New password',
            hint: 'Enter new password',
            validator: _validatePassword,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _field(
            controller: _confirmPasswordController,
            label: 'Confirm password',
            hint: 'Confirm new password',
            validator: _validateConfirmPassword,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.persian,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.persian.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Reset password',
                      style: GoogleFonts.dmSans(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(bool isDark) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline,
              size: 28, color: AppColors.success),
        ),
        const SizedBox(height: 20),
        Text(
          'Password reset \u{2705}',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _txt(isDark),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your password has been reset successfully',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 14, color: _sub(isDark)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.emailSignIn),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.persian,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text('Go to sign in',
                style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    required bool isDark,
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
          obscureText: true,
          style: GoogleFonts.dmSans(fontSize: 15, color: _txt(isDark)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextMuted
                    : const Color(0xFF9CA3AF)),
            filled: true,
            fillColor:
                isDark ? AppColors.darkInputBg : const Color(0xFFF9FAFB),
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
  Color _sub(bool d) =>
      d ? AppColors.darkTextSecondary : const Color(0xFF6B7280);
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
