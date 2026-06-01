import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/entities/main_service_entity.dart';
import '../../repositories/service_repository.dart';
import '../../../../core/error/failures.dart';

class UpdateMainServiceUseCase {
  final ServiceRepository repository;

  UpdateMainServiceUseCase({required this.repository});

  Future<Either<Failure, MainServiceEntity>> call(MainServiceEntity params) async {
    return await repository.updateMainService(params);
  }
}
