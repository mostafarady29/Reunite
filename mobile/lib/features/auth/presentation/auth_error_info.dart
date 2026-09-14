import 'package:flutter/material.dart';

import 'auth_state.dart';

/// Identified auth error kind. Used to pick icon, title and hint so the
/// user always knows *what* failed instead of seeing a generic message.
enum AuthErrorKind {
  invalidCredentials,
  phoneExists,
  validation,
  otpInvalid,
  network,
  timeout,
  unauthorized,
  notFound,
  permission,
  server,
  unknown,
}

/// UI-ready interpretation of an [AuthError].
///
/// Combines the typed `messageKey`, the raw backend `details`
/// (`HTTP <status> | <endpoint> | <message>`) and per-field errors into
/// something the dialog can render: title key, fallback message, backend
/// message, status code and an action hint.
class AuthErrorInfo {
  const AuthErrorInfo({
    required this.kind,
    required this.titleKey,
    required this.messageKey,
    required this.icon,
    this.backendMessage,
    this.statusCode,
    this.hintKey,
    this.fieldMessages = const {},
  });

  final AuthErrorKind kind;
  final String titleKey;
  final String messageKey;
  final IconData icon;
  final String? backendMessage;
  final int? statusCode;
  final String? hintKey;
  final Map<String, String> fieldMessages;

  /// Short code shown as a pill in the dialog, e.g. `HTTP 401`.
  String? get codeLabel =>
      statusCode != null ? 'HTTP $statusCode' : kind.name.toUpperCase();

  bool get hasBackendMessage =>
      backendMessage != null && backendMessage!.trim().isNotEmpty;

  bool get hasFieldErrors => fieldMessages.isNotEmpty;

