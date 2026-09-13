import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/di/app_di.dart';
import '../../../core/storage/stores.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user.dart';
import '../../reports/data/repositories/child_case_repository.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(
    this.user, {
    this.reportsCount = 0,
    this.findingsCount = 0,
    this.missingCount = 0,
    this.foundCount = 0,
  });

  final User user;
  final int reportsCount;
  final int findingsCount;
  final int missingCount;
  final int foundCount;

  @override
  List<Object?> get props => [
        user,
        reportsCount,
        findingsCount,
        missingCount,
        foundCount,
      ];
}

class ProfileError extends ProfileState {
  const ProfileError(this.failure);
  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repo, [this._reportsRepo]) : super(const ProfileLoading());

  final AuthRepository _repo;
  final ReportsRepository? _reportsRepo;

  Future<void> load() async {
    emit(const ProfileLoading());
    try {
      final user = await _repo.currentUser();
      int reportsCount = 0;
      int findingsCount = 0;
      int missingCount = 0;
      int foundCount = 0;

      if (_reportsRepo != null) {
        try {
          final reports = await _reportsRepo.myReports();
          final findings = await _reportsRepo.myFindings();
          reportsCount = reports.length;
          findingsCount = findings.length;
          missingCount = reports.where((c) => c.isMissing).length;
          foundCount = reports.where((c) => c.isFound).length + findings.length;
        } catch (_) {}
      }

      emit(ProfileLoaded(
        user ?? const User(id: 'guest', fullName: ''),
        reportsCount: reportsCount,
        findingsCount: findingsCount,
        missingCount: missingCount,
        foundCount: foundCount,
      ));
    } on AppFailure catch (e) {
      emit(ProfileError(e));
    }
  }

  Future<void> update({
    String? fullName,
    String? phone,
    String? Function()? photoPath,
  }) async {
    try {
      final user = await _repo.updateProfile(
        fullName: fullName,
        phone: phone,
        photoPath: photoPath,
      );
      final current = state;
      final reportsCount = current is ProfileLoaded ? current.reportsCount : 0;
      final findingsCount = current is ProfileLoaded ? current.findingsCount : 0;
      final missingCount = current is ProfileLoaded ? current.missingCount : 0;
      final foundCount = current is ProfileLoaded ? current.foundCount : 0;

      emit(ProfileLoaded(
        user,
        reportsCount: reportsCount,
        findingsCount: findingsCount,
        missingCount: missingCount,
        foundCount: foundCount,
      ));
    } on AppFailure catch (e) {
      emit(ProfileError(e));
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    getIt<AuthStore>()
      ..clear()
      ..saveGuest();
  }
}
