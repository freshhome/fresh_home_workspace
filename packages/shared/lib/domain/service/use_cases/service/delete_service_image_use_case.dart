import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';

class DeleteServiceImageUseCase {
  final ServiceRepository repository;

  DeleteServiceImageUseCase({required this.repository});

  Future<Either<Failure, void>> call(String imageUrl) {
    return repository.deleteServiceImage(imageUrl);
  }
}
