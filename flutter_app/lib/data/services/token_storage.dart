import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:infojobs_flutter_app/data/models/auth_session.dart';

const _tokenKey = 'auth_session';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

class TokenStorage {
  AuthSession? _cache;

  Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, jsonEncode(session.toJson()));
    _cache = session;
  }

  Future<AuthSession?> read() async {
    if (_cache != null) return _cache;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tokenKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _cache = AuthSession.fromJson(json);
      return _cache;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _cache = null;
  }
}
