import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import 'package:shared/domain/user/repositories/user_repository.dart';
import 'package:shared/core/error/failures.dart';

class UpdateUserUseCase {
  final UserRepository userRepository;

  UpdateUserUseCase({required this.userRepository});

  Future<Either<Failure, void>> call({required UserProfile user}) async {
    return await userRepository.updateUser(user: user);
  }
}
