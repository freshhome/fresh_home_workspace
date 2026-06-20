import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/phone.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import '../repositories/profile_repository.dart';

class UpdatePhoneNumbersUseCase {
  final ProfileRepository repository;

  UpdatePhoneNumbersUseCase(this.repository);

  Future<Either<Failure, UserProfile>> call(List<Phone> phoneNumbers) {
    return repository.updatePhoneNumbers(phoneNumbers: phoneNumbers);
  }
}
