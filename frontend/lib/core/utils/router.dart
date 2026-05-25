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
import 'animations.dart';

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

Page<void> _buildTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: MioAnimations.standard,
    reverseTransitionDuration: MioAnimations.standard,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MioAnimations.curve,
        )),
        child: child,
      );
    },
  );
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
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.chat,
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const ChatScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.chatDetail,
        pageBuilder: (context, state) {
          final chatId = state.pathParameters['chatId'];
          return _buildTransitionPage(
            key: state.pageKey,
            child: ChatScreen(chatId: chatId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.apiKeys,
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const ApiKeysScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const SubscriptionScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.devices,
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const DevicesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.usage,
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const UsageScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.storage,
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const StorageScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.projects,
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const ProjectListScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.projectDetail,
        pageBuilder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return _buildTransitionPage(
            key: state.pageKey,
            child: ProjectScreen(projectId: projectId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.projectNewChat,
        pageBuilder: (context, state) {
          final projectId = state.pathParameters['projectId'];
          return _buildTransitionPage(
            key: state.pageKey,
            child: ChatScreen(chatId: null, projectId: projectId),
          );
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
