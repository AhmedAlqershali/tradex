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
  const AdminAnalyticsLoaded(this.analytics);

  final AdminAnalyticsModel analytics;

  @override
  List<Object?> get props => [analytics];
}

class AdminAnalyticsFailure extends AdminAnalyticsState {
  const AdminAnalyticsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
