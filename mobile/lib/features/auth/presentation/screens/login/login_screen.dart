import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/app_di.dart';
import '../../../../../core/settings/settings_cubit.dart';
import '../../../../../core/utils/context_extensions.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../data/auth_repository.dart';
import '../../auth_cubit.dart';
import 'login_form_controller.dart';
import 'sections/login_form_card.dart';
import 'sections/login_hero_section.dart';

@RoutePage()
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(getIt<AuthRepository>())),
        BlocProvider.value(value: getIt<AppSettingsCubit>()),
      ],
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => LoginViewState();
}

class LoginViewState extends State<LoginView> {
  late final LoginFormController _c = LoginFormController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: context.palette.background,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          handleAuthError(
            context,
            state,
            operationLabel: 'login',
            onRetry: state is AuthError ? () => _c.submit(context) : null,
          );
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return ListenableBuilder(
            listenable: _c,
            builder: (context, _) {
              return Stack(
                children: [
                  LoginHeroSection(height: size.height * 0.42),
                  LoginFormCard(
                    controller: _c,
                    loading: loading,
                    topOffset: size.height * 0.25,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
