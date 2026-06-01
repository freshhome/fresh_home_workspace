import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/service/entities/sub_entities/shared_icon_entity.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';

class InsertSharedIconUseCase {
  final ServiceRepository repository;

  InsertSharedIconUseCase({required this.repository});

  Future<Either<Failure, SharedIconEntity>> call(SharedIconEntity icon) {
    return repository.insertSharedIcon(icon);
  }
}
