import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref);
});

final currentUserProvider = StateProvider<UserModel?>((ref) {
  return null;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

class AuthRepository {
  final Ref _ref;

  AuthRepository(this._ref);

  AuthService get _authService => _ref.read(authServiceProvider);

  Future<UserModel> signInWithGoogle(String idToken) async {
    try {
      final response = await _authService.googleSignIn(idToken);
      final token = response['token'] as String;
      await _authService.saveTokenSecurely(token);
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      _ref.read(currentUserProvider.notifier).state = user;
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> signInWithApple(String identityToken) async {
    try {
      final response = await _authService.appleSignIn(identityToken);
      final token = response['token'] as String;
      await _authService.saveTokenSecurely(token);
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      _ref.read(currentUserProvider.notifier).state = user;
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      await _authService.clearToken();
      _ref.read(currentUserProvider.notifier).state = null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final token = await _authService.getStoredToken();
      if (token == null) {
        return null;
      }
      final response = await _authService.getProfile();
      final user = UserModel.fromJson(response);
      _ref.read(currentUserProvider.notifier).state = user;
      return user;
    } catch (e) {
      _ref.read(currentUserProvider.notifier).state = null;
      rethrow;
    }
  }

  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authService.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );
      final token = response['access_token'] as String;
      await _authService.saveTokenSecurely(token);
      final user =
          UserModel.fromJson(response['user'] as Map<String, dynamic>);
      // Don't set currentUser here - user must verify email first.
      // Token is saved for the resend-verification call.
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      final token = response['access_token'] as String;
      await _authService.saveTokenSecurely(token);
      final user =
          UserModel.fromJson(response['user'] as Map<String, dynamic>);
      _ref.read(currentUserProvider.notifier).state = user;
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _authService.forgotPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _authService.resetPassword(token: token, newPassword: newPassword);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resendVerification(String email) async {
    try {
      await _authService.resendVerification(email);
    } catch (e) {
      rethrow;
    }
  }
}
