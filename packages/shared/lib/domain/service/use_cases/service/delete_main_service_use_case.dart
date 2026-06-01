import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/entities/main_service_entity.dart';
import '../../repositories/service_repository.dart';
import '../../../../core/error/failures.dart';

class DeleteMainServiceUseCase {
  final ServiceRepository repository;

  DeleteMainServiceUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(MainServiceEntity params) async {
    return await repository.deleteMainService(params.id, mainService: params);
  }
}
