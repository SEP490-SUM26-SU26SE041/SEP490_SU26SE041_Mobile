import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_2/shared/models/user_model.dart';
import 'package:flutter_application_2/core/api/services/auth_api_service.dart';
import '../data/auth_api_repository.dart';

final authApiRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(authApiServiceProvider));
});

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserModel user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.ref) : super(const AuthInitial());

  final Ref ref;

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final repo = ref.read(authApiRepositoryProvider);
      final user = await repo.login(email, password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authApiRepositoryProvider);
    await repo.logout();
    state = const AuthUnauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated ? authState.user : null;
});
