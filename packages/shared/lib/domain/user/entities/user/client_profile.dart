
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/entities/user/phone.dart';

class ClientProfile {
  final String uid;
  final List<Address> addresses;
  final List<Phone> phoneNumbers;

  ClientProfile({
    required this.uid,
    required this.addresses,
    required this.phoneNumbers,
  });
}
