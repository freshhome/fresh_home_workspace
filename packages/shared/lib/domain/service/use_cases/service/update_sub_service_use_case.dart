import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/entities/sub_service_entity.dart';
import '../../repositories/service_repository.dart';
import '../../../../core/error/failures.dart';

class UpdateSubServiceParams {
  final SubServiceEntity subService;
  final String mainServiceId;

  UpdateSubServiceParams({required this.subService, required this.mainServiceId});
}

class UpdateSubServiceUseCase {
  final ServiceRepository repository;

  UpdateSubServiceUseCase({required this.repository});

  Future<Either<Failure, SubServiceEntity>> call(UpdateSubServiceParams params) async {
    return await repository.updateSubService(params.subService);
  }
}
