import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/city.dart';
import 'package:shared/domain/user/entities/user/district.dart';
import 'package:shared/domain/user/entities/user/governorate.dart';

/// Repository contract for Admin Geographic Reference Data Management in Fresh Home System V2.
abstract class AdminGeographicReferenceRepository {
  /// Admin: Fetches all governorates (both active and inactive) for admin management.
  Future<Either<Failure, List<Governorate>>> getAllGovernorates();

  /// Admin: Fetches all cities (both active and inactive) for a governorate.
  Future<Either<Failure, List<City>>> getAllCitiesByGovernorate(int governorateId);

  /// Admin: Fetches all districts (both active and inactive) for a city.
  Future<Either<Failure, List<District>>> getAllDistrictsByCity(int cityId);

  /// Admin: Creates a new governorate record with bilingual names.
  Future<Either<Failure, Governorate>> createGovernorate({
    required String nameAr,
    required String nameEn,
    required String code,
    int sortOrder = 0,
  });

  /// Admin: Updates an existing governorate record.
  Future<Either<Failure, Governorate>> updateGovernorate({
    required int id,
    required String nameAr,
    required String nameEn,
    required String code,
    bool? isActive,
    int? sortOrder,
  });

  /// Admin: Creates a new city record under a valid governorate.
  Future<Either<Failure, City>> createCity({
    required int governorateId,
    required String nameAr,
    required String nameEn,
    int sortOrder = 0,
  });

  /// Admin: Updates an existing city record.
  Future<Either<Failure, City>> updateCity({
    required int id,
    required String nameAr,
    required String nameEn,
    bool? isActive,
    int? sortOrder,
  });

  /// Admin: Creates a new district record under a valid city.
  Future<Either<Failure, District>> createDistrict({
    required int cityId,
    required String nameAr,
    required String nameEn,
    int sortOrder = 0,
  });

  /// Admin: Updates an existing district record.
  Future<Either<Failure, District>> updateDistrict({
    required int id,
    required String nameAr,
    required String nameEn,
    bool? isActive,
    int? sortOrder,
  });

  /// Admin: Soft toggles enable/disable status for a reference record without hard deletion.
  Future<Either<Failure, Unit>> toggleActiveStatus({
    required String table,
    required int id,
    required bool isActive,
  });
}
