import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';
import 'package:shared/domain/user/repositories/user_repository.dart';
import '../../domain/usecases/admin_watch_bookings.dart';
import '../../domain/usecases/admin_reassign_booking.dart';
import '../../domain/usecases/admin_reschedule_booking.dart';

abstract class AdminBookingDetailsState {}

class AdminBookingDetailsInitial extends AdminBookingDetailsState {}

class AdminBookingDetailsLoading extends AdminBookingDetailsState {}

class AdminBookingDetailsLoaded extends AdminBookingDetailsState {
  final Booking? booking;
  final UserProfile? customer;
  final UserProfile? technician;
  AdminBookingDetailsLoaded({this.booking, this.customer, this.technician});
}

class AdminBookingDetailsSuccess extends AdminBookingDetailsState {
  final String message;
  final Booking? booking;
  final UserProfile? customer;
  final UserProfile? technician;
  AdminBookingDetailsSuccess(
    this.message, {
    this.booking,
    this.customer,
    this.technician,
  });
}

class AdminBookingDetailsError extends AdminBookingDetailsState {
  final String message;
  final Booking? booking;
  final UserProfile? customer;
  final UserProfile? technician;
  AdminBookingDetailsError(
    this.message, {
    this.booking,
    this.customer,
    this.technician,
  });
}

class AdminBookingDetailsCubit extends Cubit<AdminBookingDetailsState> {
  final AdminWatchBookings watchBookings;
  final AdminReassignBooking reassignBooking;
  final AdminRescheduleBooking rescheduleBooking;
  final UserRepository userRepository;
  final BookingRepository bookingRepository;

  AdminBookingDetailsCubit({
    required this.watchBookings,
    required this.reassignBooking,
    required this.rescheduleBooking,
    required this.userRepository,
    required this.bookingRepository,
  }) : super(AdminBookingDetailsInitial());

  StreamSubscription? _bookingSubscription;

  @override
  Future<void> close() {
    _bookingSubscription?.cancel();
    return super.close();
  }

  Future<void> loadData({Booking? booking, String? bookingId}) async {
    final String? targetId = bookingId ?? booking?.id;
    if (targetId == null) return;

    debugPrint('🚀 [AdminBookingDetailsCubit] Loading data for Booking: $targetId');
    emit(AdminBookingDetailsLoading());
    
    _bookingSubscription?.cancel();
    _bookingSubscription = bookingRepository.watchBooking(bookingId: targetId).listen((result) {
      result.fold(
        (failure) {
          debugPrint('❌ [AdminBookingDetailsCubit] Stream Error: ${failure.message}');
          if (state is! AdminBookingDetailsLoaded) {
            emit(AdminBookingDetailsError(failure.message));
          }
        },
        (updatedBooking) async {
          debugPrint('🔄 [AdminBookingDetailsCubit] Booking Updated: ${updatedBooking.status}');
          
          UserProfile? customer;
          UserProfile? technician;

          // If we already have data, we might want to preserve customer/tech to avoid flickering
          if (state is AdminBookingDetailsLoaded) {
            final currentState = state as AdminBookingDetailsLoaded;
            customer = currentState.customer;
            technician = currentState.technician;
          }

          // Load users if they are missing or if IDs changed
          if (updatedBooking.userId != null && (customer == null || customer.uid != updatedBooking.userId)) {
             final customerResult = await userRepository.getUserById(uid: updatedBooking.userId!);
             customer = customerResult.getOrElse((_) => customer!);
          } else if (updatedBooking.userId == null) {
             customer = null;
          }

          if (updatedBooking.technicianId != null && (technician == null || technician.uid != updatedBooking.technicianId)) {
            final techResult = await userRepository.getUserById(uid: updatedBooking.technicianId!);
            technician = techResult.getOrElse((_) => technician!);
          } else if (updatedBooking.technicianId == null) {
            technician = null;
          }

          emit(AdminBookingDetailsLoaded(
            booking: updatedBooking,
            customer: customer,
            technician: technician,
          ));
        },
      );
    });
  }

  Future<void> reassign({
    required String bookingId,
    required String newTechnicianId,
    required String adminId,
    String? reason,
  }) async {
    Booking? currentBooking;
    UserProfile? currentCustomer;
    UserProfile? currentTechnician;
    if (state is AdminBookingDetailsLoaded) {
      final loaded = state as AdminBookingDetailsLoaded;
      currentBooking = loaded.booking;
      currentCustomer = loaded.customer;
      currentTechnician = loaded.technician;
    }

    emit(AdminBookingDetailsLoading());
    final result = await reassignBooking(
      bookingId: bookingId,
      newTechnicianId: newTechnicianId,
      adminId: adminId,
      reason: reason,
    );

    result.fold(
      (l) => emit(AdminBookingDetailsError(l.message, booking: currentBooking, customer: currentCustomer, technician: currentTechnician)),
      (r) => emit(AdminBookingDetailsSuccess('تم إعادة تعيين الفني بنجاح', booking: currentBooking, customer: currentCustomer, technician: currentTechnician)),
    );
  }

