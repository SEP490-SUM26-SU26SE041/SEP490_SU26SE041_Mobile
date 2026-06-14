import 'package:flutter_application_2/shared/models/user_model.dart';
import 'package:flutter_application_2/mock/mock_users.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final user = mockUsers.where(
      (u) => u.email.toLowerCase() == email.toLowerCase()
    ).firstOrNull;
    if (user == null) {
      throw Exception('Invalid email or password');
    }
    return user;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return null;
  }
}
