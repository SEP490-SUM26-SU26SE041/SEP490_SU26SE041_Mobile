abstract class AuthRepository {
  Future<dynamic> login(String email, String password);
  Future<void> logout();
  Future<dynamic> getCurrentUser();
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<dynamic> login(String email, String password) async {
    throw UnimplementedError('Use AuthApiRepository for login');
  }

  @override
  Future<void> logout() async {}

  @override
  Future<dynamic> getCurrentUser() async => null;
}
