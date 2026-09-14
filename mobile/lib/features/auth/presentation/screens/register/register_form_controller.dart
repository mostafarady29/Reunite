import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reunitee_app/core/widgets/app_snackbar.dart';

import '../../../../../core/locations/location_models.dart';
import '../../../../../core/locations/locations_repository.dart';
import '../../../../../core/router/app_router.dart';
import '../../auth_cubit.dart';

class RegisterFormController extends ChangeNotifier {
  RegisterFormController([LocationsRepository? locations])
      : _locations = locations {
    _loadLocations();
  }

  final LocationsRepository? _locations;

  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool terms = false;
  String? governorate;
  String? city;

  List<Governorate> governorates = const [];
  bool locationsLoading = true;

  List<String> get governorateNames =>
      governorates.map((g) => g.name).toList();

  List<String> citiesOf(String? governorateName) {
    if (governorateName == null) return const [];
    return governorates
        .where((g) => g.name == governorateName)
        .expand((g) => g.cityNames)
        .toList();
  }

  Future<void> _loadLocations() async {
    final repo = _locations;
    if (repo == null) {
      locationsLoading = false;
      notifyListeners();
      return;
    }
    try {
      governorates = await repo.getGovernorates();
    } catch (_) {
      governorates = const [];
    }
    locationsLoading = false;
    notifyListeners();
  }

  void setTerms(bool value) {
    terms = value;
    notifyListeners();
  }

  void setGovernorate(String? value) {
    governorate = value;
    city = null;
    notifyListeners();
  }

  void setCity(String? value) {
    city = value;
    notifyListeners();
  }

  Future<void> submit(BuildContext context) async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (governorate == null || city == null) {
      showAppSnackbar(
        context,
        text: context.tr('validation.cityRequired'),
        type: SnackBarType.warning,
      );
      return;
    }
    if (!terms) {
      showAppSnackbar(
        context,
        text: context.tr('validation.acceptTerms'),
        type: SnackBarType.warning,
      );
      return;
    }
    final cubit = context.read<AuthCubit>();
    final result = await cubit.register(
      fullName: name.text.trim(),
      phone: phone.text.trim(),
      password: password.text,
      // Governorate stays on device — only city is sent to the API.
      city: city,
    );
    if (!context.mounted) return;
    if (result == AuthResult.success) {
      context.router.replace(const OtpRoute());
    }
  }

  @override
  void dispose() {
    for (final c in [name, phone, password, confirm]) {
      c.dispose();
    }
    super.dispose();
  }
}
