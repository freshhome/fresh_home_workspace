import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/data/user/models/address_model.dart';
import 'package:shared/data/user/models/remote/phone_model.dart';
part 'client_profile_hive_model.g.dart';

@HiveType(typeId: HiveTypeIds.clientProfile)
class ClientProfileHiveModel {
  @HiveField(0)
  final String uid;
  @HiveField(1)
  final List<AddressModel> addresses;
  @HiveField(2)
  final List<PhoneModel> phoneNumbers;

  ClientProfileHiveModel({
    required this.uid,
    required this.addresses,
    required this.phoneNumbers,
  });
}
