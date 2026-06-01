import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/settings/domain/settings_domain.dart';

/// Use case for getting the saved locale
class GetSavedLocaleUseCase {
  final LocaleRepository repository;
  
  GetSavedLocaleUseCase(this.repository);
  
  Future<Either<Failure, String?>> call() => repository.getSavedLocale();
}
