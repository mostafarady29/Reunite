import '../../../core/storage/stores.dart';
import '../domain/user.dart';

/// Helpers extracted from [RemoteAuthRepository] to keep that file <=150.
///
/// Backend returns JSON:API-ish shapes: `{user}`, `{data: {user}}`, etc.
Map<String, dynamic> unwrapAuthData(dynamic data, String key) {
  if (data is Map<String, dynamic>) {
    if (data[key] is Map<String, dynamic>) {
      return data[key] as Map<String, dynamic>;
    }
    if (data['data'] is Map<String, dynamic>) {
      final inner = data['data'] as Map<String, dynamic>;
      if (inner[key] is Map<String, dynamic>) {
        return inner[key] as Map<String, dynamic>;
      }
      return inner;
    }
    return data;
  }
  return const {};
}

User parseAuthUser(dynamic data) {
  return User.fromJson(unwrapAuthData(data, 'user'));
}

void saveAuthSession(AuthStore store, dynamic data, String fallbackId) {
  final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
  final inner = map['data'] is Map ? map['data'] as Map : map;
  final token = (inner['token'] ?? inner['accessToken']) as String?;
  final refresh = (inner['refreshToken'] ?? inner['refresh']) as String?;
  final userMap = unwrapAuthData(data, 'user');
  final userId = (userMap['id'] ?? userMap['_id'] ?? fallbackId).toString();
  final userName = (userMap['fullName'] ?? userMap['name'] ?? inner['name'] ?? inner['fullName'] ?? '').toString();
  if (token != null) {
    store.saveSession(
      token: token,
      refreshToken: refresh,
      userId: userId,
      userName: userName.isNotEmpty ? userName : null,
    );
  }
}
