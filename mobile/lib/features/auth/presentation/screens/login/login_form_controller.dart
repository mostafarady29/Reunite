import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/router/app_router.dart';
import '../../auth_cubit.dart';

class LoginFormController extends ChangeNotifier {
  LoginFormController();

  final formKey = GlobalKey<FormState>();
  final phone = TextEditingController();
  final password = TextEditingController();
  bool rememberMe = true;

  void setRememberMe(bool value) {
    rememberMe = value;
    notifyListeners();
  }

  Future<void> submit(BuildContext context) async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<AuthCubit>();
    await cubit.login(
      phone: phone.text.trim(),
      password: password.text,
      rememberMe: rememberMe,
    );
    if (!context.mounted) return;
    if (cubit.state is AuthSuccess) {
      context.router.replaceAll([const AppShellRoute()]);
    }
  }

  void goForgot(BuildContext context) {
    context.router.push(const ForgotPasswordRoute());
  }

  void goRegister(BuildContext context) {
    context.router.push(const RegisterRoute());
  }

  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }
}
