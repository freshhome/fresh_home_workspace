import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../entities/notification.dart';
import '../entities/fcm_token.dart';

abstract class NotificationRepository {
  Stream<Either<Failure, List<AppNotification>>> watchNotifications(String userId);
  Future<Either<Failure, void>> markAsRead(String notificationId);
  Future<Either<Failure, void>> markAllAsRead(String userId);
  Future<Either<Failure, void>> registerFcmToken(FcmToken token);
  Future<Either<Failure, void>> deleteFcmToken(String userId, String deviceId);
}
