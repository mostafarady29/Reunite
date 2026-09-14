import 'package:equatable/equatable.dart';

import '../domain/user.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess(this.user);
  final User user;

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  const AuthError(
    this.messageKey, {
    this.details,
    this.fieldMessages = const {},
  });
  final String messageKey;

  /// Raw backend message / `HTTP <status> | <endpoint> | <message>`.
  /// Shown in the error dialog so the exact failure is identifiable.
  final String? details;

  /// Per-field validation errors from the backend (`errors` map).
  final Map<String, String> fieldMessages;

  @override
  List<Object?> get props => [messageKey, details, fieldMessages];
}
