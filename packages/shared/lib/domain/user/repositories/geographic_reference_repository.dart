import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/city.dart';
import 'package:shared/domain/user/entities/user/district.dart';
import 'package:shared/domain/user/entities/user/governorate.dart';

/// Repository contract for fetching Geographic Reference Data in Fresh Home System V2.
abstract class GeographicReferenceRepository {
  /// Fetches all active governorates sorted by sort_order.
  Future<Either<Failure, List<Governorate>>> getGovernorates();

  /// Fetches active cities belonging to a specific governorate sorted by sort_order.
  Future<Either<Failure, List<City>>> getCitiesByGovernorate(int governorateId);

  /// Fetches active districts belonging to a specific city sorted by sort_order.
  Future<Either<Failure, List<District>>> getDistrictsByCity(int cityId);
}
