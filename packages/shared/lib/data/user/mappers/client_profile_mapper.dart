
import 'package:shared/data/user/mappers/address_mapper.dart';
import 'package:shared/data/user/models/local/client_profile_hive_model.dart';
import 'package:shared/data/user/models/remote/client_profile_remote_model.dart';
import 'package:shared/data/user/mappers/phone_mapper.dart';
import 'package:shared/domain/user/entities/user/client_profile.dart';

class ClientProfileMapper {

static ClientProfile fromRemote(ClientProfileRemoteModel model) {
  return ClientProfile(
    uid: model.uid,
    addresses: model.addresses.map((e) => AddressMapper.fromModel(e)).toList(),
    phoneNumbers: model.phoneNumbers.map((e) => PhoneMapper.fromModel(e)).toList(),
  );
}

static ClientProfile fromHive(ClientProfileHiveModel model) {
  return ClientProfile(
    uid: model.uid,
    addresses: model.addresses.map((e) => AddressMapper.fromModel(e)).toList(),
    phoneNumbers: model.phoneNumbers.map((e) => PhoneMapper.fromModel(e)).toList(),
  );
}

static ClientProfileRemoteModel toRemote(ClientProfile entity) {
  return ClientProfileRemoteModel(
    uid: entity.uid,
    addresses: entity.addresses.map((e) => AddressMapper.toModel(e)).toList(),
    phoneNumbers: entity.phoneNumbers.map((e) => PhoneMapper.toModel(e)).toList(),
  );
}

static ClientProfileHiveModel toHive(ClientProfile entity) {
  return ClientProfileHiveModel(
    uid: entity.uid,
    addresses: entity.addresses.map((e) => AddressMapper.toModel(e)).toList(),
    phoneNumbers: entity.phoneNumbers.map((e) => PhoneMapper.toModel(e)).toList(),
  );
}

}
