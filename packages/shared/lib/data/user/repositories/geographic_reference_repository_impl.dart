import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/data/user/datasources/geographic_reference_remote_datasource.dart';
import 'package:shared/domain/user/entities/user/city.dart';
import 'package:shared/domain/user/entities/user/district.dart';
import 'package:shared/domain/user/entities/user/governorate.dart';
import 'package:shared/domain/user/repositories/geographic_reference_repository.dart';

/// Implementation of GeographicReferenceRepository supporting memory-level caching.
class GeographicReferenceRepositoryImpl implements GeographicReferenceRepository {
  final GeographicReferenceRemoteDataSource remoteDataSource;

  // Memory Caches
  List<Governorate>? _cachedGovernorates;
  final Map<int, List<City>> _cachedCitiesByGov = {};
  final Map<int, List<District>> _cachedDistrictsByCity = {};

  GeographicReferenceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Governorate>>> getGovernorates() async {
    if (_cachedGovernorates != null && _cachedGovernorates!.isNotEmpty) {
      return Right(_cachedGovernorates!);
    }

    try {
      final models = await remoteDataSource.getGovernorates();
      final entities = models.map((m) => m.toEntity()).toList();
      _cachedGovernorates = entities;
      return Right(entities);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<City>>> getCitiesByGovernorate(int governorateId) async {
    if (_cachedCitiesByGov.containsKey(governorateId)) {
      return Right(_cachedCitiesByGov[governorateId]!);
    }

    try {
      final models = await remoteDataSource.getCitiesByGovernorate(governorateId);
      final entities = models.map((m) => m.toEntity()).toList();
      _cachedCitiesByGov[governorateId] = entities;
      return Right(entities);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<District>>> getDistrictsByCity(int cityId) async {
    if (_cachedDistrictsByCity.containsKey(cityId)) {
      return Right(_cachedDistrictsByCity[cityId]!);
    }

    try {
      final models = await remoteDataSource.getDistrictsByCity(cityId);
      final entities = models.map((m) => m.toEntity()).toList();
      _cachedDistrictsByCity[cityId] = entities;
      return Right(entities);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// Clears in-memory caches when refresh is explicitly requested.
  void clearMemoryCache() {
    _cachedGovernorates = null;
    _cachedCitiesByGov.clear();
    _cachedDistrictsByCity.clear();
  }
}
