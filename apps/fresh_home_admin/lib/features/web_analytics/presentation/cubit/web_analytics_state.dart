import 'package:equatable/equatable.dart';
import '../../domain/entities/web_analytics_entity.dart';

abstract class WebAnalyticsState extends Equatable {
  const WebAnalyticsState();

  @override
  List<Object?> get props => [];
}

class WebAnalyticsInitial extends WebAnalyticsState {
  const WebAnalyticsInitial();
}

class WebAnalyticsLoading extends WebAnalyticsState {
  const WebAnalyticsLoading();
}

class WebAnalyticsLoaded extends WebAnalyticsState {
  final WebAnalyticsEntity analytics;

  const WebAnalyticsLoaded(this.analytics);

  @override
  List<Object?> get props => [analytics];
}

class WebAnalyticsError extends WebAnalyticsState {
  final String message;

  const WebAnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}
