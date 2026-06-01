import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/exceptions.dart';

abstract class AvailabilityRemoteDataSource {
  Future<List<Map<String, dynamic>>> getAvailableDays({
    required String serviceId,
    required String startDate,
    required String endDate,
  });
}

class AvailabilityRemoteDataSourceImpl implements AvailabilityRemoteDataSource {
  final SupabaseClient _supabase;

  AvailabilityRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getAvailableDays({
    required String serviceId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_available_days',
        params: {
          'p_sub_service_id': serviceId,
          'p_start_date': startDate,
          'p_end_date': endDate,
        },
      );
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }
}
