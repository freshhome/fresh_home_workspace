import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/data/user/models/city_model.dart';
import 'package:shared/data/user/models/district_model.dart';
import 'package:shared/data/user/models/governorate_model.dart';

/// Contract for Remote Data Source querying Supabase Geographic Reference Tables.
abstract class GeographicReferenceRemoteDataSource {
  Future<List<GovernorateModel>> getGovernorates();
  Future<List<CityModel>> getCitiesByGovernorate(int governorateId);
  Future<List<DistrictModel>> getDistrictsByCity(int cityId);
}

/// Implementation using SupabaseClient querying reference tables.
class GeographicReferenceRemoteDataSourceImpl implements GeographicReferenceRemoteDataSource {
  final SupabaseClient supabaseClient;

  GeographicReferenceRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<GovernorateModel>> getGovernorates() async {
    final response = await supabaseClient
        .from('governorates')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => GovernorateModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<CityModel>> getCitiesByGovernorate(int governorateId) async {
    final response = await supabaseClient
        .from('cities')
        .select()
        .eq('governorate_id', governorateId)
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => CityModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<DistrictModel>> getDistrictsByCity(int cityId) async {
    final response = await supabaseClient
        .from('districts')
        .select()
        .eq('city_id', cityId)
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => DistrictModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}
