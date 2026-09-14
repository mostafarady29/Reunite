import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  const LoginRequested({
    required this.phone,
    required this.password,
    required this.rememberMe,
  });
  final String phone;
  final String password;
  final bool rememberMe;

  @override
  List<Object?> get props => [phone, password, rememberMe];
}

class RegisterRequested extends AuthEvent {
  const RegisterRequested({
    required this.fullName,
    required this.phone,
    required this.password,
    this.city,
  });
  final String fullName;
  final String phone;
  final String password;
  final String? city;

  @override
  List<Object?> get props => [fullName, phone, password, city];
}

class OtpSubmitted extends AuthEvent {
  const OtpSubmitted(this.code);
  final String code;

  @override
  List<Object?> get props => [code];
}

class ForgotPasswordRequested extends AuthEvent {
  const ForgotPasswordRequested(this.email);
  final String email;

  @override
  List<Object?> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  const ResetPasswordRequested({
    required this.email,
    required this.code,
    required this.newPassword,
  });
  final String email;
  final String code;
  final String newPassword;

  @override
  List<Object?> get props => [email, code, newPassword];
}
