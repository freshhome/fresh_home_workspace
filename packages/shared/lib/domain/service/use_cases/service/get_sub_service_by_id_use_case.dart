import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/entities/sub_service_entity.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';
import 'package:shared/core/error/failures.dart';

class GetSubServiceByIdUseCase {
  final ServiceRepository repository;

  GetSubServiceByIdUseCase({required this.repository});

  Future<Either<Failure, SubServiceEntity>> call({
    required String subServiceId,
    required String mainServiceId,
    bool forceRemote = false,
  }) {
    return repository.getSubServiceById(
      subServiceId,
      forceRemote: forceRemote,
      mainServiceId: mainServiceId,
      subServiceId: subServiceId,
    );
  }

}
