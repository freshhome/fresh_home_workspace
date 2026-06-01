import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../repositories/notification_repository.dart';
import '../entities/fcm_token.dart';

class ManageFcmTokenUseCase {
  final NotificationRepository _repository;

  ManageFcmTokenUseCase(this._repository);

  Future<Either<Failure, void>> register(FcmToken token) {
    return _repository.registerFcmToken(token);
  }

  Future<Either<Failure, void>> delete(String userId, String deviceId) {
    return _repository.deleteFcmToken(userId, deviceId);
  }
}
