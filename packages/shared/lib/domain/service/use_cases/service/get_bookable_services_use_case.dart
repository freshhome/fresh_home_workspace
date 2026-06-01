import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/entities/service_entity.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';
import 'package:shared/core/error/failures.dart';

class GetBookableServicesUseCase {
  final ServiceRepository repository;

  GetBookableServicesUseCase({required this.repository});

  Future<Either<Failure, List<ServiceEntity>>> call({bool forceRefresh = false}) {
    return repository.getBookableServices(forceRefresh: forceRefresh);
  }
}
