import 'package:json_annotation/json_annotation.dart';
import 'package:shared/domain/user/entities/user/capacity_pool.dart';

part 'capacity_pool_remote_model.g.dart';

@JsonSerializable()
class CapacityPoolRemoteModel {
  final String id;

  @JsonKey(name: 'technician_id')
  final String technicianId;

  final String title;

  @JsonKey(name: 'max_daily_capacity')
  final int maxDailyCapacity;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const CapacityPoolRemoteModel({
    required this.id,
    required this.technicianId,
    required this.title,
    required this.maxDailyCapacity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CapacityPoolRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$CapacityPoolRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$CapacityPoolRemoteModelToJson(this);

  CapacityPool toEntity() => CapacityPool(
        id: id,
        technicianId: technicianId,
        title: title,
        maxDailyCapacity: maxDailyCapacity,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
