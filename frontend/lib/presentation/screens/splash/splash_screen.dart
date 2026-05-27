import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/common/shaking_hands.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mascotController;
  late final AnimationController _titleController;
  late final AnimationController _taglineController;
  late final AnimationController _accentController;
  late final AnimationController _exitController;

  late final Animation<double> _mascotScale;
  late final Animation<double> _mascotFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _accentFade;
  late final Animation<double> _accentWidth;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _accentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _mascotScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _mascotController, curve: Curves.easeOutBack),
    );

    _mascotFade = CurvedAnimation(
      parent: _mascotController,
      curve: Curves.easeIn,
    );

    _titleFade = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeIn,
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOutCubic,
    ));

    _taglineFade = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeIn,
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeOutCubic,
    ));

    _accentFade = CurvedAnimation(
      parent: _accentController,
      curve: Curves.easeIn,
    );

    _accentWidth = Tween<double>(begin: 0, end: 40).animate(
      CurvedAnimation(parent: _accentController, curve: Curves.easeOutCubic),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _mascotController.forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _titleController.forward();
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _taglineController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) _accentController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        _exitController.forward().then((_) {
          if (mounted) _navigate();
        });
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
    _mascotController.dispose();
    _titleController.dispose();
    _taglineController.dispose();
    _accentController.dispose();
    _exitController.dispose();
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
      body: FadeTransition(
        opacity: _exitFade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _mascotScale,
                child: FadeTransition(
                  opacity: _mascotFade,
                  child: const ShakingHands(size: 120),
                ),
              ),
              const SizedBox(height: 24),
              SlideTransition(
                position: _titleSlide,
                child: FadeTransition(
                  opacity: _titleFade,
                  child: Text(
                    AppStrings.appName,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _accentFade,
                builder: (context, child) => Opacity(
                  opacity: _accentFade.value,
                  child: AnimatedBuilder(
                    animation: _accentWidth,
                    builder: (context, child) => Container(
                      width: _accentWidth.value,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.persian,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SlideTransition(
                position: _taglineSlide,
                child: FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    AppStrings.tagline,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: taglineColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
