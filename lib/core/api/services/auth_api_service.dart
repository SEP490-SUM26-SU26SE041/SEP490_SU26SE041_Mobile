library;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.read(dioProvider));
});

class AuthApiService {
  AuthApiService(this._dio);
  final Dio _dio;

  /// POST /auth/login
  Future<AuthTokenResponse> login(LoginRequest request) async {
    final res = await _dio.post(
      '/auth/login',
      data: request.toJson(),
    );
    return AuthTokenResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// Save token to secure storage after successful login.
  static Future<void> saveToken(String token) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'auth_token', value: token);
  }

  /// Clear token on logout.
  static Future<void> clearToken() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'auth_token');
  }
}

class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

/// Response model — userId được parse từ JWT token.
class AuthTokenResponse {
  const AuthTokenResponse({
    required this.token,
    required this.userId,
    required this.role,
    this.email,
    this.fullName,
  });

  final String token;
  final String userId;
  final String role;
  final String? email;
  final String? fullName;

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String;
    // Parse userId từ JWT payload (backend không gửi userId trực tiếp)
    final userId = _parseUserIdFromJwt(token);
    return AuthTokenResponse(
      token: token,
      userId: userId,
      role: json['role'] as String,
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
    );
  }

  /// Trích userId từ JWT payload.
  /// JWT format: header.payload.signature
  static String _parseUserIdFromJwt(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return jwt;
      // Pad base64
      final payload = parts[1];
      final padded = payload.padRight(payload.length + (4 - payload.length % 4) % 4, '=');
      final decoded = utf8.decode(base64Decode(padded));
      final map = Map<String, dynamic>.from(json.decode(decoded) as Map);
      // Các claim có thể có của userId
      return (map['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']
              ?? map['sub']
              ?? map['userId']
              ?? map['id']
              ?? jwt) as String;
    } catch (_) {
      return jwt;
    }
  }
}
