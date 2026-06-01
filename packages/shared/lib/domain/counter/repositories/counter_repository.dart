import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';

abstract class CounterRepository {
  Future<Either<Failure, int>> getNextId(String collectionName);
}
