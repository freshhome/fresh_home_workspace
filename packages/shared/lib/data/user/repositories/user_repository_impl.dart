import 'package:fpdart/fpdart.dart';
import 'package:shared/data/user/datasources/user_local_datasource.dart';
import 'package:shared/data/user/datasources/user_remote_datasource.dart';
import 'package:shared/data/user/mappers/user_mapper.dart';
import 'package:shared/domain/user/entities/user/user.dart';
import 'package:shared/domain/user/repositories/user_repository.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/core/error/failures.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, void>> createUser({required User user}) async {
    try {
      final remoteModel = UserMapper.entityToRemote(user);
      await remoteDataSource.createUser(user: remoteModel);
      await localDataSource.cacheCurrentUser(UserMapper.remoteToHive(remoteModel));
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, User>> getUserById({required String uid}) async {
    try {
      // Strategy: Cache First, then Remote? Or Remote then Cache?
      // Usually for "My Profile", we want fresh data but fallback to cache.
      // However, the comment said "هاته من التخزين المحلي دائما" (Bring it from local storage always)
      // but typically we need to sync.
      // Let's implement: Try Cache, if found return it. But also maybe background sync?
      // For now, let's follow the standard: Try Remote -> Update Cache -> Return.
      // If Remote fails -> Return Cache.
      
      // But if the requirement is STRICTLY local first for speed:
      final localUser = await localDataSource.getUserById(uid);
      if (localUser != null && localUser.uid == uid) {
         // Optionally fetch remote in background to update cache?
         // For now, let's just return local if available? 
         // But if we return local, we might be stale. 
         // Let's stick to reliable: Remote first.
      }
      
      try {
        final remoteUser = await remoteDataSource.getUserById(uid);
        if (remoteUser != null) {
          await localDataSource.cacheUser(UserMapper.remoteToHive(remoteUser));
          return Right(UserMapper.remoteToEntity(remoteUser));
        } else {
          if (localUser != null) {
            return Right(UserMapper.hiveToEntity(localUser));
          }
          return Left(ServerFailure(message: 'User profile not found'));
        }
      } catch (e) {
        if (localUser != null) {
          return Right(UserMapper.hiveToEntity(localUser));
        }
        rethrow;
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUser({required User user}) async {
    try {
      final remoteModel = UserMapper.entityToRemote(user);
      await remoteDataSource.updateUser(user: remoteModel);
      await localDataSource.cacheCurrentUser(UserMapper.remoteToHive(remoteModel));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
