import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shared/data/booking/models/remote/booking_remote_model.dart';
import 'package:shared/core/error/exceptions.dart';

abstract class BookingRemoteDataSource {
  Future<String> createBooking({required BookingRemoteModel booking});
  Future<BookingRemoteModel> getBookingById(String id);
  Future<List<BookingRemoteModel>> getUserBookings(String userId);
  Stream<List<BookingRemoteModel>> watchUserBookings(String userId);
  Stream<List<BookingRemoteModel>> watchAllBookings({List<String>? serviceNames});
  Stream<BookingRemoteModel> watchBooking(String bookingId);
  Future<void> updateBooking({required BookingRemoteModel booking});
  Future<void> transitionBooking({
    required String bookingId,
    required String newStatus,
    required String actorId,
    required String actorRole,
    String? reason,
    String? notes,
    Map<String, dynamic>? metadata,
  });
  Future<void> updateBookingSchedule({
    required String bookingId,
    required DateTime newDay,
    required String newTimeSlot,
    required String actorId,
  });
  Future<void> updateBookingAddress({
    required String bookingId,
    required Map<String, dynamic> addressSnapshot,
    required Map<String, dynamic> contactSnapshot,
    required String actorId,
  });
  Future<void> cancelBooking(String bookingId);
  Future<Map<String, dynamic>> calculateBookingPrice({
    required String subServiceId,
    required Map<String, dynamic> pricingInputs,
  });
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final SupabaseClient _supabase;
  final String _tableName = 'bookings';

  BookingRemoteDataSourceImpl(this._supabase);

  @override
  Future<String> createBooking({required BookingRemoteModel booking}) async {
    try {
      final newBookingUuid = await _supabase.rpc(
        'create_atomic_booking',
        params: {
          'p_user_id': booking.userId,
          'p_sub_service_id': booking.serviceId,
          'p_technician_id': booking.technicianId,
          'p_scheduled_day': booking.scheduledAt.toIso8601String().split('T').first,
          'p_start_time_slot': booking.startTimeSlot,
          'p_address_snapshot': booking.address.toJson(),
          'p_service_snapshot': booking.service.toJson(),
          'p_pricing_inputs': booking.pricingInputs ?? {},
          'p_contact_name': booking.contact.name,
          'p_contact_phones': booking.contact.phone,
        },
      ) as String;

      final row = await _supabase
          .from(_tableName)
          .select('readable_id')
          .eq('id', newBookingUuid)
          .maybeSingle();

      final readableId = row?['readable_id'] as String?;
      return readableId ?? newBookingUuid;
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<BookingRemoteModel> getBookingById(String id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();
      return BookingRemoteModel.fromJson(response);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Stream<List<BookingRemoteModel>> watchUserBookings(String userId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((json) => BookingRemoteModel.fromJson(json)).toList());
  }

  @override
  Stream<List<BookingRemoteModel>> watchAllBookings({List<String>? serviceNames}) {
    var query = _supabase.from(_tableName).stream(primaryKey: ['id']);
    return query.map((data) => data.map((json) => BookingRemoteModel.fromJson(json)).toList());
  }

  @override
  Stream<BookingRemoteModel> watchBooking(String bookingId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('id', bookingId)
        .map((data) {
          if (data.isEmpty) throw Exception('Booking not found');
          return BookingRemoteModel.fromJson(data.first);
        });
  }

  @override
  Future<List<BookingRemoteModel>> getUserBookings(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BookingRemoteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<void> updateBooking({required BookingRemoteModel booking}) async {
    try {
      // SAFETY GUARD: Strip 'status' field — status changes MUST go through
      // transitionBooking() to ensure State Machine integrity, audit trail,
      // and notification dispatch. Direct status updates are forbidden.
      final data = booking.toJson()..remove('status');
      await _supabase
          .from(_tableName)
          .update(data)
          .eq('id', booking.id);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<void> transitionBooking({
    required String bookingId,
    required String newStatus,
    required String actorId,
    required String actorRole,
    String? reason,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.rpc(
        'transition_booking',
        params: {
          'p_booking_id': bookingId,
          'p_new_status': newStatus,
          'p_actor_id': actorId,
          'p_actor_role': actorRole,
          'p_reason_code': reason,
          'p_notes': notes,
          'p_metadata': metadata,
        },
      );
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    await transitionBooking(
      bookingId: bookingId,
      newStatus: 'cancelled',
      actorId: user.id,
      actorRole: 'customer',
      reason: 'User cancelled via app',
    );
  }

  @override
  Future<void> updateBookingSchedule({
    required String bookingId,
    required DateTime newDay,
    required String newTimeSlot,
    required String actorId,
  }) async {
    try {
      await _supabase.rpc(
        'customer_update_booking_schedule',
        params: {
          'p_booking_id': bookingId,
          'p_new_day': newDay.toIso8601String().split('T').first,
          'p_new_time_slot': newTimeSlot,
          'p_actor_id': actorId,
        },
      );
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<void> updateBookingAddress({
    required String bookingId,
    required Map<String, dynamic> addressSnapshot,
    required Map<String, dynamic> contactSnapshot,
    required String actorId,
  }) async {
    try {
      await _supabase.rpc(
        'customer_update_booking_address',
        params: {
          'p_booking_id': bookingId,
          'p_address_snapshot': addressSnapshot,
          'p_contact_snapshot': contactSnapshot,
          'p_actor_id': actorId,
        },
      );
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<Map<String, dynamic>> calculateBookingPrice({
    required String subServiceId,
    required Map<String, dynamic> pricingInputs,
  }) async {
    try {
      final response = await _supabase.rpc(
        'calculate_booking_price',
        params: {
          'p_sub_service_id': subServiceId,
          'p_pricing_inputs': pricingInputs,
        },
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }
}
