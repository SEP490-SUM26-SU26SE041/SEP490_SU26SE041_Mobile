library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../data/auth_api_repository.dart';

final loginProvider = FutureProvider.autoDispose.family<UserModel, LoginCredentials>(
  (ref, creds) async {
    final repo = ref.read(authRepositoryProvider);
    return repo.login(creds.email, creds.password);
  },
);

final logoutProvider = FutureProvider.autoDispose<void>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  await repo.logout();
});

class LoginCredentials {
  const LoginCredentials({required this.email, required this.password});
  final String email;
  final String password;
}
