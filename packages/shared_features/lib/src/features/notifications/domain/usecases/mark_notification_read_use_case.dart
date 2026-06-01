import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationRepository _repository;

  MarkNotificationReadUseCase(this._repository);

  Future<Either<Failure, void>> call(String notificationId) {
    return _repository.markAsRead(notificationId);
  }

  Future<Either<Failure, void>> all(String userId) {
    return _repository.markAllAsRead(userId);
  }
}
