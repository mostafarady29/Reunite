import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/stores.dart';
import '../domain/user.dart';
import 'auth_api_mapper.dart';
import 'auth_repository.dart';

/// REST-backed auth repository. Mirrors [MockAuthRepository] so the UI
/// doesn't change when [kUseMock] flips to false.
///
/// Expected backend contract (JSON:API-ish):
/// POST /auth/login    {phone, password} -> {token, refreshToken, user}
/// POST /auth/register {fullName, phone, password, city} -> {token?, user}
/// NOTE: governorate is UI-only — only `city` is sent to the backend.
/// POST /auth/verify-otp {code}
/// POST /auth/forgot-password {email}
/// POST /auth/reset-password {email, code, newPassword}
/// GET  /auth/me -> {user} | {data}
/// PATCH /auth/profile -> {user}
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._api, this._authStore);

  final ApiClient _api;
  final AuthStore _authStore;

  @override
  Future<User> login(LoginInput input) async {
    final res = await _api.run(
      (dio) => dio.post(ApiEndpoints.login, data: {
        'phone': input.phone,
        // Kept for backward compatibility with backends expecting `identifier`.
        'identifier': input.phone,
        'password': input.password,
      }),
    );
    final user = parseAuthUser(res.data);
    saveAuthSession(_authStore, res.data, user.id);
    return user;
  }

  @override
  Future<User> register(RegisterInput input) async {
    final res = await _api.run(
      (dio) => dio.post(ApiEndpoints.register, data: {
        'fullName': input.fullName,
        'name': input.fullName,
        'phone': input.phone,
        'password': input.password,
        // City only — governorate never leaves the device.
        if (input.city != null) 'city': input.city,
      }),
    );
    final user = parseAuthUser(res.data);
    saveAuthSession(_authStore, res.data, user.id);
    return user;
  }

  @override
  Future<void> verifyOtp(String code) async {
    await _api.run((dio) => dio.post(ApiEndpoints.verifyOtp, data: {
      'code': code,
    }));
  }

  @override
  Future<void> requestReset(String email) async {
    await _api.run(
      (dio) => dio.post(ApiEndpoints.requestReset, data: {'email': email}),
    );
  }

  @override
  Future<void> resetPassword(String e, String code, String pwd) async {
    await _api.run(
      (dio) => dio.post(ApiEndpoints.resetPassword, data: {
        'email': e,
        'code': code,
        'newPassword': pwd,
        'password': pwd,
      }),
    );
  }

  @override
  Future<User?> currentUser() async {
    final localId = _authStore.userId;
    final res = await _api.run((dio) => dio.get(ApiEndpoints.me));
    try {
      return parseAuthUser(res.data);
    } catch (_) {
      if (localId != null) return User(id: localId);
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _api.run((dio) => dio.post(ApiEndpoints.logout));
    } finally {
      _authStore.clear();
    }
  }

  @override
  Future<User> updateProfile({
    String? fullName,
    String? phone,
    String? Function()? photoPath,
  }) async {
    final res = await _api.run(
      (dio) => dio.patch(ApiEndpoints.updateProfile, data: {
        if (fullName != null) 'fullName': fullName,
        if (fullName != null) 'name': fullName,
        if (phone != null) 'phone': phone,
        // For file upload use multipart: FormData with 'photo' field.
        if (photoPath != null && photoPath() != null) 'photo': photoPath(),
      }),
    );
    return parseAuthUser(res.data);
  }
}
