import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';
import 'package:shared/core/error/failures.dart';

class SyncServicesUseCase {
  final ServiceRepository repository;

  SyncServicesUseCase({required this.repository});

  Future<Either<Failure, bool>> call() async {
    return await repository.syncAllServices();
  }
}
