import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/entities/main_service_entity.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';
import 'package:shared/core/error/failures.dart';

class SearchServicesUseCase {
  final ServiceRepository repository;

  SearchServicesUseCase({required this.repository});

  Future<Either<Failure, List<MainServiceEntity>>> call({required String query}) {
    return repository.searchServices(query);
  }
}
