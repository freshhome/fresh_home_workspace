import 'package:fpdart/fpdart.dart';
import 'package:shared/data/user/datasources/user_local_datasource.dart';
import 'package:shared/data/user/datasources/user_remote_datasource.dart';
import 'package:shared/data/user/mappers/user_profile_mapper.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
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
  Future<Either<Failure, void>> createUser({required UserProfile user}) async {
    try {
      final remoteModel = UserProfileMapper.entityToRemote(user);
      await remoteDataSource.createUser(user: remoteModel);
      await localDataSource.cacheCurrentUser(UserProfileMapper.remoteToHive(remoteModel));
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> getUserById({required String uid}) async {
    try {
      final localUser = await localDataSource.getUserById(uid);
      
      try {
        final remoteUser = await remoteDataSource.getUserById(uid);
        if (remoteUser != null) {
          await localDataSource.cacheUser(UserProfileMapper.remoteToHive(remoteUser));
          return Right(UserProfileMapper.remoteToEntity(userModel: remoteUser));
        } else {
          if (localUser != null) {
            return Right(UserProfileMapper.hiveToEntity(localUser));
          }
          return Left(const ServerFailure(message: 'User profile not found'));
        }
      } catch (e) {
        if (localUser != null) {
          return Right(UserProfileMapper.hiveToEntity(localUser));
        }
        rethrow;
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUser({required UserProfile user}) async {
    try {
      final remoteModel = UserProfileMapper.entityToRemote(user);
      await remoteDataSource.updateUser(user: remoteModel);
      await localDataSource.cacheCurrentUser(UserProfileMapper.remoteToHive(remoteModel));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
