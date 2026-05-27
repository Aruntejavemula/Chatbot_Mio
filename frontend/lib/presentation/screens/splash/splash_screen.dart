import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/common/ghost_mascot.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _navigate();
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: const Center(
        child: PenguinMascot(size: 100),
      ),
    );
  }
}
