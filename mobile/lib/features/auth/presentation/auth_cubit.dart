import 'package:bloc/bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/stores.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';
import 'auth_state.dart';

export 'auth_events.dart';
export 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const AuthInitial());

  final AuthRepository _repo;

  Future<AuthResult> _persist(User user) async {
    final store = getIt<AuthStore>();
    store.saveSession(
      token: 'demo-token-${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      refreshToken: 'demo-refresh',
    );
    emit(AuthSuccess(user));
    return AuthResult.success;
  }

  String _mapFailure(AppFailure failure) =>
      failure.details != null && failure.details!.isNotEmpty
          ? failure.details!
          : failure.messageKey;

  Future<AuthResult> login({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.login(LoginInput(
        identifier: identifier,
        password: password,
        rememberMe: rememberMe,
      ));
      return await _persist(user);
    } on AppFailure catch (e) {
      emit(AuthError(_mapFailure(e)));
      return AuthResult.failure;
    }
  }

  Future<AuthResult> register({
    required String fullName,
    required String phone,
    required String password,
    String? city,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.register(RegisterInput(
        fullName: fullName,
        phone: phone,
        password: password,
        city: city,
      ));
      return await _persist(user);
    } on AppFailure catch (e) {
      emit(AuthError(_mapFailure(e)));
      return AuthResult.failure;
    }
  }

  Future<AuthResult> submitOtp(String code) async {
    emit(const AuthLoading());
    try {
      await _repo.verifyOtp(code);
      emit(const AuthSuccess(User(id: 'pending')));
      return AuthResult.success;
    } on AppFailure catch (e) {
      emit(AuthError(_mapFailure(e)));
      return AuthResult.failure;
    }
  }

  Future<AuthResult> forgotPassword(String email) async {
    emit(const AuthLoading());
    try {
      await _repo.requestReset(email);
      emit(const AuthInitial());
      return AuthResult.success;
    } on AppFailure catch (e) {
      emit(AuthError(_mapFailure(e)));
      return AuthResult.failure;
    }
  }

  Future<AuthResult> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    emit(const AuthLoading());
    try {
      await _repo.resetPassword(email, code, newPassword);
      emit(const AuthSuccess(User(id: 'reset')));
      return AuthResult.success;
    } on AppFailure catch (e) {
      emit(AuthError(_mapFailure(e)));
      return AuthResult.failure;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    getIt<AuthStore>()
      ..clear()
      ..saveGuest();
    emit(const AuthInitial());
  }
}

enum AuthResult { success, failure }
