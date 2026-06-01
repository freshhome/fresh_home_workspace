import 'package:json_annotation/json_annotation.dart';
import 'package:shared/domain/user/entities/user/technician_skill.dart';

part 'technician_skill_remote_model.g.dart';

@JsonSerializable()
class TechnicianSkillRemoteModel {
  final String id;

  @JsonKey(name: 'technician_id')
  final String technicianId;

  @JsonKey(name: 'sub_service_id')
  final String subServiceId;

  @JsonKey(name: 'capacity_pool_id')
  final String capacityPoolId;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const TechnicianSkillRemoteModel({
    required this.id,
    required this.technicianId,
    required this.subServiceId,
    required this.capacityPoolId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TechnicianSkillRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$TechnicianSkillRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$TechnicianSkillRemoteModelToJson(this);

  TechnicianSkill toEntity() => TechnicianSkill(
        id: id,
        technicianId: technicianId,
        subServiceId: subServiceId,
        capacityPoolId: capacityPoolId,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
