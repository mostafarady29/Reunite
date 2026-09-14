import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/auth_repository.dart';
import '../auth_cubit.dart';

@RoutePage()
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(getIt<AuthRepository>()),
      child: const _ResetView(),
    );
  }
}

class _ResetView extends StatefulWidget {
  const _ResetView();

  @override
  State<_ResetView> createState() => _ResetViewState();
}

class _ResetViewState extends State<_ResetView> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    for (final c in [_code, _password, _confirm, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<AuthCubit>();
    final result = await cubit.resetPassword(
      email: _email.text.trim(),
      code: _code.text.trim(),
      newPassword: _password.text,
    );
    if (!context.mounted) return;
    if (result == AuthResult.success) {
      showAppSnackbar(context,
          text: context.tr('auth.passwordChanged'), type: SnackBarType.success);
      context.router.replaceAll([const LoginRoute()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBackBar(),
      body: SafeArea(
        top: false,
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            handleAuthError(
              context,
              state,
              operationLabel: 'reset-password',
              onRetry: state is AuthError ? _submit : null,
            );
          },
          builder: (context, state) {
            final loading = state is AuthLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      ),
                      child: const Icon(Icons.password_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: AppDimens.xl),
                    Text(context.tr('auth.resetTitle'),
                        style: context.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(context.tr('auth.resetSubtitle'),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.palette.textSecondary,
                        )),
                    const SizedBox(height: AppDimens.xxl),
                    AppTextField(
                      controller: _code,
                      icon: Icons.confirmation_number_outlined,
                      hint: context.tr('auth.otpTitle'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v ?? '').length >= 6
                          ? null
                          : context.tr('validation.otp'),
                    ),
                    const SizedBox(height: AppDimens.lg),
                    PasswordField(
                      controller: _password,
                      hint: context.tr('auth.password'),
                      validator: (v) => (v ?? '').length >= 8
                          ? null
                          : context.tr('validation.passwordMin'),
                    ),
                    const SizedBox(height: AppDimens.lg),
                    PasswordField(
                      controller: _confirm,
                      hint: context.tr('auth.confirmPassword'),
                      validator: (v) => v == _password.text
                          ? null
                          : context.tr('validation.passwordMatch'),
                    ),
                    const SizedBox(height: AppDimens.xl),
                    AppButton(
                      label: context.tr('auth.resetPassword'),
                      gradient: AppColors.brandGradient,
                      loading: loading,
                      onPressed: loading ? null : _submit,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}