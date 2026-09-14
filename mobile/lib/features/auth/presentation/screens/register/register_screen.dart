import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reunitee_app/core/widgets/widgets.dart';

import '../../../../../core/di/app_di.dart';
import '../../../../../core/locations/locations_repository.dart';
import '../../../../../core/settings/settings_cubit.dart';
import '../../../../../core/utils/context_extensions.dart';
import '../../../data/auth_repository.dart';
import '../../auth_cubit.dart';
import 'register_form_controller.dart';
import 'sections/register_form_card.dart';
import 'sections/register_hero_section.dart';

@RoutePage()
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(getIt<AuthRepository>())),
        BlocProvider.value(value: getIt<AppSettingsCubit>()),
      ],
      child: const RegisterView(),
    );
  }
}

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => RegisterViewState();
}

class RegisterViewState extends State<RegisterView> {
  late final RegisterFormController _c =
      RegisterFormController(getIt<LocationsRepository>());

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
            operationLabel: 'register',
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
                  RegisterHeroSection(height: size.height * 0.38),
                  RegisterFormCard(
                    controller: _c,
                    loading: loading,
                    topOffset: size.height * 0.2,
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