  Future<void> reschedule({
    required String bookingId,
    required DateTime newDateTime,
    required String adminId,
    String? reason,
  }) async {
    Booking? currentBooking;
    UserProfile? currentCustomer;
    UserProfile? currentTechnician;
    if (state is AdminBookingDetailsLoaded) {
      final loaded = state as AdminBookingDetailsLoaded;
      currentBooking = loaded.booking;
      currentCustomer = loaded.customer;
      currentTechnician = loaded.technician;
    }

    emit(AdminBookingDetailsLoading());
    final result = await rescheduleBooking(
      bookingId: bookingId,
      newDateTime: newDateTime,
      adminId: adminId,
      reason: reason,
    );

    result.fold(
      (l) => emit(AdminBookingDetailsError(l.message, booking: currentBooking, customer: currentCustomer, technician: currentTechnician)),
      (r) => emit(AdminBookingDetailsSuccess('تم إعادة جدولة الموعد بنجاح', booking: currentBooking, customer: currentCustomer, technician: currentTechnician)),
    );
  }

  Future<void> cancelBooking({
    required String bookingId,
    required String adminId,
    required String reasonCode,
    String? notes,
  }) async {
    Booking? currentBooking;
    UserProfile? currentCustomer;
    UserProfile? currentTechnician;
    if (state is AdminBookingDetailsLoaded) {
      final loaded = state as AdminBookingDetailsLoaded;
      currentBooking = loaded.booking;
      currentCustomer = loaded.customer;
      currentTechnician = loaded.technician;
    }

    emit(AdminBookingDetailsLoading());
    
    final result = await bookingRepository.transitionBooking(
      bookingId: bookingId,
      newStatus: OrderStatus.cancelled,
      actorId: adminId,
      actorRole: 'admin',
      reason: reasonCode,
      notes: notes,
    );

    result.fold(
      (l) => emit(AdminBookingDetailsError(l.message, booking: currentBooking, customer: currentCustomer, technician: currentTechnician)),
      (r) => emit(AdminBookingDetailsSuccess('تم إلغاء الطلب بنجاح', booking: currentBooking, customer: currentCustomer, technician: currentTechnician)),
    );
  }

  Future<void> confirmWhatsappBooking({
    required String bookingId,
  }) async {
    Booking? currentBooking;
    UserProfile? currentCustomer;
    UserProfile? currentTechnician;
    if (state is AdminBookingDetailsLoaded) {
      final loaded = state as AdminBookingDetailsLoaded;
      currentBooking = loaded.booking;
      currentCustomer = loaded.customer;
      currentTechnician = loaded.technician;
    }

    emit(AdminBookingDetailsLoading());
    
    final result = await bookingRepository.adminConfirmWhatsappBooking(
      bookingId: bookingId,
    );

    result.fold(
      (l) => emit(AdminBookingDetailsError(l.message, booking: currentBooking, customer: currentCustomer, technician: currentTechnician)),
      (r) => emit(AdminBookingDetailsSuccess('تم تأكيد حجز الواتساب يدوياً بنجاح وتنشيط الحجز!', booking: currentBooking, customer: currentCustomer, technician: currentTechnician)),
    );
  }

  Future<void> updateBookingDetails({
    required Booking booking,
    required Map<String, dynamic> pricingInputs,
    required BookingPricing price,
  }) async {
    UserProfile? customer;
    UserProfile? technician;
    if (state is AdminBookingDetailsLoaded) {
      final loaded = state as AdminBookingDetailsLoaded;
      customer = loaded.customer;
      technician = loaded.technician;
    } else if (state is AdminBookingDetailsSuccess) {
      final success = state as AdminBookingDetailsSuccess;
      customer = success.customer;
      technician = success.technician;
    }

    emit(AdminBookingDetailsLoading());

    final updatedBooking = booking.copyWith(
      pricingInputs: pricingInputs,
      price: price,
    );

    final result = await bookingRepository.updateBooking(booking: updatedBooking);

    result.fold(
      (l) => emit(AdminBookingDetailsError(l.message, booking: booking, customer: customer, technician: technician)),
      (r) => emit(AdminBookingDetailsSuccess('تم تحديث تفاصيل الطلب والأسعار بنجاح', booking: updatedBooking, customer: customer, technician: technician)),
    );
  }
}
