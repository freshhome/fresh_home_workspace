import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared/core/constants/hive_constants.dart';

part 'phone_model.g.dart';

@HiveType(typeId: HiveTypeIds.phoneModel)
@JsonSerializable(explicitToJson: true)
class PhoneModel {
  @HiveField(0)
  @JsonKey(includeIfNull: false)
  final String? id;
  @HiveField(1)
  @JsonKey(name: 'user_id')
  final String userId;
  @HiveField(2)
  @JsonKey(name: 'phone_number')
  final String phoneNumber;
  @HiveField(3)
  @JsonKey(name: 'is_primary')
  final bool isPrimary;
  @HiveField(4)
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @HiveField(5)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const PhoneModel({
    this.id,
    required this.userId,
    required this.phoneNumber,
    required this.isPrimary,
    required this.isVerified,
    required this.createdAt,
  });

  factory PhoneModel.fromJson(Map<String, dynamic> json) =>
      _$PhoneModelFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneModelToJson(this);
}
