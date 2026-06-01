import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';
import 'package:shared/domain/technician/entities/technician.dart';

class GetTechniciansForServiceUseCase {
  final ServiceRepository repository;

  GetTechniciansForServiceUseCase({required this.repository});

  Future<Either<Failure, List<Technician>>> call(String subServiceId) async {
    return await repository.getTechniciansForService(subServiceId);
  }
}
