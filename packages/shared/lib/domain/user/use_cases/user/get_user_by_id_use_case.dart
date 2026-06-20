import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import 'package:shared/domain/user/repositories/user_repository.dart';
import 'package:shared/core/error/failures.dart';

class GetUserByIdUseCase {
  final UserRepository userRepository;

  GetUserByIdUseCase({required this.userRepository});

  Future<Either<Failure, UserProfile>> call({required String uid}) async {
    return await userRepository.getUserById(uid: uid);
  }
}
