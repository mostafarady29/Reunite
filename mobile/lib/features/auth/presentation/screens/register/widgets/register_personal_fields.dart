import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../register_form_controller.dart';
import 'register_location_fields.dart';
import 'register_modern_input.dart';
import 'register_section_label.dart';

class RegisterPersonalFields extends StatelessWidget {
  const RegisterPersonalFields({super.key, required this.controller});

  final RegisterFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RegisterSectionLabel(
          icon: Icons.person_outline_rounded,
          label: 'المعلومات الشخصية',
        ).animate().fadeIn(delay: 530.ms, duration: 400.ms),
        const SizedBox(height: 14),
        RegisterModernInput(
          label: context.tr('auth.fullName'),
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          controller: controller.name,
          delay: 560,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? context.tr('validation.required')
              : null,
        ),
        RegisterModernInput(
          label: context.tr('auth.phone'),
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
          controller: controller.phone,
          delay: 620,
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
        const SizedBox(height: 12),
        RegisterLocationFields(
          governorates: controller.governorateNames,
          cities: controller.citiesOf(controller.governorate),
          governorate: controller.governorate,
          city: controller.city,
          loading: controller.locationsLoading,
          onGovernorateChanged: controller.setGovernorate,
          onCityChanged: controller.setCity,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
