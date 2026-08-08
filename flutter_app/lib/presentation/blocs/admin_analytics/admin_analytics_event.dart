part of 'admin_analytics_bloc.dart';

abstract class AdminAnalyticsEvent extends Equatable {
  const AdminAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class AdminAnalyticsLoadRequested extends AdminAnalyticsEvent {
  const AdminAnalyticsLoadRequested();
}
