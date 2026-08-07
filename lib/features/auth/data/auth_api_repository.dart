library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/api/services/auth_api_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(authApiServiceProvider));
});

class AuthRepository {
  AuthRepository(this._api);
  final AuthApiService _api;

  Future<UserModel> login(String email, String password) async {
    final res = await _api.login(LoginRequest(email: email, password: password));
    await AuthApiService.saveToken(res.token);
    return UserModel(
      id: res.userId,
      email: res.email ?? email,
      fullName: res.fullName ?? email.split('@').first,
      role: _parseRole(res.role),
    );
  }

  Future<void> logout() async {
    await AuthApiService.clearToken();
  }

  UserRole _parseRole(String role) {
    return switch (role.toLowerCase()) {
      'admin' => UserRole.admin,
      'researcher' => UserRole.researcher,
      'farmmanager' || 'farm_manager' => UserRole.farmManager,
      'technician' => UserRole.technician,
      'student' => UserRole.student,
      _ => UserRole.student,
    };
  }
}
