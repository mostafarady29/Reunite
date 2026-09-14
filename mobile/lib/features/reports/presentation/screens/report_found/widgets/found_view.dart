import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/utils/context_extensions.dart';
import '../../../../data/repositories/child_case_repository.dart';
import '../../../../../shared/domain/app_enums.dart';
import '../../../report_cubit.dart';
import 'found_hero.dart';
import 'found_appbar.dart';
import 'found_footer.dart';
import 'found_photo_section.dart';
import 'found_age_gender_section.dart';
import 'found_location_section.dart';
import 'found_appearance_section.dart';

export 'found_photo_section.dart';
export 'found_age_gender_section.dart';
export 'found_location_section.dart';
export 'found_appearance_section.dart';
export 'found_appbar.dart';
export 'found_footer.dart';

/// Thin composition for the found flow. Sections live in their own files.
/// No logic changes.
class ModernFoundView extends StatefulWidget {
  const ModernFoundView({super.key});
  @override
  State<ModernFoundView> createState() => _ModernFoundViewState();
}

class _ModernFoundViewState extends State<ModernFoundView> {
  final _age = TextEditingController();
  final _foundLocation = TextEditingController();
  final _clothing = TextEditingController();
  final _description = TextEditingController();
  final _extra = TextEditingController();
  Gender? _gender;
  String? _photoSeed;

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final mime = picked.mimeType ?? 'image/jpeg';
        final base64String = 'data:$mime;base64,${base64Encode(bytes)}';
        setState(() => _photoSeed = base64String);
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  @override
  void dispose() {
    for (final c in [_age, _foundLocation, _clothing, _description, _extra]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ReportCubit>();
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: FoundAppBar(onClose: () => context.router.maybePop()),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FoundHero()
                      .animate()
                      .fadeIn(duration: 380.ms)
                      .slideY(begin: 0.05),
                  const SizedBox(height: 16),
                  FoundPhotoSection(
                    photoSeed: _photoSeed,
                    onChanged: _pickPhoto,
                    onClear: () => setState(() => _photoSeed = null),
                  ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.04),
                  const SizedBox(height: 14),
                  FoundAgeGenderSection(
                    age: _age,
                    gender: _gender,
                    onGender: (g) => setState(() => _gender = g),
                  ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.04),
                  const SizedBox(height: 14),
                  FoundLocationSection(foundLocation: _foundLocation)
                      .animate()
                      .fadeIn(delay: 160.ms)
                      .slideY(begin: 0.04),
                  const SizedBox(height: 14),
                  FoundAppearanceSection(
                    clothing: _clothing,
                    description: _description,
                    extra: _extra,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.04),
                  const SizedBox(height: 14),
                  const FoundQuickCheck().animate().fadeIn(delay: 240.ms),
                ],
              ),
            ),
          ),
          FoundFooter(
            submitting: cubit.submitting,
            onSubmit: () async => _submit(cubit),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(ReportCubit cubit) async {
    final caseData = await cubit.submitFound(FoundReportInput(
        photoSeed: _photoSeed,
        estimatedAge: int.tryParse(_age.text) ?? 0,
        gender: _gender ?? Gender.male,
        foundSince: DateTime.now(),
        foundLocation: _foundLocation.text.trim(),
        city: '',
        area: '',
        clothing: _clothing.text.trim(),
        description: _description.text.trim(),
        extraInfo: _extra.text.trim()));
    if (!mounted || caseData == null) return;
    context.router.replace(ReportConfirmationRoute(caseId: caseData.id));
  }
}
