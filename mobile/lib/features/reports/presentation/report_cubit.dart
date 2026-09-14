import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../data/repositories/child_case_repository.dart';
import '../domain/child_case.dart';

sealed class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportIdle extends ReportState {
  const ReportIdle(this.step);
  final int step;

  @override
  List<Object?> get props => [step];
}

class ReportSubmitting extends ReportState {
  const ReportSubmitting(this.step);
  final int step;

  @override
  List<Object?> get props => [step];
}

class ReportSubmitted extends ReportState {
  const ReportSubmitted(this.caseData);
  final ChildCase caseData;

  @override
  List<Object?> get props => [caseData];
}

class ReportError extends ReportState {
  const ReportError(this.failure);
  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}

class ReportCubit extends Cubit<ReportState> {
  ReportCubit(this._repo, {required this.isMissing})
      : super(const ReportIdle(0));

  final ReportsRepository _repo;
  final bool isMissing;
  int _step = 0;

  int get step => _step;

  bool get submitting => state is ReportSubmitting;

  void next() {
    if (_step < 5) {
      _step++;
      emit(ReportIdle(_step));
    }
  }

  void previous() {
    if (_step > 0) {
      _step--;
      emit(ReportIdle(_step));
    }
  }

  Future<ChildCase?> submitMissing(MissingReportInput input) async {
    emit(ReportSubmitting(_step));
    try {
      final caseData = await _repo.submitMissing(input);
      emit(ReportSubmitted(caseData));
      return caseData;
    } on AppFailure catch (e) {
      emit(ReportError(e));
      return null;
    } catch (e) {
      emit(ReportError(ServerFailure(details: e.toString())));
      return null;
    }
  }

  Future<ChildCase?> submitFound(FoundReportInput input) async {
    emit(ReportSubmitting(step));
    try {
      final caseData = await _repo.submitFound(input);
      emit(ReportSubmitted(caseData));
      return caseData;
    } on AppFailure catch (e) {
      emit(ReportError(e));
      return null;
    } catch (e) {
      emit(ReportError(ServerFailure(details: e.toString())));
      return null;
    }
  }
}
