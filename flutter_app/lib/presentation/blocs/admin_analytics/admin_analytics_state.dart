part of 'admin_analytics_bloc.dart';

abstract class AdminAnalyticsState extends Equatable {
  const AdminAnalyticsState();

  @override
  List<Object?> get props => [];
}

class AdminAnalyticsInitial extends AdminAnalyticsState {
  const AdminAnalyticsInitial();
}

class AdminAnalyticsLoading extends AdminAnalyticsState {
  const AdminAnalyticsLoading();
}

class AdminAnalyticsLoaded extends AdminAnalyticsState {
  const AdminAnalyticsLoaded(
    this.analytics, {
    this.aiInsight,
    this.aiLoading = false,
    this.aiError,
  });

  final AdminAnalyticsModel analytics;
  final AdminAiInsight? aiInsight;
  final bool aiLoading;
  final String? aiError;

  @override
  List<Object?> get props => [analytics, aiInsight, aiLoading, aiError];
}

class AdminAnalyticsFailure extends AdminAnalyticsState {
  const AdminAnalyticsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
