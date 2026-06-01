import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/settings/domain/settings_domain.dart';

class GetThemeUseCase {
  final SettingsRepository repository;
  GetThemeUseCase(this.repository);
  Future<Either<Failure, bool>> call() => repository.getIsDark();
}
