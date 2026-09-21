import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_funnel_entity.dart';

enum FunnelDateFilter {
  today,
  all,
  last7Days,
  custom,
}

abstract class BookingFunnelState extends Equatable {
  final FunnelDateFilter filter;
  final DateTime? customDate;

  const BookingFunnelState({
    this.filter = FunnelDateFilter.all,
    this.customDate,
  });

  @override
  List<Object?> get props => [filter, customDate];
}

class BookingFunnelInitial extends BookingFunnelState {
  const BookingFunnelInitial({
    super.filter = FunnelDateFilter.all,
    super.customDate,
  });
}

class BookingFunnelLoading extends BookingFunnelState {
  const BookingFunnelLoading({
    super.filter = FunnelDateFilter.all,
    super.customDate,
  });
}

class BookingFunnelLoaded extends BookingFunnelState {
  final BookingFunnelEntity funnel;

  const BookingFunnelLoaded(
    this.funnel, {
    super.filter = FunnelDateFilter.all,
    super.customDate,
  });

  @override
  List<Object?> get props => [funnel, filter, customDate];
}

class BookingFunnelEmpty extends BookingFunnelState {
  const BookingFunnelEmpty({
    super.filter = FunnelDateFilter.all,
    super.customDate,
  });
}

class BookingFunnelError extends BookingFunnelState {
  final String message;

  const BookingFunnelError(
    this.message, {
    super.filter = FunnelDateFilter.all,
    super.customDate,
  });

  @override
  List<Object?> get props => [message, filter, customDate];
}
