import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/entities/sub_service_entity.dart';
import '../../repositories/service_repository.dart';
import '../../../../core/error/failures.dart';

class AddSubServiceParams {
  final SubServiceEntity subService;
  final String mainServiceId;

  AddSubServiceParams({required this.subService, required this.mainServiceId});
}

class AddSubServiceUseCase {
  final ServiceRepository repository;

  AddSubServiceUseCase({required this.repository});

  Future<Either<Failure, SubServiceEntity>> call(AddSubServiceParams params) async {
    return await repository.addSubService(
      params.subService,
      params.mainServiceId,
    );
  }
}
