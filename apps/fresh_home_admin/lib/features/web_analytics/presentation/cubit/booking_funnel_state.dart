import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_funnel_entity.dart';

abstract class BookingFunnelState extends Equatable {
  const BookingFunnelState();

  @override
  List<Object?> get props => [];
}

class BookingFunnelInitial extends BookingFunnelState {
  const BookingFunnelInitial();
}

class BookingFunnelLoading extends BookingFunnelState {
  const BookingFunnelLoading();
}

class BookingFunnelLoaded extends BookingFunnelState {
  final BookingFunnelEntity funnel;

  const BookingFunnelLoaded(this.funnel);

  @override
  List<Object?> get props => [funnel];
}

class BookingFunnelEmpty extends BookingFunnelState {
  const BookingFunnelEmpty();
}

class BookingFunnelError extends BookingFunnelState {
  final String message;

  const BookingFunnelError(this.message);

  @override
  List<Object?> get props => [message];
}
