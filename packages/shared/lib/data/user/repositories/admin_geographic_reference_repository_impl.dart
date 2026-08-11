import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/data/user/models/city_model.dart';

import 'package:shared/data/user/models/district_model.dart';
import 'package:shared/data/user/models/governorate_model.dart';
import 'package:shared/data/user/repositories/geographic_reference_repository_impl.dart';
import 'package:shared/domain/user/entities/user/city.dart';
import 'package:shared/domain/user/entities/user/district.dart';
import 'package:shared/domain/user/entities/user/governorate.dart';
import 'package:shared/domain/user/repositories/admin_geographic_reference_repository.dart';

/// Implementation of AdminGeographicReferenceRepository with validation and memory cache invalidation.
class AdminGeographicReferenceRepositoryImpl implements AdminGeographicReferenceRepository {
  final SupabaseClient supabaseClient;
  final GeographicReferenceRepositoryImpl? clientRepository;

  AdminGeographicReferenceRepositoryImpl({
    required this.supabaseClient,
    this.clientRepository,
  });

  @override
  Future<Either<Failure, List<Governorate>>> getAllGovernorates() async {
    try {
      final response = await supabaseClient
          .from('governorates')
          .select()
          .order('sort_order', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final entities = data
          .map((json) => GovernorateModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
      return Right(entities);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<City>>> getAllCitiesByGovernorate(int governorateId) async {
    try {
      final response = await supabaseClient
          .from('cities')
          .select()
          .eq('governorate_id', governorateId)
          .order('sort_order', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final entities = data
          .map((json) => CityModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
      return Right(entities);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<District>>> getAllDistrictsByCity(int cityId) async {
    try {
      final response = await supabaseClient
          .from('districts')
          .select()
          .eq('city_id', cityId)
          .order('sort_order', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final entities = data
          .map((json) => DistrictModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
      return Right(entities);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Governorate>> createGovernorate({
    required String nameAr,
    required String nameEn,
    required String code,
    int sortOrder = 0,
  }) async {
    final cleanAr = nameAr.trim();
    final cleanEn = nameEn.trim();
    final cleanCode = code.trim().toUpperCase();

    if (cleanAr.isEmpty || cleanEn.isEmpty || cleanCode.isEmpty) {
      return Left(const ValidationFailure(
        message: 'Governorate Arabic name, English name, and Code are required.',
        code: 'INVALID_GOVERNORATE_INPUT',
      ));
    }

    try {
      final response = await supabaseClient
          .from('governorates')
          .insert({
            'name_ar': cleanAr,
            'name_en': cleanEn,
            'code': cleanCode,
            'sort_order': sortOrder,
            'is_active': true,
          })
          .select()
          .single();

      clientRepository?.clearMemoryCache();
      final model = GovernorateModel.fromJson(response);
      return Right(model.toEntity());
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Governorate>> updateGovernorate({
    required int id,
    required String nameAr,
    required String nameEn,
    required String code,
    bool? isActive,
    int? sortOrder,
  }) async {
    final cleanAr = nameAr.trim();
    final cleanEn = nameEn.trim();
    final cleanCode = code.trim().toUpperCase();

    if (cleanAr.isEmpty || cleanEn.isEmpty || cleanCode.isEmpty) {
      return Left(const ValidationFailure(
        message: 'Governorate Arabic name, English name, and Code are required.',
        code: 'INVALID_GOVERNORATE_INPUT',
      ));
    }

    try {
      final updateData = <String, dynamic>{
        'name_ar': cleanAr,
        'name_en': cleanEn,
        'code': cleanCode,
      };
      if (isActive != null) updateData['is_active'] = isActive;
      if (sortOrder != null) updateData['sort_order'] = sortOrder;

      final response = await supabaseClient
          .from('governorates')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      clientRepository?.clearMemoryCache();
      final model = GovernorateModel.fromJson(response);
      return Right(model.toEntity());
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, City>> createCity({
    required int governorateId,
    required String nameAr,
    required String nameEn,
    int sortOrder = 0,
  }) async {
    final cleanAr = nameAr.trim();
    final cleanEn = nameEn.trim();

    if (cleanAr.isEmpty || cleanEn.isEmpty) {
      return Left(const ValidationFailure(
        message: 'City Arabic name and English name are required.',
        code: 'INVALID_CITY_INPUT',
      ));
    }

    try {
      final response = await supabaseClient
          .from('cities')
          .insert({
            'governorate_id': governorateId,
            'name_ar': cleanAr,
            'name_en': cleanEn,
            'sort_order': sortOrder,
            'is_active': true,
          })
          .select()
          .single();

      clientRepository?.clearMemoryCache();
      final model = CityModel.fromJson(response);
      return Right(model.toEntity());
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, City>> updateCity({
    required int id,
    required String nameAr,
    required String nameEn,
    bool? isActive,
    int? sortOrder,
  }) async {
    final cleanAr = nameAr.trim();
    final cleanEn = nameEn.trim();

    if (cleanAr.isEmpty || cleanEn.isEmpty) {
      return Left(const ValidationFailure(
        message: 'City Arabic name and English name are required.',
        code: 'INVALID_CITY_INPUT',
      ));
    }

    try {
      final updateData = <String, dynamic>{
        'name_ar': cleanAr,
        'name_en': cleanEn,
      };
      if (isActive != null) updateData['is_active'] = isActive;
      if (sortOrder != null) updateData['sort_order'] = sortOrder;

      final response = await supabaseClient
          .from('cities')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      clientRepository?.clearMemoryCache();
      final model = CityModel.fromJson(response);
      return Right(model.toEntity());
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, District>> createDistrict({
    required int cityId,
    required String nameAr,
    required String nameEn,
    int sortOrder = 0,
  }) async {
    final cleanAr = nameAr.trim();
    final cleanEn = nameEn.trim();

    if (cleanAr.isEmpty || cleanEn.isEmpty) {
      return Left(const ValidationFailure(
        message: 'District Arabic name and English name are required.',
        code: 'INVALID_DISTRICT_INPUT',
      ));
    }

    try {
      final response = await supabaseClient
          .from('districts')
          .insert({
            'city_id': cityId,
            'name_ar': cleanAr,
            'name_en': cleanEn,
            'sort_order': sortOrder,
            'is_active': true,
          })
          .select()
          .single();

      clientRepository?.clearMemoryCache();
      final model = DistrictModel.fromJson(response);
      return Right(model.toEntity());
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, District>> updateDistrict({
    required int id,
    required String nameAr,
    required String nameEn,
    bool? isActive,
    int? sortOrder,
  }) async {
    final cleanAr = nameAr.trim();
    final cleanEn = nameEn.trim();

    if (cleanAr.isEmpty || cleanEn.isEmpty) {
      return Left(const ValidationFailure(
        message: 'District Arabic name and English name are required.',
        code: 'INVALID_DISTRICT_INPUT',
      ));
    }

    try {
      final updateData = <String, dynamic>{
        'name_ar': cleanAr,
        'name_en': cleanEn,
      };
      if (isActive != null) updateData['is_active'] = isActive;
      if (sortOrder != null) updateData['sort_order'] = sortOrder;

      final response = await supabaseClient
          .from('districts')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      clientRepository?.clearMemoryCache();
      final model = DistrictModel.fromJson(response);
      return Right(model.toEntity());
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleActiveStatus({
    required String table,
    required int id,
    required bool isActive,
  }) async {
    if (!['governorates', 'cities', 'districts'].contains(table)) {
      return Left(const ValidationFailure(message: 'Invalid target table.', code: 'INVALID_TABLE'));
    }

    try {
      await supabaseClient
          .from(table)
          .update({'is_active': isActive})
          .eq('id', id);

      clientRepository?.clearMemoryCache();
      return Right(unit);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
