import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_funnel_model.dart';

abstract class BookingFunnelRemoteDataSource {
  Future<BookingFunnelModel> getBookingFunnelStats({
    DateTime? startDate,
    DateTime? endDate,
    String? serviceId,
  });
}

class BookingFunnelRemoteDataSourceImpl
    implements BookingFunnelRemoteDataSource {
  final SupabaseClient supabaseClient;

  BookingFunnelRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<BookingFunnelModel> getBookingFunnelStats({
    DateTime? startDate,
    DateTime? endDate,
    String? serviceId,
  }) async {
    debugPrint('📊 [BookingFunnelRemoteDataSource] Requesting get_booking_funnel_stats RPC...');
    try {
      final Map<String, dynamic> rpcParams = {
        'p_tracking_version': 'v1',
      };
      if (startDate != null) {
        rpcParams['p_start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        rpcParams['p_end_date'] = endDate.toIso8601String();
      }
      if (serviceId != null && serviceId.trim().isNotEmpty) {
        rpcParams['p_service_id'] = serviceId.trim();
      }

      final response = await supabaseClient.rpc(
        'get_booking_funnel_stats',
        params: rpcParams,
      );

      debugPrint('📊 [BookingFunnelRemoteDataSource] Received RPC response: $response');

      if (response == null) {
        throw ServerException('لم يتم استلام أي بيانات من الخادم');
      }

      Map<String, dynamic> jsonMap;
      if (response is Map<String, dynamic>) {
        jsonMap = response;
      } else if (response is String) {
        jsonMap = jsonDecode(response) as Map<String, dynamic>;
      } else if (response is Map) {
        jsonMap = Map<String, dynamic>.from(response);
      } else {
        throw ServerException('صيغة البيانات المستلمة غير مدعومة');
      }

      return BookingFunnelModel.fromJson(jsonMap);
    } on PostgrestException catch (e) {
      debugPrint('❌ [BookingFunnelRemoteDataSource] PostgrestException: ${e.message} (code: ${e.code})');
      if (e.code == '42501') {
        throw ServerException('غير مصرح لك بالوصول إلى بيانات مسار الحجز (خاص بالإدارة فقط)');
      }
      throw ServerException(e.message);
    } on AppException catch (e) {
      debugPrint('❌ [BookingFunnelRemoteDataSource] AppException: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('💥 [BookingFunnelRemoteDataSource] Unexpected Exception: $e\n$stackTrace');
      throw NetworkException('تعذر الاتصال بقاعدة البيانات: $e');
    }
  }
}
