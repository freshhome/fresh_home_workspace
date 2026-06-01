
import 'package:shared/domain/user/entities/user/address.dart';

class ClientProfile {
  final String uid;
  final List<Address> addresses;
  final List<String> phoneNumbers;

  ClientProfile({
    required this.uid,
    required this.addresses,
    required this.phoneNumbers,
  });
}
