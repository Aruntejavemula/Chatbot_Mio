import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/common/shaking_hands.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  int _cooldown = 0;
  Timer? _timer;
  bool _isResending = false;

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
    _timer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldown = 0);
      } else {
        if (mounted) setState(() => _cooldown--);
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_cooldown > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      await ref.read(authRepositoryProvider).resendVerification(widget.email);
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
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
          child: Padding(
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
                          color: AppColors.persian.withOpacity(0.12),
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
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.persian.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mark_email_read_outlined,
                              size: 28, color: AppColors.persian),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Verify your email',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: _txt(isDark),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'We sent a verification link to',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: _sub(isDark)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.persian.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.email,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.persian,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _cooldown > 0 || _isResending
                                ? null
                                : _resendEmail,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _cooldown > 0
                                    ? _inBorder(isDark)
                                    : AppColors.persian,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isResending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(
                                    _cooldown > 0
                                        ? 'Resend email ($_cooldown s)'
                                        : 'Resend email',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _cooldown > 0
                                          ? _sub(isDark)
                                          : AppColors.persian,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _animated(
                  delay: 0.2,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.emailSignIn),
                    style: TextButton.styleFrom(
                      backgroundColor: _cardBg(isDark).withOpacity(0.6),
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

  Color _cardBg(bool d) => d ? const Color(0xFF141414) : Colors.white;
  Color _txt(bool d) => d ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color _sub(bool d) =>
      d ? AppColors.darkTextSecondary : const Color(0xFF6B7280);
  Color _inBorder(bool d) =>
      d ? AppColors.darkInputBorder : const Color(0xFFE5E7EB);

  BoxDecoration _glass(bool d) => BoxDecoration(
        color: d
            ? _cardBg(d).withOpacity(0.92)
            : _cardBg(d).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: d
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(d ? 0.4 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      );
}
