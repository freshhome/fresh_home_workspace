import 'package:fpdart/fpdart.dart';

import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/settings/data/settings_data.dart';
import 'package:shared_features/src/features/settings/domain/settings_domain.dart';

/// Implementation of LocaleRepository
class LocaleRepositoryImpl implements LocaleRepository {
  final LocaleLocalDataSource localeLocalDataSource;

  LocaleRepositoryImpl({required this.localeLocalDataSource});

  @override
  Future<Either<Failure, String?>> getSavedLocale() async {
    try {
      final localeCode = await localeLocalDataSource.getSavedLocaleCode();
      return Right(localeCode);
    } catch (e) {
      return Left(
        UnknownFailure(message: e.toString(), code: 'locale_read_error'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> changeLocale(String localeCode) async {
    try {
      await localeLocalDataSource.saveLocaleCode(localeCode);
      return const Right(null);
    } catch (e) {
      return Left(
        UnknownFailure(message: e.toString(), code: 'locale_save_error'),
      );
    }
  }
}
