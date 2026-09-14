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
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(getIt<AuthRepository>()),
      child: const _ForgotView(),
    );
  }
}

class _ForgotView extends StatefulWidget {
  const _ForgotView();

  @override
  State<_ForgotView> createState() => _ForgotViewState();
}

class _ForgotViewState extends State<_ForgotView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<AuthCubit>();
    final result = await cubit.forgotPassword(_email.text.trim());
    if (!context.mounted) return;
    if (result == AuthResult.success) {
      showAppSnackbar(context,
          text: context.tr('auth.otpSubtitle'), type: SnackBarType.success);
      context.router.push(const ResetPasswordRoute());
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
              operationLabel: 'forgot-password',
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
                      child: const Icon(Icons.lock_reset_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: AppDimens.xl),
                    Text(context.tr('auth.forgotTitle'),
                        style: context.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(context.tr('auth.forgotSubtitle'),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.palette.textSecondary,
                        )),
                    const SizedBox(height: AppDimens.xxl),
                    AppTextField(
                      controller: _email,
                      icon: Icons.alternate_email_rounded,
                      hint: context.tr('auth.email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final e = v?.trim() ?? '';
                        final ok =
                            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
                        return ok ? null : context.tr('validation.email');
                      },
                    ),
                    const SizedBox(height: AppDimens.xl),
                    AppButton(
                      label: context.tr('auth.sendCode'),
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