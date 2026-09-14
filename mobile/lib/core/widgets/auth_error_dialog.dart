import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/auth/presentation/auth_error_info.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/context_extensions.dart';

bool _authDialogOpen = false;

/// Shows a modern, identifiable auth-error dialog.
///
/// - Title + icon identify the failure kind (wrong password, phone taken,
///   no internet, validation, ...).
/// - The exact backend message is shown so the error is never "unclear".
/// - Per-field errors and technical details are expandable.
/// - Safe to call from any `BlocConsumer` listener; duplicate calls while
///   the dialog is open are ignored.
Future<void> showAuthErrorDialog(
  BuildContext context, {
  required AuthError error,
  String? operationLabel,
  VoidCallback? onRetry,
}) async {
  if (_authDialogOpen) return;
  _authDialogOpen = true;
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) =>
          _AuthErrorDialogContent(error: error, onRetry: onRetry),
    );
  } finally {
    _authDialogOpen = false;
  }
}

/// Convenience for `BlocConsumer<AuthCubit, AuthState>` listeners:
/// shows the dialog on [AuthError], does nothing otherwise.
void handleAuthError(
  BuildContext context,
  AuthState state, {
  String? operationLabel,
  VoidCallback? onRetry,
}) {
  if (state is AuthError && context.mounted) {
    // Defer one frame so it never fires during build/layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showAuthErrorDialog(
        context,
        error: state,
        operationLabel: operationLabel,
        onRetry: onRetry,
      );
    });
  }
}

class _AuthErrorDialogContent extends StatelessWidget {
  const _AuthErrorDialogContent({required this.error, this.onRetry});

  final AuthError error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final info = AuthErrorInfo.from(error);
    final palette = context.palette;
    final code = info.codeLabel;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(icon: info.icon, code: code),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.tr(info.titleKey),
                        textAlign: TextAlign.center,
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(info.messageKey),
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: palette.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      if (info.hasBackendMessage) ...[
                        const SizedBox(height: 14),
                        _BackendMessageBox(message: info.backendMessage!),
                      ],
                      if (info.hasFieldErrors) ...[
                        const SizedBox(height: 12),
                        _FieldErrorsBox(fields: info.fieldMessages),
                      ],
                      if (info.hintKey != null) ...[
                        const SizedBox(height: 12),
                        _HintRow(hint: context.tr(info.hintKey!)),
                      ],
                      if ((error.details ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _DetailsExpander(details: error.details!.trim()),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (info.hasBackendMessage)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text:
                                          'Auth error [${code ?? info.kind.name}]\n'
                                          'key=${error.messageKey}\n'
                                          'details=${error.details ?? '-'}'
                                          '${info.fieldMessages.isEmpty ? '' : '\nfields=${info.fieldMessages}'}',
                                    ),
                                  );
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          context.tr(
                                            'authErrors.copied',
                                          ),
                                        ),
                                        duration:
                                            const Duration(seconds: 2),
                                      ),
                                    );
                                },
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  context.tr('authErrors.copyDetails'),
                                ),
                              ),
                            ),
                          if (info.hasBackendMessage)
                            const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.emergency,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(
                                  0,
                                  AppDimens.buttonHeight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusMd,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                onRetry?.call();
                              },
                              child: Text(
                                onRetry != null
                                    ? context.tr('authErrors.retry')
                                    : context.tr('common.done'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.icon, required this.code});

  final IconData icon;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final String? codeLabel = code;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: const BoxDecoration(
        gradient: AppColors.emergencyGradient,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          if (codeLabel != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                codeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BackendMessageBox extends StatelessWidget {
  const _BackendMessageBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.emergencySoft,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.emergency.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.emergency,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('authErrors.serverSays'),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.emergency,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldErrorsBox extends StatelessWidget {
  const _FieldErrorsBox({required this.fields});

  final Map<String, String> fields;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('authErrors.fieldErrors'),
            style: context.textTheme.labelSmall?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          for (final entry in fields.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: palette.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lightbulb_outline_rounded,
          size: 18,
          color: palette.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hint,
            style: context.textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsExpander extends StatelessWidget {
  const _DetailsExpander({required this.details});

  final String details;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        dense: true,
        iconColor: palette.textMuted,
        collapsedIconColor: palette.textMuted,
        title: Text(
          context.tr('authErrors.technicalDetails'),
          style: context.textTheme.labelSmall?.copyWith(
            color: palette.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: SelectableText(
              details,
              style: context.textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
