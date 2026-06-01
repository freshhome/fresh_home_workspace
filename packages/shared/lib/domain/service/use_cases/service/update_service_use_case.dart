import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/entities/service_entity.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';
import 'package:shared/core/error/failures.dart';

class UpdateServiceUseCase {
  final ServiceRepository repository;

  UpdateServiceUseCase({required this.repository});

  Future<Either<Failure, ServiceEntity>> call(ServiceEntity service) {
    return repository.updateService(service);
  }
}
