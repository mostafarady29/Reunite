import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/utils/context_extensions.dart';
import '../../../../data/repositories/child_case_repository.dart';
import '../../../../../shared/domain/app_enums.dart';
import '../../../report_cubit.dart';
import 'missing_appbar.dart';
import 'missing_footer.dart';
import 'modern_stepper.dart';
import 'missing_steps_body.dart';

export 'missing_appbar.dart';
export 'missing_footer.dart';
export 'missing_steps_body.dart';
export 'missing_photo_step.dart' show MissingPhotoStep;
export 'missing_basic_step.dart' show MissingBasicStep;
export 'missing_date_step.dart' show MissingDateStep;
export 'missing_appearance_step.dart' show MissingAppearanceStep;
export 'missing_contact_step.dart' show MissingContactStep;
export 'missing_review_step.dart' show MissingReviewStep;
class ModernMissingView extends StatefulWidget {
  const ModernMissingView({super.key});
  @override
  State<ModernMissingView> createState() => _ModernMissingViewState();
}

class _ModernMissingViewState extends State<ModernMissingView> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _lastLocation = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  final _clothing = TextEditingController();
  final _marks = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  DateTime _missingDate = DateTime.now();
  Gender? _gender;
  String? _photoSeed;

  @override
  void dispose() {
    for (final c in [_name, _age, _lastLocation, _city, _area, _clothing, _marks, _description, _phone, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ReportCubit>();
    final step = cubit.step;
    const total = 6;
    const icons = [Icons.camera_alt_rounded, Icons.person_rounded, Icons.event_rounded, Icons.checkroom_rounded, Icons.call_rounded, Icons.verified_rounded];
    const labels = ['Photo', 'Info', 'Date', 'Look', 'Contact', 'Review'];
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: MissingAppBar(
        step: step,
        onBack: () => step > 0 ? cubit.previous() : context.router.maybePop(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: MissingStepper(step: step, total: total, icons: icons, labels: labels),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: AnimatedSwitcher(
                duration: 280.ms,
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                        position: Tween(
                                begin: const Offset(0.04, 0), end: Offset.zero)
                            .animate(anim),
                        child: child)),
                child: MissingStepsBody(
                  step: step,
                  name: _name,
                  age: _age,
                  lastLocation: _lastLocation,
                  city: _city,
                  area: _area,
                  clothing: _clothing,
                  marks: _marks,
                  description: _description,
                  phone: _phone,
                  email: _email,
                  missingDateLabel: _dateLabel(),
                  gender: _gender,
                  photoSeed: _photoSeed,
                  onPhotoChanged: (v) => setState(() => _photoSeed = v),
                  onGender: (g) => setState(() => _gender = g),
                  onPickDate: () => _pickDate(),
                ),
              ),
            ),
          ),
          MissingFooter(
            step: step,
            submitting: cubit.submitting,
            onBack: () => cubit.previous(),
            onNext: () async => _onNext(cubit, step),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(context: context, initialDate: _missingDate, firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)), lastDate: DateTime.now());
    if (p != null) setState(() => _missingDate = p);
  }

  String _dateLabel() => '${_missingDate.day}/${_missingDate.month}/${_missingDate.year}';

  Future<void> _onNext(ReportCubit cubit, int step) async {
    if (step < 5) {
      cubit.next();
      return;
    }
    final c = await cubit.submitMissing(MissingReportInput(
        name: _name.text.trim(),
        age: int.tryParse(_age.text) ?? 0,
        gender: _gender ?? Gender.male,
        missingSince: _missingDate,
        lastKnownLocation: _lastLocation.text.trim(),
        city: _city.text.trim(),
        area: _area.text.trim(),
        clothing: _clothing.text.trim(),
        description: _description.text.trim(),
        distinguishingMarks: _marks.text.trim().isEmpty ? null : _marks.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        photoSeed: _photoSeed));
    if (!mounted) return;
    if (c != null) {
      context.router.replace(ReportConfirmationRoute(caseId: c.id));
    }
  }
}
