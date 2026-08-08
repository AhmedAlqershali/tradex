part of 'admin_plans_bloc.dart';

abstract class AdminPlansEvent extends Equatable {
  const AdminPlansEvent();

  @override
  List<Object?> get props => [];
}

class AdminPlansLoadRequested extends AdminPlansEvent {
  const AdminPlansLoadRequested();
}

class AdminPlansSearchChanged extends AdminPlansEvent {
  const AdminPlansSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

class AdminPlansStatusFilterChanged extends AdminPlansEvent {
  const AdminPlansStatusFilterChanged(this.status);

  final String? status;

  @override
  List<Object?> get props => [status];
}

class AdminPlansPageRequested extends AdminPlansEvent {
  const AdminPlansPageRequested(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

class AdminPlanDetailsRequested extends AdminPlansEvent {
  const AdminPlanDetailsRequested(this.planId);

  final String planId;

  @override
  List<Object?> get props => [planId];
}

class AdminPlanCreateRequested extends AdminPlansEvent {
  const AdminPlanCreateRequested({
    required this.name,
    required this.displayName,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.storeLimit,
    required this.features,
    required this.status,
    this.aiUsageLimit,
    this.productLimit,
  });

  final String name;
  final String displayName;
  final double monthlyPrice;
  final double yearlyPrice;
  final int? aiUsageLimit;
  final int? productLimit;
  final int storeLimit;
  final List<String> features;
  final String status;

  @override
  List<Object?> get props => [
        name,
        displayName,
        monthlyPrice,
        yearlyPrice,
        aiUsageLimit,
        productLimit,
        storeLimit,
        features,
        status,
      ];
}

class AdminPlanUpdateRequested extends AdminPlansEvent {
  const AdminPlanUpdateRequested({
    required this.planId,
    this.name,
    this.displayName,
    this.monthlyPrice,
    this.yearlyPrice,
    this.aiUsageLimit,
    this.productLimit,
    this.storeLimit,
    this.features,
    this.status,
  });

  final String planId;
  final String? name;
  final String? displayName;
  final double? monthlyPrice;
  final double? yearlyPrice;
  final int? aiUsageLimit;
  final int? productLimit;
  final int? storeLimit;
  final List<String>? features;
  final String? status;

  @override
  List<Object?> get props => [
        planId,
        name,
        displayName,
        monthlyPrice,
        yearlyPrice,
        aiUsageLimit,
        productLimit,
        storeLimit,
        features,
        status,
      ];
}

class AdminPlanDeleteRequested extends AdminPlansEvent {
  const AdminPlanDeleteRequested(this.planId);

  final String planId;

  @override
  List<Object?> get props => [planId];
}
