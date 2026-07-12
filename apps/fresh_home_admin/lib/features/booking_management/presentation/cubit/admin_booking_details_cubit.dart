import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';
import 'package:shared/domain/user/repositories/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:fresh_home_admin/features/user_management/domain/repositories/user_management_repository.dart';
import 'package:shared/domain/booking/use_cases/booking/get_available_days_use_case.dart';
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
  final String? warningMessage;
  final DateTime? suggestedRescheduleDate;
  AdminBookingDetailsSuccess(
    this.message, {
    this.booking,
    this.customer,
    this.technician,
    this.warningMessage,
    this.suggestedRescheduleDate,
  });
}

class AdminBookingDetailsError extends AdminBookingDetailsState {
  final String message;
  final Booking? booking;
  final UserProfile? customer;
  final UserProfile? technician;
  final DateTime? suggestedRescheduleDate;
  AdminBookingDetailsError(
    this.message, {
    this.booking,
    this.customer,
    this.technician,
    this.suggestedRescheduleDate,
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
          if (isClosed) return;
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

          if (isClosed) return;
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
    debugPrint('🔍 [AdminBookingDetailsCubit] reassign: bookingId="$bookingId", newTechnicianId="$newTechnicianId", adminId="$adminId", reason="$reason"');
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

    if (isClosed) {
      debugPrint('⚠️ [AdminBookingDetailsCubit] Cubit was closed before reassign completed.');
      return;
    }
    result.fold(
      (l) {
        debugPrint('❌ [AdminBookingDetailsCubit] Reassign Technician Error: ${l.message}');
        emit(AdminBookingDetailsError(l.message, booking: currentBooking, customer: currentCustomer, technician: currentTechnician));
      },
      (r) {
        debugPrint('✅ [AdminBookingDetailsCubit] Reassign Technician Success!');
        emit(AdminBookingDetailsSuccess('تم إعادة تعيين الفني بنجاح', booking: currentBooking, customer: currentCustomer, technician: currentTechnician));
      },
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

    if (isClosed) return;
    result.fold(
      (l) {
        debugPrint('❌ [AdminBookingDetailsCubit] Reschedule Booking Error: ${l.message}');
        emit(AdminBookingDetailsError(l.message, booking: currentBooking, customer: currentCustomer, technician: currentTechnician));
      },
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

    if (isClosed) return;
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

    if (isClosed) return;
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
    Booking? currentBooking;
    UserProfile? customer;
    UserProfile? technician;
    if (state is AdminBookingDetailsLoaded) {
      final loaded = state as AdminBookingDetailsLoaded;
      currentBooking = loaded.booking;
      customer = loaded.customer;
      technician = loaded.technician;
    } else if (state is AdminBookingDetailsSuccess) {
      final success = state as AdminBookingDetailsSuccess;
      currentBooking = success.booking;
      customer = success.customer;
      technician = success.technician;
    }

    emit(AdminBookingDetailsLoading());

    // 1. Check if service changed
    final bool isServiceChanged = currentBooking != null && 
        booking.serviceId != null && 
        currentBooking.serviceId != booking.serviceId;

    String? finalTechId = booking.technicianId;
    String successMessage = 'تم تحديث تفاصيل الطلب والأسعار بنجاح';
    String? warningMessage;
    DateTime? suggestedRescheduleDate;

    if (isServiceChanged) {
      final String newServiceId = booking.serviceId!;
      final String? currentTechId = currentBooking.technicianId;

      bool currentTechHasSkill = false;
      if (currentTechId != null) {
        // Query if current technician has the new skill
        try {
          final skillCheck = await Supabase.instance.client
              .from('technician_skills')
              .select('id')
              .eq('technician_id', currentTechId)
              .eq('sub_service_id', newServiceId)
              .eq('is_active', true)
              .maybeSingle();
          currentTechHasSkill = skillCheck != null;
        } catch (e) {
          debugPrint('Error checking technician skill: $e');
        }
      }

      if (currentTechId != null && currentTechHasSkill) {
        // Option 1: Keep the current technician
        debugPrint('ℹ️ [updateBookingDetails] Current technician has the skill. Keeping assignment.');
        finalTechId = currentTechId;
      } else {
        // Option 2 & 3: Assign to closest available technician, or reject and suggest reschedule
        debugPrint('ℹ️ [updateBookingDetails] Current technician does not have the skill or is null. Finding available technicians on ${booking.scheduledAt}');
        
        try {
          // Get available technicians for the booking date and new service
          final list = await GetIt.I<UserManagementRepository>()
              .getTechniciansBySubService(newServiceId, date: booking.scheduledAt);
          
          if (list.isNotEmpty) {
            // Find the best available technician
            final newTech = list.first;
            finalTechId = newTech.uid;
            successMessage = 'تم تغيير الخدمة وإسناد الطلب للفني المتاح "${newTech.fullName}"';
            debugPrint('✅ [updateBookingDetails] Assigned to new available technician: $finalTechId');
          } else {
            // No technicians available on this day -> Reject the update!
            debugPrint('⚠️ [updateBookingDetails] No available technicians found on ${booking.scheduledAt}. Rejecting service change.');
            
            // Find the closest available day in the next 30 days
            final getAvailableDays = GetIt.instance<GetAvailableDaysUseCase>();
            final daysResult = await getAvailableDays(
              serviceId: newServiceId,
              startDate: DateTime.now(),
              endDate: DateTime.now().add(const Duration(days: 30)),
            );
            
            daysResult.fold(
              (f) => debugPrint('Error loading available days: ${f.message}'),
              (days) {
                final availableDays = days.where((d) => d.isAvailable);
                if (availableDays.isNotEmpty) {
                  suggestedRescheduleDate = availableDays.first.date;
                  debugPrint('ℹ️ [updateBookingDetails] Suggested reschedule date: $suggestedRescheduleDate');
                }
              },
            );

            emit(AdminBookingDetailsError(
              'لا يمكن تغيير الخدمة لعدم توفر فنيين مؤهلين في هذا اليوم. يرجى اختيار موعد آخر أو التراجع.',
              booking: currentBooking,
              customer: customer,
              technician: technician,
              suggestedRescheduleDate: suggestedRescheduleDate,
            ));
            return; // Reject and stop
          }
        } catch (e) {
          debugPrint('Error finding available technicians: $e');
          emit(AdminBookingDetailsError(
            'حدث خطأ أثناء فحص الفنيين المتاحين: $e',
            booking: currentBooking,
            customer: customer,
            technician: technician,
          ));
          return; // Reject and stop
        }
      }
    }

    final updatedBooking = booking.copyWith(
      pricingInputs: pricingInputs,
      price: price,
      technicianId: finalTechId,
      clearAssignedAt: finalTechId == null, // Clear assignedAt timestamp if unassigned
    );

    final result = await bookingRepository.updateBooking(booking: updatedBooking);

    if (isClosed) return;
    result.fold(
      (l) {
        // ignore: avoid_print
        print('==================================================================');
        // ignore: avoid_print
        print('❌ [AdminBookingDetailsCubit] Update Booking Details Error: ${l.message}');
        // ignore: avoid_print
        print('==================================================================');
        debugPrint('❌ [AdminBookingDetailsCubit] Update Booking Details Error: ${l.message}');
        emit(AdminBookingDetailsError(l.message, booking: currentBooking, customer: customer, technician: technician));
      },
      (r) {
        // Reload all data so that the correct technician details are fetched and updated in the screen
        loadData(bookingId: booking.id);
        
        emit(AdminBookingDetailsSuccess(
          successMessage,
          booking: updatedBooking,
          customer: customer,
          technician: null,
          warningMessage: warningMessage,
          suggestedRescheduleDate: suggestedRescheduleDate,
        ));
      },
    );
  }
}
