
import 'package:shared/data/user/models/address_model.dart';
import 'package:shared/domain/user/entities/user/address.dart';

class AddressMapper {

static Address fromModel(AddressModel model) {
  return Address(
    id: model.id,
    governorate: model.governorate,
    city: model.city,
    street: model.street,
    buildingNumber: model.buildingNumber,
    floorNumber: model.floorNumber,
    apartmentNumber: model.apartmentNumber,
  );
}

static AddressModel toModel(Address entity) {
  return AddressModel(
    id: entity.id,
    governorate: entity.governorate,
    city: entity.city,
    street: entity.street,
    buildingNumber: entity.buildingNumber,
    floorNumber: entity.floorNumber,
    apartmentNumber: entity.apartmentNumber,
  );
}










}
