import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
part 'user_hive_model.g.dart';

@HiveType(typeId: HiveTypeIds.user)
class UserHiveModel {
  @HiveField(0)
  final int customId;
  @HiveField(1)
  final String uid;
  @HiveField(2)
  final String firstName;
  @HiveField(3)
  final String lastName;
  @HiveField(4)
  final String email;
  @HiveField(5)
  final String accountStatus;
  @HiveField(6)
  final String gender;
  @HiveField(10)
  final String? avatarUrl;
  @HiveField(7)
  final List<int> rolesCodes;
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9)
  final DateTime updatedAt;
  @HiveField(11)
  final List<String> phones;

  UserHiveModel({
    required this.customId,
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.accountStatus,
    required this.gender,
    this.avatarUrl,
    required this.rolesCodes,
    required this.createdAt,
    required this.updatedAt,
    this.phones = const [],
  });
}
