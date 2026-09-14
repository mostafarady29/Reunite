import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import 'hive_service.dart';

/// Typed access to the auth session box.
class AuthStore {
  AuthStore(this._box);

  AuthStore.of() : _box = HiveService.authBox;

  final Box _box;
  Box get box => _box;

  static String get _tokenKey => 'access_token';
  static String get _refreshKey => 'refresh_token';
  static String get _userIdKey => 'user_id';
  static String get _userNameKey => 'user_name';
  static String get _isGuestKey => 'is_guest';

  String? get token => box.get(_tokenKey) as String?;
  String? get refreshToken => box.get(_refreshKey) as String?;
  String? get userId => box.get(_userIdKey) as String?;
  String? get userName => box.get(_userNameKey) as String?;
  bool get isGuest => (box.get(_isGuestKey) as bool?) ?? true;

  bool get isAuthenticated => token != null && !isGuest;

  void saveSession({
    required String token,
    String? refreshToken,
    String? userId,
    String? userName,
  }) {
    box.put(_tokenKey, token);
    if (refreshToken != null) box.put(_refreshKey, refreshToken);
    if (userId != null) box.put(_userIdKey, userId);
    if (userName != null && userName.isNotEmpty) box.put(_userNameKey, userName);
    box.put(_isGuestKey, false);
  }

  void saveGuest() {
    box.put(_isGuestKey, true);
  }

  void clear() {
    box.delete(_tokenKey);
    box.delete(_refreshKey);
    box.delete(_userIdKey);
    box.delete(_userNameKey);
    box.delete(_isGuestKey);
  }
}

/// Lightweight prefs store for settings/preferences.
class PrefsStore {
  PrefsStore.of() : _box = HiveService.prefsBox;

  final Box _box;
  Box get box => _box;

  // keys
  static const _kThemeMode = 'theme_mode';
  static const _kLocale = 'locale';
  static const _kRadius = 'alert_radius';
  static const _kNotifyNearby = 'notify_nearby';
  static const _kNotifyUpdates = 'notify_updates';
  static const _kNotifyMatches = 'notify_matches';
  static const _kPushEnabled = 'push_enabled';
  static const _kOnboarded = 'onboarded';

  String? get themeMode => box.get(_kThemeMode) as String?;
  set themeMode(String? v) => _put(_kThemeMode, v);
  void clearThemeMode() => box.delete(_kThemeMode);

  String? get locale => box.get(_kLocale) as String?;
  set locale(String? v) => _put(_kLocale, v);

  int get alertRadiusMeters =>
      box.get(_kRadius) ?? AppConstants.defaultAlertRadiusMeters;
  set alertRadiusMeters(int v) => _put(_kRadius, v);

  bool get notifyNearby => box.get(_kNotifyNearby) as bool? ?? true;
  set notifyNearby(bool v) => _put(_kNotifyNearby, v);
  bool get notifyUpdates => box.get(_kNotifyUpdates) as bool? ?? true;
  set notifyUpdates(bool v) => _put(_kNotifyUpdates, v);
  bool get notifyMatches => box.get(_kNotifyMatches) as bool? ?? true;
  set notifyMatches(bool v) => _put(_kNotifyMatches, v);
  bool get pushEnabled => box.get(_kPushEnabled) as bool? ?? true;
  set pushEnabled(bool v) => _put(_kPushEnabled, v);

  bool get onboarded => box.get(_kOnboarded) as bool? ?? false;
  set onboarded(bool v) => _put(_kOnboarded, v);

  void _put(String key, Object? value) {
    if (value == null) {
      box.delete(key);
    } else {
      box.put(key, value);
    }
  }
}

/// Typed access to cached data (cached cases, recent searches, notifications).
class CacheStore {
  CacheStore.of() : _box = HiveService.cacheBox;

  final Box _box;

  Box get box => _box;

  String? _read(String key) => box.get(key) as String?;

  void _write(String key, Object value) => box.put(key, value);

  List<String> readStringList(String key) {
    final String? raw = _read(key);
    if (raw == null) return const [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  void writeStringList(String key, List<String> values) {
    _write(key, jsonEncode(values));
  }

  T? readJson<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final String? raw = _read(key);
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  void writeJson(String key, Map<String, dynamic> value) {
    _write(key, jsonEncode(value));
  }
}