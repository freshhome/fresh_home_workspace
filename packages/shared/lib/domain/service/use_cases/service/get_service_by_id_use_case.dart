import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/entities/service_entity.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';
import 'package:shared/core/error/failures.dart';

class GetServiceByIdUseCase {
  final ServiceRepository repository;

  GetServiceByIdUseCase({required this.repository});

  Future<Either<Failure, ServiceEntity>> call(String id, {bool forceRefresh = false}) {
    return repository.getServiceById(id, forceRefresh: forceRefresh);
  }
}
