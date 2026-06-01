import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../repositories/notification_repository.dart';
import '../entities/notification.dart';

class WatchNotificationsUseCase {
  final NotificationRepository _repository;

  WatchNotificationsUseCase(this._repository);

  Stream<Either<Failure, List<AppNotification>>> call(String userId) {
    return _repository.watchNotifications(userId);
  }
}
