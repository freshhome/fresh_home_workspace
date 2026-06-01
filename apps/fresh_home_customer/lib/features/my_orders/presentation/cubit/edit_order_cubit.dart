import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/booking/use_cases/booking/transition_booking_use_case.dart';
import 'package:shared/domain/booking/use_cases/booking/update_booking_schedule_use_case.dart';
import 'package:shared/domain/booking/use_cases/booking/update_booking_address_use_case.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/entities/user/phone.dart';
import 'package:shared_features/shared_features.dart';

part 'edit_order_state.dart';

class EditOrderCubit extends Cubit<EditOrderState> {
  final SupabaseClient supabase;
  final ProfileRepository profileRepository;
  final AuthLocalDataSource localDataSource;
  final TransitionBookingUseCase transitionBooking;
  final UpdateBookingScheduleUseCase updateBookingScheduleUseCase;
  final UpdateBookingAddressUseCase updateBookingAddressUseCase;

  EditOrderCubit({
    required this.supabase,
    required this.profileRepository,
    required this.localDataSource,
    required this.transitionBooking,
    required this.updateBookingScheduleUseCase,
    required this.updateBookingAddressUseCase,
  }) : super(EditOrderInitial());

  Future<void> updateOrderSchedule({
    required String orderId,
    required DateTime scheduledAt,
  }) async {
    emit(EditOrderLoading());
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final result = await updateBookingScheduleUseCase(UpdateBookingScheduleParams(
        bookingId: orderId,
        newDay: scheduledAt,
        newTimeSlot: '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
        actorId: user.id,
      ));

      result.fold(
        (failure) => emit(EditOrderFailure(message: failure.message)),
        (_) => emit(EditOrderSuccess()),
      );
    } catch (e) {
      emit(EditOrderFailure(message: e.toString()));
    }
  }

  Future<void> updateOrderAddress({
    required String orderId,
    required Address address,
    required Contact contact,
  }) async {
    emit(EditOrderLoading());
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final syncedAddress = await _syncNewDataToProfile(address, contact);

      final result = await updateBookingAddressUseCase(UpdateBookingAddressParams(
        bookingId: orderId,
        address: syncedAddress ?? address,
        contact: contact,
        actorId: user.id,
      ));

      result.fold(
        (failure) => emit(EditOrderFailure(message: failure.message)),
        (_) => emit(EditOrderSuccess()),
      );
    } catch (e) {
      emit(EditOrderFailure(message: e.toString()));
    }
  }

  Future<Address?> _syncNewDataToProfile(Address usedAddress, Contact usedContact) async {
    final result = await profileRepository.loadProfile();
    final profile = result.fold((_) => null, (p) => p);
    if (profile == null) return usedAddress;
    
    final usedPhone = usedContact.phone.firstOrNull;
    if (usedPhone == null) return usedAddress;

    final addresses = profile.clientProfile?.addresses ?? [];
    final phones = profile.clientProfile?.phoneNumbers ?? [];

    bool isNewAddress = !addresses.any((a) =>
        a.governorate == usedAddress.governorate &&
        a.city == usedAddress.city &&
        a.street == usedAddress.street &&
        a.buildingNumber == usedAddress.buildingNumber &&
        a.floorNumber == usedAddress.floorNumber &&
        a.apartmentNumber == usedAddress.apartmentNumber);

    bool isNewPhone = !phones.any((p) => p.phoneNumber == usedPhone);

    if (isNewAddress) {
      await profileRepository.addAddress(
        address: Address(
          governorate: usedAddress.governorate,
          city: usedAddress.city,
          street: usedAddress.street,
          buildingNumber: usedAddress.buildingNumber,
          floorNumber: usedAddress.floorNumber,
          apartmentNumber: usedAddress.apartmentNumber,
        ),
      );
    }

    if (isNewPhone) {
      final updatedPhones = List<Phone>.from(phones)
        ..add(Phone(
          id: '',
          userId: profile.user.uid,
          phoneNumber: usedPhone,
          isPrimary: phones.isEmpty,
          isVerified: false,
          createdAt: DateTime.now(),
        ));
      await profileRepository.updatePhoneNumbers(phoneNumbers: updatedPhones);
    }
    
    Address? finalAddress = usedAddress;
    final updatedResult = await profileRepository.loadProfile();
    updatedResult.fold((_) => null, (updatedProfile) {
      final updatedAddresses = updatedProfile.clientProfile?.addresses ?? [];
      finalAddress = updatedAddresses.firstWhere(
        (a) =>
            a.governorate == usedAddress.governorate &&
            a.city == usedAddress.city &&
            a.street == usedAddress.street &&
            a.buildingNumber == usedAddress.buildingNumber &&
            a.floorNumber == usedAddress.floorNumber &&
            a.apartmentNumber == usedAddress.apartmentNumber,
        orElse: () => usedAddress,
      );
    });
    return finalAddress;
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    emit(EditOrderLoading());
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final result = await transitionBooking(TransitionBookingParams(
        bookingId: orderId,
        newStatus: status,
        actorId: user.id,
        actorRole: 'customer',
        reason: 'User triggered status update',
      ));

      result.fold(
        (failure) => emit(EditOrderFailure(message: failure.message)),
        (_) => emit(EditOrderSuccess()),
      );
    } catch (e) {
      emit(EditOrderFailure(message: e.toString()));
    }
  }
}
