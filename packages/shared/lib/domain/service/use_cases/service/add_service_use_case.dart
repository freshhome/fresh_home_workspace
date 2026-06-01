import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/entities/service_entity.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';
import 'package:shared/core/error/failures.dart';

class AddServiceUseCase {
  final ServiceRepository repository;

  AddServiceUseCase({required this.repository});

  Future<Either<Failure, ServiceEntity>> call(ServiceEntity service) {
    return repository.addService(service);
  }
}
