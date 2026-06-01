import 'package:fpdart/fpdart.dart';

import 'package:shared/core/usecase/usecase.dart';
import 'package:shared/domain/counter/repositories/counter_repository.dart';
import 'package:shared/core/error/failures.dart';

class GetNextIdUseCase extends UseCase<int, String> {
  final CounterRepository repository;

  GetNextIdUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(String params) async {
    return await repository.getNextId(params);
  }
}
