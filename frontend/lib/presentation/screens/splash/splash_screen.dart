import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
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
  late final AnimationController _entryController;
  late final AnimationController _exitController;

  late final Animation<double> _entryScale;
  late final Animation<double> _entryFade;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _entryScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );

    _entryFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeIn,
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _entryController.forward();

    Future.delayed(const Duration(milliseconds: 2100), () {
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
    _entryController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _exitFade,
        child: Center(
          child: ScaleTransition(
            scale: _entryScale,
            child: FadeTransition(
              opacity: _entryFade,
              child: const ShakingHands(size: 140),
            ),
          ),
        ),
      ),
    );
  }
}
