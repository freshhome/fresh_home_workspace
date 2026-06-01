import 'package:equatable/equatable.dart';

class FcmToken extends Equatable {
  final String userId;
  final String deviceId;
  final String token;
  final String platform;

  const FcmToken({
    required this.userId,
    required this.deviceId,
    required this.token,
    required this.platform,
  });

  @override
  List<Object?> get props => [userId, deviceId, token, platform];
}
