import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/core/error/exceptions.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/fcm_token.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';
import '../mappers/notification_mapper.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImpl(this._remoteDataSource);

  @override
  Stream<Either<Failure, List<AppNotification>>> watchNotifications(String userId) {
    return _remoteDataSource.watchNotifications(userId).map(
      (models) => Right<Failure, List<AppNotification>>(
        models.map((m) => NotificationMapper.remoteToEntity(m)).toList(),
      ),
    ).handleError((e) => Left<Failure, List<AppNotification>>(ServerFailure(message: e.toString())));
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await _remoteDataSource.markAsRead(notificationId);
      return const Right(null);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead(String userId) async {
    try {
      await _remoteDataSource.markAllAsRead(userId);
      return const Right(null);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> registerFcmToken(FcmToken token) async {
    try {
      await _remoteDataSource.registerFcmToken(
        userId: token.userId,
        deviceId: token.deviceId,
        token: token.token,
        platform: token.platform,
      );
      return const Right(null);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFcmToken(String userId, String deviceId) async {
    try {
      await _remoteDataSource.deleteFcmToken(userId, deviceId);
      return const Right(null);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
