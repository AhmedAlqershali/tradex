part of 'admin_plans_bloc.dart';

abstract class AdminPlansState extends Equatable {
  const AdminPlansState();

  @override
  List<Object?> get props => [];
}

class AdminPlansInitial extends AdminPlansState {
  const AdminPlansInitial();
}

class AdminPlansLoading extends AdminPlansState {
  const AdminPlansLoading({
    this.previousPage,
    this.selectedPlan,
  });

  final AdminPlanPage? previousPage;
  final AdminPlan? selectedPlan;

  @override
  List<Object?> get props => [previousPage, selectedPlan];
}

class AdminPlansLoaded extends AdminPlansState {
  const AdminPlansLoaded({
    required this.page,
    this.selectedPlan,
  });

  final AdminPlanPage page;
  final AdminPlan? selectedPlan;

  @override
  List<Object?> get props => [page, selectedPlan];
}

class AdminPlansFailure extends AdminPlansState {
  const AdminPlansFailure(
    this.message, {
    this.previousPage,
    this.selectedPlan,
  });

  final String message;
  final AdminPlanPage? previousPage;
  final AdminPlan? selectedPlan;

  @override
  List<Object?> get props => [message, previousPage, selectedPlan];
}
