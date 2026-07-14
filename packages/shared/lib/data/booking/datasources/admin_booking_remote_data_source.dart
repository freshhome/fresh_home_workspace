import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/data/booking/models/remote/booking_remote_model.dart';
import 'package:shared/data/booking/models/remote/order_status_model.dart';

abstract class AdminBookingRemoteDataSource {
  Future<void> reassignBooking({
    required String bookingId,
    required String newTechnicianId,
    required String adminId,
    String? reason,
  });

  Future<void> cancelBooking({
    required String bookingId,
    required String adminId,
    required String reason,
  });

  Future<void> rescheduleBooking({
    required String bookingId,
    required String adminId,
    required DateTime newDateTime,
    String? reason,
  });

  Future<void> forceStatusUpdate({
    required String bookingId,
    required OrderStatus newStatus,
    required String adminId,
    String? reason,
  });

  Stream<List<BookingRemoteModel>> watchActiveBookings();
  Stream<List<BookingRemoteModel>> watchCompletedBookings();
  Stream<List<BookingRemoteModel>> watchCancelledBookings();
  Stream<List<BookingRemoteModel>> watchAllBookings();
  Future<List<BookingRemoteModel>> getAllBookings();
}

class AdminBookingRemoteDataSourceImpl implements AdminBookingRemoteDataSource {
  final SupabaseClient _supabase;
  final String _tableName = 'bookings';

  AdminBookingRemoteDataSourceImpl(this._supabase);

  @override
  Future<void> reassignBooking({
    required String bookingId,
    required String newTechnicianId,
    required String adminId,
    String? reason,
  }) async {
    try {
      await _supabase.rpc(
        'admin_reassign_booking',
        params: {
          'p_booking_id': bookingId,
          'p_new_technician_id': newTechnicianId,
          'p_admin_id': adminId,
          'p_reason': reason,
        },
      );
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<void> cancelBooking({
    required String bookingId,
    required String adminId,
    required String reason,
  }) async {
    try {
      await _supabase.rpc(
        'transition_booking',
        params: {
          'p_booking_id': bookingId,
          'p_new_status': 'cancelled',
          'p_actor_id': adminId,
          'p_actor_role': 'admin',
          'p_reason_code': reason, // ← FIXED: was 'p_reason', audit trail now preserved
        },
      );
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<void> rescheduleBooking({
    required String bookingId,
    required String adminId,
    required DateTime newDateTime,
    String? reason,
  }) async {
    try {
      await _supabase.rpc(
        'admin_reschedule_booking_atomic',
        params: {
          'p_booking_id': bookingId,
          'p_new_date': newDateTime.toIso8601String().split('T')[0],
          'p_admin_id': adminId,
          'p_reason': reason,
          'p_new_time': '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}:00',
        },
      );
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<void> forceStatusUpdate({
    required String bookingId,
    required OrderStatus newStatus,
    required String adminId,
    String? reason,
  }) async {
    try {
      await _supabase.rpc(
        'admin_force_status_update',
        params: {
          'p_booking_id': bookingId,
          'p_new_status': OrderStatusModel.toJson(newStatus),
          'p_admin_id': adminId,
          'p_reason': reason,
        },
      );
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Stream<List<BookingRemoteModel>> watchActiveBookings() {
    print('🌐 [AdminBookingDataSource] Watching Active Bookings...');
    return _supabase.from(_tableName).stream(primaryKey: ['id']).map((data) {
      print('📦 [AdminBookingDataSource] Active Raw Data: ${data.length} rows');
      return data
          .where(
            (json) =>
                json['status'] == 'assigned' ||
                json['status'] == 'accepted' ||
                json['status'] == 'ready' ||      // ← ADDED: new state from STEP 2.1
                json['status'] == 'on_the_way' ||
                json['status'] == 'arrived' ||
                json['status'] == 'in_progress',
          )
          .map((json) {
            try {
              return BookingRemoteModel.fromJson(json);
            } catch (e) {
              print(
                '❌ [AdminBookingDataSource] Error parsing row: $e | Data: $json',
              );
              rethrow;
            }
          })
          .toList();
    });
  }

  @override
  Stream<List<BookingRemoteModel>> watchCompletedBookings() {
    print('🌐 [AdminBookingDataSource] Watching Completed Bookings...');
    return _supabase.from(_tableName).stream(primaryKey: ['id']).map((data) {
      print(
        '📦 [AdminBookingDataSource] Completed Raw Data: ${data.length} rows',
      );
      return data
          .where((json) => json['status'] == 'completed')
          .map((json) => BookingRemoteModel.fromJson(json))
          .toList();
    });
  }

  @override
  Stream<List<BookingRemoteModel>> watchCancelledBookings() {
    print('🌐 [AdminBookingDataSource] Watching Cancelled Bookings...');
    return _supabase.from(_tableName).stream(primaryKey: ['id']).map((data) {
      print(
        '📦 [AdminBookingDataSource] Cancelled Raw Data: ${data.length} rows',
      );
      return data
          .where(
            (json) =>
                (json['status'] as String).startsWith('cancelled') ||
                json['status'] == 'expired' ||
                json['status'] == 'failed_no_show',
          )
          .map((json) => BookingRemoteModel.fromJson(json))
          .toList();
    });
  }

  @override
  Stream<List<BookingRemoteModel>> watchAllBookings() {
    print('🌐 [AdminBookingDataSource] Watching All Bookings...');
    return _supabase.from(_tableName).stream(primaryKey: ['id']).map((data) {
      print('📦 [AdminBookingDataSource] All Raw Data: ${data.length} rows');
      return data.map((json) {
        try {
          return BookingRemoteModel.fromJson(json);
        } catch (e) {
          print('❌ [AdminBookingDataSource] Error parsing row: $e');
          rethrow;
        }
      }).toList();
    });
  }

  @override
  Future<List<BookingRemoteModel>> getAllBookings() async {
    try {
      final user = _supabase.auth.currentUser;
      print('👤 [AdminBookingDataSource] Current User: ${user?.id} | Email: ${user?.email}');
      print('🌐 [AdminBookingDataSource] Fetching All Bookings via Select...');
      final response = await _supabase
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);

      final data = response as List;
      print('📦 [AdminBookingDataSource] Select Raw Data: ${data.length} rows');

      return data.map((json) {
        try {
          return BookingRemoteModel.fromJson(json);
        } catch (e) {
          print('❌ [AdminBookingDataSource] Select Parse Error: $e');
          rethrow;
        }
      }).toList();
    } catch (e) {
      print('❌ [AdminBookingDataSource] Select Fetch Error: $e');
      rethrow;
    }
  }
}
