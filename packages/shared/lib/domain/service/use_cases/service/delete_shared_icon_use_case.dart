import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';

class DeleteSharedIconUseCase {
  final ServiceRepository repository;

  DeleteSharedIconUseCase({required this.repository});

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteSharedIcon(id);
  }
}
