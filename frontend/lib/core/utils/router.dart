import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/auth/welcome_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/settings/api_keys_screen.dart';
import '../../presentation/screens/settings/devices_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/settings/subscription_screen.dart';
import '../../presentation/screens/settings/storage_screen.dart';
import '../../presentation/screens/settings/usage_screen.dart';
import '../../presentation/screens/projects/project_list_screen.dart';
import '../../presentation/screens/projects/project_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const chat = '/chat';
  static const chatDetail = '/chat/:chatId';
  static const settings = '/settings';
  static const apiKeys = '/settings/api-keys';
  static const subscription = '/settings/subscription';
  static const devices = '/settings/devices';
  static const usage = '/settings/usage';
  static const storage = '/settings/storage';
  static const projects = '/projects';
  static const projectDetail = '/projects/:projectId';
  static const projectNewChat = '/projects/:projectId/new-chat';
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
        AppRoutes.onboarding,
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
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
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
      GoRoute(
        path: AppRoutes.usage,
        builder: (context, state) => const UsageScreen(),
      ),
      GoRoute(
        path: AppRoutes.storage,
        builder: (context, state) => const StorageScreen(),
      ),
      GoRoute(
        path: AppRoutes.projects,
        builder: (context, state) => const ProjectListScreen(),
      ),
      GoRoute(
        path: AppRoutes.projectDetail,
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return ProjectScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: AppRoutes.projectNewChat,
        builder: (context, state) {
          return const ChatScreen(chatId: null);
        },
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
