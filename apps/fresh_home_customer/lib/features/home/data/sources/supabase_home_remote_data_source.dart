import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class HomeRemoteDataSource {
  Future<Map<String, dynamic>?> getSliders();
}

class SupabaseHomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final SupabaseClient _supabase;

  SupabaseHomeRemoteDataSourceImpl(this._supabase);

  static const String _homeContentTable = 'home_content';

  @override
  Future<Map<String, dynamic>?> getSliders() async {
    debugPrint('🚀 [SUPABASE] Fetching sliders from $_homeContentTable...');
    try {
      final response = await _supabase
          .from(_homeContentTable)
          .select()
          .eq('type', 'sliders')
          .single();
      
      debugPrint('✅ [SUPABASE] Sliders fetched successfully');
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ [SUPABASE] Error fetching sliders: $e');
      rethrow;
    }
  }
}
