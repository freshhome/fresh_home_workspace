import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/entities/main_service_entity.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';
import 'package:shared/core/error/failures.dart';

class GetMainServicesUseCase {
  final ServiceRepository repository;

  GetMainServicesUseCase({required this.repository});

  Stream<Either<Failure, List<MainServiceEntity>>> call() {
    return repository.getMainServices();
  }
}
