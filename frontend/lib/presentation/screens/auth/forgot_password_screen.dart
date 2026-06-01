import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/common/shaking_hands.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

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
    _emailController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      if (mounted) setState(() => _isSent = true);
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
                    child: _isSent
                        ? _buildSuccess(isDark)
                        : _buildForm(isDark),
                  ),
                ),
                const SizedBox(height: 16),
                _animated(
                  delay: 0.2,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.emailSignIn),
                    style: TextButton.styleFrom(
                      backgroundColor: _cardBg(isDark).withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      '\u2190 Back to sign in',
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

  Widget _buildForm(bool isDark) {
    return Column(
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
          'Forgot password?',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _txt(isDark),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'No worries \u2014 enter your email and we\u2019ll send a reset link',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 14, color: _sub(isDark)),
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email',
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _txt(isDark))),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.dmSans(fontSize: 15, color: _txt(isDark)),
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : const Color(0xFF9CA3AF)),
                filled: true,
                fillColor:
                    isDark ? AppColors.darkInputBg : const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
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
                  borderSide: const BorderSide(
                      color: AppColors.persian, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendResetLink,
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
                : Text('Send reset link',
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
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
          child: const Icon(Icons.mark_email_read_outlined,
              size: 28, color: AppColors.success),
        ),
        const SizedBox(height: 20),
        Text(
          'Check your email',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _txt(isDark),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We sent a password reset link to your email',
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
            child: Text('Back to sign in',
                style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w600)),
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
