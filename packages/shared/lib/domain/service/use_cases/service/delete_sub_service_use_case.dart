import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/entities/sub_service_entity.dart';
import '../../repositories/service_repository.dart';
import '../../../../core/error/failures.dart';

class DeleteSubServiceParams {
  final SubServiceEntity subService;
  final String mainServiceId;

  DeleteSubServiceParams({required this.subService, required this.mainServiceId});
}

class DeleteSubServiceUseCase {
  final ServiceRepository repository;

  DeleteSubServiceUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(DeleteSubServiceParams params) async {
    return await repository.deleteSubService(params.subService.id);
  }
}
