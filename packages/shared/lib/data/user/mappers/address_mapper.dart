import 'package:shared/data/user/models/address_model.dart';
import 'package:shared/domain/user/entities/user/address.dart';

/// Mapper class converting between Address Entity and AddressModel DTO.
class AddressMapper {
  static Address toEntity(AddressModel model) => model.toEntity();

  static AddressModel toModel(Address entity) => AddressModel.fromEntity(entity);

  static List<Address> toEntityList(List<AddressModel> models) {
    return models.map((m) => m.toEntity()).toList();
  }

  static List<AddressModel> toModelList(List<Address> entities) {
    return entities.map((e) => AddressModel.fromEntity(e)).toList();
  }
}
