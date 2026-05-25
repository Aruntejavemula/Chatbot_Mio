import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _titleController;
  late final AnimationController _taglineController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _titleFade = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeIn,
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 10 / 48),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOut,
    ));

    _taglineFade = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeIn,
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 10 / 16),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeOut,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    _titleController.forward();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _taglineController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _navigate();
      }
    });
  }

  void _navigate() async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (isAuthenticated) {
      const storage = FlutterSecureStorage();
      final value = await storage.read(key: 'onboarding_complete');
      if (!mounted) return;
      if (value == null || value != 'true') {
        context.go(AppRoutes.onboarding);
      } else {
        context.go(AppRoutes.chat);
      }
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final taglineColor =
        isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Add mascot image here
            SlideTransition(
              position: _titleSlide,
              child: FadeTransition(
                opacity: _titleFade,
                child: Text(
                  'Mio',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SlideTransition(
              position: _taglineSlide,
              child: FadeTransition(
                opacity: _taglineFade,
                child: Text(
                  'Think. Not yap.',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: taglineColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
