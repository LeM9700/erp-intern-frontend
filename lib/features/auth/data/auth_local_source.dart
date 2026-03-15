import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erp_frontend/features/auth/domain/models/user_model.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden at startup');
});

final authLocalSourceProvider = Provider<AuthLocalSource>((ref) {
  return AuthLocalSource(ref.read(sharedPrefsProvider));
});

class AuthLocalSource {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUser = 'current_user';

  final SharedPreferences _prefs;

  AuthLocalSource(this._prefs);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_keyAccessToken, accessToken);
    await _prefs.setString(_keyRefreshToken, refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _prefs.getString(_keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return _prefs.getString(_keyRefreshToken);
  }

  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  UserModel? getUser() {
    final json = _prefs.getString(_keyUser);
    if (json == null) return null;
    return UserModel.fromJson(jsonDecode(json));
  }

  Future<void> clearAll() async {
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyUser);
  }

  bool get isLoggedIn => _prefs.containsKey(_keyAccessToken);
}
