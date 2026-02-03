import 'package:flutter/material.dart';
import 'dart:async';

import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/app_config.dart';
import '../utils/app_storage.dart';

class AuthProvider extends ChangeNotifier {
  final AppStorage _storage = getStorage();

  bool loading = true;
  String? token;
  User? user;
  String baseUrl = AppConfig.defaultBaseUrl;

  bool get isAuthenticated => token != null && user != null;

  Future<void> loadFromStorage() async {
    loading = true;
    notifyListeners();

    try {
      token = await _withTimeout<String?>(
        _storage.read('token'),
        const Duration(seconds: 3),
      );
      baseUrl = await _withTimeout<String?>(
            _storage.read('baseUrl'),
            const Duration(seconds: 3),
          ) ??
          AppConfig.defaultBaseUrl;

      if (token != null) {
        try {
          final api = ApiService(baseUrl: baseUrl, token: token);
          user = await api.me();
        } catch (_) {
          token = null;
          user = null;
          await _withTimeout<void>(
            _storage.delete('token'),
            const Duration(seconds: 2),
          );
        }
      }
    } catch (_) {
      token = null;
      user = null;
      baseUrl = AppConfig.defaultBaseUrl;
    }

    loading = false;
    notifyListeners();
  }

  Future<void> login({
    required String username,
    required String password,
    required String newBaseUrl,
  }) async {
    loading = true;
    notifyListeners();
    baseUrl = newBaseUrl.trim();
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    _withTimeout<void>(
      _storage.write('baseUrl', baseUrl),
      const Duration(seconds: 2),
    );

    try {
      final api = ApiService(baseUrl: baseUrl, token: null);
      final data = await api
          .login(username: username, password: password)
          .timeout(const Duration(seconds: 15));

      token = data['token'] as String;
      user = User.fromJson(data['user'] as Map<String, dynamic>);

      if (token != null) {
        _withTimeout<void>(
          _storage.write('token', token!),
          const Duration(seconds: 2),
        );
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    token = null;
    user = null;
    _withTimeout<void>(
      _storage.delete('token'),
      const Duration(seconds: 2),
    );
    notifyListeners();
  }

  ApiService api() {
    return ApiService(baseUrl: baseUrl, token: token);
  }

  Future<T> _withTimeout<T>(Future<T> future, Duration duration) async {
    return Future.any([
      future,
      Future<T>.delayed(duration, () => throw TimeoutException('timeout')),
    ]);
  }
}
