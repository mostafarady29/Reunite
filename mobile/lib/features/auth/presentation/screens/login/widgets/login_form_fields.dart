import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../login_form_controller.dart';
import 'login_modern_input.dart';
import 'login_modern_password_input.dart';

class LoginFormFields extends StatelessWidget {
  const LoginFormFields({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  final LoginFormController controller;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginModernInput(
          label: context.tr('auth.phone'),
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
          controller: controller.phone,
          delay: 550,
          validator: (v) {
            final p = v?.trim() ?? '';
            if (p.isEmpty) {
              return context.tr('validation.required');
            }
            if (!RegExp(r'^[0-9+\s]{8,}$').hasMatch(p)) {
              return context.tr('validation.phone');
            }
            return null;
          },
        ),
        LoginModernPasswordInput(
          label: context.tr('auth.password'),
          controller: controller.password,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          delay: 600,
          validator: (v) {
            if (v == null || v.isEmpty) {
              return context.tr('validation.required');
            }
            return null;
          },
        ),
      ],
    );
  }
}
