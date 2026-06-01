import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';

abstract class SettingsRepository {
  Future<Either<Failure, bool>> getIsDark();
  Future<Either<Failure, void>> setIsDark(bool isDark);
}
