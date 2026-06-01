import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';
import 'package:shared/domain/technician/entities/technician.dart';

class GetTechniciansUseCase {
  final ServiceRepository repository;

  GetTechniciansUseCase({required this.repository});

  Future<Either<Failure, List<Technician>>> call() async {
    return await repository.getTechnicians();
  }
}
