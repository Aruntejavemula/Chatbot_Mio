import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/common/shaking_hands.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isLoadingGoogle = false;
  bool _isLoadingApple = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool get _showAppleButton {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoadingGoogle = true);
    try {
      // TODO: Get actual Google ID token from Google Sign-In SDK
      await ref.read(authRepositoryProvider).signInWithGoogle('');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingGoogle = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoadingApple = true);
    try {
      // TODO: Get actual Apple identity token from Sign in with Apple SDK
      await ref.read(authRepositoryProvider).signInWithApple('');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingApple = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Mascot placeholder
            const ShakingHands(size: 80),
            const SizedBox(height: 20),
            // App name
            Text(
              'Mio',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Tagline
            Text(
              'Think. Not yap.',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
            const Spacer(flex: 3),
            // Buttons section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  children: [
                    // Google Sign In button
                    _buildSignInButton(
                      isLoading: _isLoadingGoogle,
                      onPressed: _signInWithGoogle,
                      logoWidget: const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      label: 'Continue with Google',
                    ),
                    if (_showAppleButton) ...[
                      const SizedBox(height: 12),
                      // Apple Sign In button
                      _buildSignInButton(
                        isLoading: _isLoadingApple,
                        onPressed: _signInWithApple,
                        logoWidget: const Text(
                          '\u{1F34E}',
                          style: TextStyle(fontSize: 18),
                        ),
                        label: 'Continue with Apple',
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? AppColors.darkBorderDefault
                                : AppColors.borderDefault,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? AppColors.darkBorderDefault
                                : AppColors.borderDefault,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSignInButton(
                      isLoading: false,
                      onPressed: () => context.go(AppRoutes.emailSignIn),
                      logoWidget: Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF0A0A0A),
                      ),
                      label: 'Continue with email',
                    ),
                    const SizedBox(height: 24),
                    // Try without signing in
                    TextButton(
                      onPressed: () => context.go(AppRoutes.chat),
                      child: Text(
                        'Try without signing in',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.dmSans(fontSize: 12),
                  children: [
                    TextSpan(
                      text: 'By continuing you agree to our ',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                    const TextSpan(
                      text: 'Terms',
                      style: TextStyle(
                        color: AppColors.persian,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(
                      text: ' and ',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                    const TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppColors.persian,
                        decoration: TextDecoration.underline,
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

  Widget _buildSignInButton({
    required bool isLoading,
    required VoidCallback onPressed,
    required Widget logoWidget,
    required String label,
  }) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: AppColors.borderDefault),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              offset: Offset(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        logoWidget,
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0A0A0A),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
