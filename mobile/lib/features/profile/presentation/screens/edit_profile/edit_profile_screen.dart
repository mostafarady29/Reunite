import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/app_di.dart';
import '../../../../../core/theme/app_dimens.dart';
import '../../../../../core/utils/context_extensions.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../auth/data/auth_repository.dart';
import '../../profile_cubit.dart';
import 'widgets/edit_profile_form.dart';

@RoutePage()
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(getIt<AuthRepository>())..load(),
      child: const EditProfileView(),
    );
  }
}

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => EditProfileViewState();
}

class EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _initialName = '';
  String _initialPhone = '';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<ProfileCubit>();
    await cubit.update(
      fullName: _name.text.trim().isEmpty ? null : _name.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
    );
    if (!context.mounted) return;
    showAppSnackbar(context,
        text: context.tr('auth.verificationSuccess'), type: SnackBarType.success);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileCubit>().state;
    if (state is ProfileLoaded) {
      if (_initialName.isEmpty && state.user.fullName.isNotEmpty) {
        _initialName = state.user.fullName;
        _name.text = _initialName;
      }
      if (_initialPhone.isEmpty && state.user.phone != null) {
        _initialPhone = state.user.phone!;
        _phone.text = _initialPhone;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile.editProfile'),
            style: context.textTheme.titleLarge),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.xl),
          child: EditProfileForm(
            formKey: _formKey,
            nameController: _name,
            phoneController: _phone,
            initialName: _initialName,
            onSave: _save,
          ),
        ),
      ),
    );
  }
}
