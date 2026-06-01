import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/settings/data/settings_data.dart';
import 'package:shared_features/src/features/settings/domain/settings_domain.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final ThemeLocalDataSource themeLocalDataSource;

  SettingsRepositoryImpl({
    required this.themeLocalDataSource,
  });

  @override
  Future<Either<Failure, bool>> getIsDark() async {
    try {
      final value = await themeLocalDataSource.getIsDark();
      return Right(value);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString(), code: 'unexpected_error'));
    }
  }

  @override
  Future<Either<Failure, void>> setIsDark(bool isDark) async {
    try {
      await themeLocalDataSource.setIsDark(isDark);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString(), code: 'unexpected_error'));
    }
  }
}
