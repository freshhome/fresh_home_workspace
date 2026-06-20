import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/domain/user/enums/user_status.dart';
import 'package:shared/domain/user/repositories/user_repository.dart';
import 'package:shared/core/error/failures.dart';

class CreateUserUseCase {
  final UserRepository userRepository;

  CreateUserUseCase({
    required this.userRepository,
  });

  Future<Either<Failure, void>> call({
    required String email,
    required String firstName,
    required String lastName,
    required String uid,
    List<UserRole>? roles,
  }) async {
    // Instantiate a default CustomerProfile (which is the subclass for new signups)
    final user = CustomerProfile(
      email: email,
      firstName: firstName,
      lastName: lastName,
      uid: uid,
      roles: roles ?? [UserRole.client],
      accountStatus: UserStatus.active,
      gender: 'unspecified',
      avatarUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      preferredPaymentMethod: 'cash',
      phoneNumbers: const [],
      addresses: const [],
    );

    return await userRepository.createUser(
      user: user,
    );
  }
}
