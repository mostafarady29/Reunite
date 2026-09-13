import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/auth_repository.dart';
import '../auth_cubit.dart';
import 'otp/otp_controller.dart';
import 'otp/widgets/otp_code_input.dart';
import 'otp/widgets/otp_footer.dart';
import 'otp/widgets/otp_header.dart';

@RoutePage()
class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(getIt<AuthRepository>()),
      child: const _OtpView(),
    );
  }
}

class _OtpView extends StatefulWidget {
  const _OtpView();

  @override
  State<_OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<_OtpView> {
  late final OtpController _otp = OtpController();

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<AuthCubit>();
    final result = await cubit.submitOtp(_otp.code);
    if (!context.mounted) return;
    if (result == AuthResult.success) {
      showAppSnackbar(
        context,
        text: context.tr('auth.verificationSuccess'),
        type: SnackBarType.success,
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!context.mounted) return;
      context.router.replaceAll([const AppShellRoute()]);
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
            if (state is AuthError) {
              showAppSnackbar(
                context,
                text: context.tr(state.messageKey),
                type: SnackBarType.error,
              );
            }
          },
          builder: (context, state) {
            final loading = state is AuthLoading;
            return ListenableBuilder(
              listenable: _otp,
              builder: (context, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimens.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const OtpHeader(),
                      OtpCodeInput(controller: _otp),
                      OtpFooter(
                        loading: loading,
                        codeValid: _otp.code.length >= 6,
                        seconds: _otp.seconds,
                        onVerify: _submit,
                        onResend: _otp.startTimer,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
