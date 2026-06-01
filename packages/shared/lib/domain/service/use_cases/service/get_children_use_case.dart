import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/entities/service_entity.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';
import 'package:shared/core/error/failures.dart';

class GetChildrenUseCase {
  final ServiceRepository repository;

  GetChildrenUseCase({required this.repository});

  Future<Either<Failure, List<ServiceEntity>>> call(String parentId, {bool forceRefresh = false}) {
    return repository.getChildren(parentId, forceRefresh: forceRefresh);
  }
}
