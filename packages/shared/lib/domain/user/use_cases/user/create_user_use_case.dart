import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/user/entities/user/user.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/domain/user/enums/user_status.dart';
import 'package:shared/domain/user/repositories/user_repository.dart';
import 'package:shared/domain/counter/use_cases/generate_next_id_usecase/get_next_id_use_case.dart';
import 'package:shared/core/error/failures.dart';

class CreateUserUseCase {
  final UserRepository userRepository;
  final GetNextIdUseCase getNextIdUseCase;

  CreateUserUseCase({
    required this.userRepository,
    required this.getNextIdUseCase,
  });

  Future<Either<Failure, void>> call({
    required String email,
    required String firstName,
    required String lastName,
    required String uid,
    List<UserRole>? roles,
  }) async {
    // 1️⃣ توليد customId 
    final result = await getNextIdUseCase('users');

    if (result.isLeft()) {
      return Left(result.swap().getOrElse((_) => const UnknownFailure(
        message: 'Failed to generate custom ID',
        code: 'id_generation_failed',
      )));
    }

    final customId = result.getOrElse((_) => throw Exception('ID should exist'));

    // 2️⃣ إنشاء المستخدم
    final user = User(
      email: email,
      firstName: firstName,
      lastName: lastName,
      uid: uid,
      roles: roles ?? [UserRole.client],
      customId: customId,
      accountStatus: UserStatus.active,
      gender: 'unspecified',
      avatarUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 3️⃣ إرسال المستخدم للـ Repository
    return await userRepository.createUser(
      user: user,
    );
  }
}
