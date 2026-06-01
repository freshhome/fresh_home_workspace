import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/domain/booking/entities/availability/day_availability.dart';
import 'package:shared/domain/user/entities/user/technician_profile.dart';
import 'package:shared/data/user/models/remote/technician_profile_remote_model.dart';

/// Remote data source for all assignment engine RPC calls.
abstract class AssignmentRemoteDataSource {
  Future<List<TechnicianProfile>> getAvailableTechnicians({
    required String subServiceId,
    required DateTime date,
  });

  Future<List<DayAvailability>> getAvailableDays({
    required String subServiceId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<String> createAtomicBooking({
    required String userId,
    required String subServiceId,
    required String technicianId,
    required DateTime scheduledDay,
    required Map<String, dynamic> addressSnapshot,
    required Map<String, dynamic> serviceSnapshot,
    required Map<String, dynamic> priceSnapshot,
  });
}

class AssignmentRemoteDataSourceImpl implements AssignmentRemoteDataSource {
  final SupabaseClient _client;

  AssignmentRemoteDataSourceImpl({required SupabaseClient client})
      : _client = client;

  @override
  Future<List<TechnicianProfile>> getAvailableTechnicians({
    required String subServiceId,
    required DateTime date,
  }) async {
    final response = await _client.rpc('get_available_technicians', params: {
      'p_sub_service_id': subServiceId,
      'p_date': date.toIso8601String().split('T').first,
    });

    final list = List<Map<String, dynamic>>.from(response as List);
    return list
        .map((json) => TechnicianProfileRemoteModel.fromJson(json).toDomain())
        .toList();
  }

  @override
  Future<List<DayAvailability>> getAvailableDays({
    required String subServiceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client.rpc('get_available_days', params: {
      'p_sub_service_id': subServiceId,
      'p_start_date': startDate.toIso8601String().split('T').first,
      'p_end_date': endDate.toIso8601String().split('T').first,
    });

    final list = List<Map<String, dynamic>>.from(response as List);
    return list
        .map((json) => DayAvailability(
              date: DateTime.parse(json['available_date'] as String),
              isAvailable: json['is_available'] as bool,
            ))
        .toList();
  }

  @override
  Future<String> createAtomicBooking({
    required String userId,
    required String subServiceId,
    required String technicianId,
    required DateTime scheduledDay,
    required Map<String, dynamic> addressSnapshot,
    required Map<String, dynamic> serviceSnapshot,
    required Map<String, dynamic> priceSnapshot,
  }) async {
    final response = await _client.rpc('create_atomic_booking', params: {
      'p_user_id': userId,
      'p_sub_service_id': subServiceId,
      'p_technician_id': technicianId,
      'p_scheduled_day': scheduledDay.toIso8601String().split('T').first,
      'p_address_snapshot': addressSnapshot,
      'p_service_snapshot': serviceSnapshot,
      'p_price_snapshot': priceSnapshot,
    });

    return response as String;
  }
}
