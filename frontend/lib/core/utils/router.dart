import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/welcome_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/settings/api_keys_screen.dart';
import '../../presentation/screens/settings/devices_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/settings/subscription_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const chat = '/chat';
  static const chatDetail = '/chat/:chatId';
  static const settings = '/settings';
  static const apiKeys = '/settings/api-keys';
  static const subscription = '/settings/subscription';
  static const devices = '/settings/devices';
}

final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.matchedLocation;

      const publicRoutes = [
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.login,
      ];

      if (!isAuthenticated) {
        if (publicRoutes.contains(location)) {
          return null;
        }
        return AppRoutes.welcome;
      }

      if (location == AppRoutes.splash || location == AppRoutes.welcome) {
        return AppRoutes.chat;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatDetail,
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'];
          return ChatScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.apiKeys,
        builder: (context, state) => const ApiKeysScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.devices,
        builder: (context, state) => const DevicesScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Page not found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.chat),
              child: const Text('Go to Chat'),
            ),
          ],
        ),
      ),
    ),
  );
});
