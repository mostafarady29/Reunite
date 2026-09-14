import '../../auth/domain/user.dart';

class RegisterInput {
  const RegisterInput({
    required this.fullName,
    required this.phone,
    required this.password,
    this.city,
  });

  final String fullName;
  final String phone;
  final String password;

  /// City only (governorate is UI-only and never sent to the API).
  final String? city;
}

class LoginInput {
  const LoginInput({
    required this.phone,
    required this.password,
    required this.rememberMe,
  });

  final String phone;
  final String password;
  final bool rememberMe;
}

/// Authentication repository abstraction.
abstract class AuthRepository {
  Future<User> login(LoginInput input);

  Future<User> register(RegisterInput input);

  Future<void> verifyOtp(String code);

  Future<void> requestReset(String email);

  Future<void> resetPassword(String email, String code, String newPassword);

  Future<User?> currentUser();

  Future<void> logout();

  Future<User> updateProfile({
    String? fullName,
    String? phone,
    String? Function()? photoPath,
  });
}

/// Mock auth. Accepts any input for a smooth prototype demo.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository();

  User? _current;

  Future<void> _delay() =>
      Future.delayed(const Duration(milliseconds: 500));

  @override
  Future<User> login(LoginInput input) async {
    await _delay();
    return _current = const User(
      id: 'user-1',
      fullName: 'عمر غزال',
      email: 'omar@example.com',
      phone: '01012345678',
      hasVerified: true,
    );
  }

  @override
  Future<User> register(RegisterInput input) async {
    await _delay();
    return _current = User(
      id: 'user-1',
      fullName: input.fullName,
      phone: input.phone,
      hasVerified: false,
      city: input.city,
    );
  }

  @override
  Future<void> verifyOtp(String code) async {
    await _delay();
  }

  @override
  Future<void> requestReset(String email) async {
    await _delay();
  }

  @override
  Future<void> resetPassword(
      String email, String code, String newPassword) async {
    await _delay();
  }

  @override
  Future<User?> currentUser() async {
    await _delay();
    return _current ??
        const User(id: 'user-1', fullName: 'عمر حسن', email: 'omar@example.com');
  }

  @override
  Future<void> logout() async {
    await _delay();
    _current = null;
  }

  @override
  Future<User> updateProfile({
    String? fullName,
    String? phone,
    String? Function()? photoPath,
  }) async {
    await _delay();
    final base = _current ?? const User(id: 'user-1');
    return _current = base.copyWith(
      fullName: fullName ?? base.fullName,
      phone: phone != null ? () => phone : () => base.phone,
      photoPath: photoPath != null ? photoPath : () => base.photoPath,
    );
  }
}