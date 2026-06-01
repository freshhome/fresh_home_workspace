import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/entities/sub_service_entity.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';
import 'package:shared/core/error/failures.dart';

class GetSubServicesUseCase {
  final ServiceRepository repository;

  GetSubServicesUseCase({required this.repository});

  Future<Either<Failure, List<SubServiceEntity>>> call({
    required String mainServiceId,
    bool forceRemote = false,
  }) {
    return repository.getSubServices(mainServiceId);
  }

}