  static AuthErrorInfo from(AuthError error) {
    final details = error.details ?? '';
    final lower = details.toLowerCase();
    final status = _extractStatus(details);
    final backendMessage = _extractBackendMessage(details);
    final fields = error.fieldMessages;

    // --- Offline / timeout first (most actionable) ---
    if (error.messageKey == 'error.network') {
      return AuthErrorInfo(
        kind: AuthErrorKind.network,
        titleKey: 'authErrors.networkTitle',
        messageKey: 'error.network',
        icon: Icons.wifi_off_rounded,
        backendMessage: backendMessage,
        statusCode: status,
        hintKey: 'authErrors.networkHint',
        fieldMessages: fields,
      );
    }
    if (error.messageKey == 'error.timeout') {
      return AuthErrorInfo(
        kind: AuthErrorKind.timeout,
        titleKey: 'authErrors.timeoutTitle',
        messageKey: 'error.timeout',
        icon: Icons.timer_off_rounded,
        backendMessage: backendMessage,
        statusCode: status,
        hintKey: 'authErrors.timeoutHint',
        fieldMessages: fields,
      );
    }

    // --- Identify by backend message content ---
    if (_containsAny(lower, [
      'invalid credentials',
      'invalid phone or password',
      'wrong password',
      'incorrect password',
      'invalid login',
      'unauthorized',
      'invalid identifier',
    ])) {
      return AuthErrorInfo(
        kind: AuthErrorKind.invalidCredentials,
        titleKey: 'authErrors.invalidCredentialsTitle',
        messageKey: 'authErrors.invalidCredentialsMsg',
        icon: Icons.lock_outline_rounded,
        backendMessage: backendMessage,
        statusCode: status,
        hintKey: 'authErrors.invalidCredentialsHint',
        fieldMessages: fields,
      );
    }
    if (_containsAny(lower, [
      'already exists',
      'already registered',
      'already in use',
      'duplicate',
      'phone exists',
      'user exists',
      'conflict',
    ])) {
      return AuthErrorInfo(
        kind: AuthErrorKind.phoneExists,
        titleKey: 'authErrors.phoneExistsTitle',
        messageKey: 'authErrors.phoneExistsMsg',
        icon: Icons.person_off_outlined,
        backendMessage: backendMessage,
        statusCode: status,
        hintKey: 'authErrors.phoneExistsHint',
        fieldMessages: fields,
      );
    }
    if (_containsAny(lower, [
      'otp',
      'verification code',
      'invalid code',
      'expired code',
      'code expired',
    ])) {
      return AuthErrorInfo(
        kind: AuthErrorKind.otpInvalid,
        titleKey: 'authErrors.otpTitle',
        messageKey: 'authErrors.otpMsg',
        icon: Icons.sms_failed_outlined,
        backendMessage: backendMessage,
        statusCode: status,
        hintKey: 'authErrors.otpHint',
        fieldMessages: fields,
      );
    }
    if (_containsAny(lower, [
      'validation',
      'invalid phone',
      'invalid password',
      'required',
      'zod',
      'bad request',
    ]) ||
        error.messageKey == 'error.validation' ||
        fields.isNotEmpty) {
      return AuthErrorInfo(
        kind: AuthErrorKind.validation,
        titleKey: 'authErrors.validationTitle',
        messageKey: 'error.validation',
        icon: Icons.rule_rounded,
        backendMessage: backendMessage,
        statusCode: status,
        hintKey: 'authErrors.validationHint',
        fieldMessages: fields,
      );
    }

    // --- Fall back to typed key ---
    switch (error.messageKey) {
      case 'error.unauthorized':
        return AuthErrorInfo(
          kind: AuthErrorKind.unauthorized,
          titleKey: 'authErrors.sessionTitle',
          messageKey: 'error.unauthorized',
          icon: Icons.lock_clock_rounded,
          backendMessage: backendMessage,
          statusCode: status ?? 401,
          hintKey: 'authErrors.sessionHint',
          fieldMessages: fields,
        );
      case 'error.notFound':
        return AuthErrorInfo(
          kind: AuthErrorKind.notFound,
          titleKey: 'authErrors.notFoundTitle',
          messageKey: 'error.notFound',
          icon: Icons.search_off_rounded,
          backendMessage: backendMessage,
          statusCode: status ?? 404,
          fieldMessages: fields,
        );
      case 'error.permission':
        return AuthErrorInfo(
          kind: AuthErrorKind.permission,
          titleKey: 'authErrors.permissionTitle',
          messageKey: 'error.permission',
          icon: Icons.block_rounded,
          backendMessage: backendMessage,
          statusCode: status,
          fieldMessages: fields,
        );
      case 'error.validation':
        return AuthErrorInfo(
          kind: AuthErrorKind.validation,
          titleKey: 'authErrors.validationTitle',
          messageKey: 'error.validation',
          icon: Icons.rule_rounded,
          backendMessage: backendMessage,
          statusCode: status,
          hintKey: 'authErrors.validationHint',
          fieldMessages: fields,
        );
      default:
        return AuthErrorInfo(
          kind: status != null && status >= 500
              ? AuthErrorKind.server
              : AuthErrorKind.unknown,
          titleKey: 'authErrors.genericTitle',
          messageKey: error.messageKey,
          icon: Icons.error_outline_rounded,
          backendMessage: backendMessage,
          statusCode: status,
          hintKey: 'authErrors.genericHint',
          fieldMessages: fields,
        );
    }
  }

  static bool _containsAny(String haystack, List<String> needles) {
    for (final n in needles) {
      if (haystack.contains(n)) return true;
    }
    return false;
  }

  static int? _extractStatus(String details) {
    final match = RegExp(r'HTTP\s*(\d{3})').firstMatch(details);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  /// `details` is `HTTP <status> | <endpoint> | <message>` — the message
  /// is the last segment and is what identifies the exact backend error.
  static String? _extractBackendMessage(String details) {
    if (details.trim().isEmpty) return null;
    final segments =
        details.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty);
    final list = segments.toList();
    if (list.isEmpty) return null;
    // Drop leading `HTTP xxx` segment.
    if (list.first.toUpperCase().startsWith('HTTP')) list.removeAt(0);
    // Drop endpoint-looking segment (`auth/login`, `/api/...`).
    if (list.isNotEmpty && _looksLikeEndpoint(list.first)) {
      list.removeAt(0);
    }
    if (list.isEmpty) return null;
    final msg = list.join(' | ').trim();
    if (msg.isEmpty || msg.toLowerCase() == 'null') return null;
    return msg;
  }

  static bool _looksLikeEndpoint(String s) =>
      s.contains('/') && !s.contains(' ');
}
