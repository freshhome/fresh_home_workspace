import 'package:shared/data/user/models/remote/phone_model.dart';
import 'package:shared/domain/user/entities/user/phone.dart';

class PhoneMapper {
  static Phone fromModel(PhoneModel model) {
    return Phone(
      id: model.id,
      userId: model.userId,
      phoneNumber: model.phoneNumber,
      isPrimary: model.isPrimary,
      isVerified: model.isVerified,
      createdAt: model.createdAt,
    );
  }

  static PhoneModel toModel(Phone entity) {
    return PhoneModel(
      id: entity.id,
      userId: entity.userId,
      phoneNumber: entity.phoneNumber,
      isPrimary: entity.isPrimary,
      isVerified: entity.isVerified,
      createdAt: entity.createdAt,
    );
  }
}
