import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/settings/domain/settings_domain.dart';

/// Use case for changing the app locale
class ChangeLocaleUseCase {
  final LocaleRepository repository;
  
  ChangeLocaleUseCase(this.repository);
  
  Future<Either<Failure, void>> call(String localeCode) => 
      repository.changeLocale(localeCode);
}
