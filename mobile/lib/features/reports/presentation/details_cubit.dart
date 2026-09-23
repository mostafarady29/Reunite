import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../shared/domain/app_enums.dart';
import '../domain/child_case.dart';
import '../data/repositories/child_case_repository.dart';

sealed class DetailsState extends Equatable {
  const DetailsState();

  @override
  List<Object?> get props => [];
}

class DetailsLoading extends DetailsState {
  const DetailsLoading();
}

class DetailsLoaded extends DetailsState {
  const DetailsLoaded({
    required this.caseData,
    required this.matches,
    this.failure,
  });

  final ChildCase caseData;
  final List<PossibleMatch> matches;
  final AppFailure? failure;

  @override
  List<Object?> get props => [caseData, matches, failure];
}

class DetailsError extends DetailsState {
  const DetailsError(this.failure);
  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}

class DetailsCubit extends Cubit<DetailsState> {
  DetailsCubit(this._repo, {required this.caseId}) : super(const DetailsLoading()) {
    load();
  }

  final ChildCaseRepository _repo;
  final String caseId;

  Future<void> load() async {
    emit(const DetailsLoading());
    try {
      final caseData = await _repo.getById(caseId);
      List<PossibleMatch> matches = const [];
      if (caseData.isMissing) {
        try {
          matches = await _repo.getPossibleMatches(caseId);
        } catch (_) {
          matches = const [];
        }
      }
      emit(DetailsLoaded(caseData: caseData, matches: matches));
    } on AppFailure catch (e) {
      emit(DetailsError(e));
    }
  }

  Future<void> reportSighting({
    required double latitude,
    required double longitude,
    required DateTime occurredAt,
    required String description,
  }) async {
    await _repo.reportSighting(SightingInput(
      caseId: caseId,
      latitude: latitude,
      longitude: longitude,
      occurredAt: occurredAt,
      description: description,
    ));
    // Refresh status to possibleSighting via local reload.
    final current = state;
    if (current is DetailsLoaded) {
      final updated =
          current.caseData.copyWith(status: CaseStatus.possibleSighting);
      emit(DetailsLoaded(caseData: updated, matches: current.matches));
    }
  }
}
