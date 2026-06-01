import 'package:fpdart/fpdart.dart';

import 'package:shared/data/counter/datasources/counter_remote_data_source.dart';
import 'package:shared/domain/counter/repositories/counter_repository.dart';
import 'package:shared/core/error/failures.dart';

class CounterRepositoryImpl implements CounterRepository {
  final CounterRemoteDataSource remoteDataSource;

  CounterRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, int>> getNextId(String collectionName) async {
    try {
      final result = await remoteDataSource.getNextId(collectionName);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to generate ID: $e'));
    }
  }
}
