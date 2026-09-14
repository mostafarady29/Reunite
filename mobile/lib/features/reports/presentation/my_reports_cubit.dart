import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../shared/domain/app_enums.dart';
import '../domain/child_case.dart';
import '../data/repositories/child_case_repository.dart';

sealed class MyReportsState extends Equatable {
  const MyReportsState();

  @override
  List<Object?> get props => [];
}

class MyReportsLoading extends MyReportsState {
  const MyReportsLoading();
}

class MyReportsLoaded extends MyReportsState {
  const MyReportsLoaded(this.reportsList);
  final List<ChildCase> reportsList;

  List<ChildCase> get pending =>
      reportsList.where((r) => r.status == CaseStatus.reported || r.status == CaseStatus.underReview).toList();
  List<ChildCase> get active =>
      reportsList.where((r) => r.status == CaseStatus.published || r.status == CaseStatus.possibleSighting).toList();
  List<ChildCase> get found =>
      reportsList.where((r) => r.status == CaseStatus.childFound).toList();
  List<ChildCase> get closed =>
      reportsList.where((r) => r.status == CaseStatus.caseClosed).toList();

  @override
  List<Object?> get props => [reportsList];
}

class MyReportsError extends MyReportsState {
  const MyReportsError(this.failure);
  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}

class MyReportsCubit extends Cubit<MyReportsState> {
  MyReportsCubit(this._repo) : super(const MyReportsLoading()) {
    load();
  }

  final ReportsRepository _repo;

  Future<void> load() async {
    emit(const MyReportsLoading());
    try {
      final list = await _repo.myReports();
      emit(MyReportsLoaded(list));
    } on UnauthorizedFailure {
      emit(const MyReportsLoaded([]));
    } on AppFailure catch (e) {
      emit(MyReportsError(e));
    } catch (_) {
      emit(const MyReportsLoaded([]));
    }
  }
}
