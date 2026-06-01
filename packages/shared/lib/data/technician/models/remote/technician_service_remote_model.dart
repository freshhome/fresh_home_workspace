import 'package:json_annotation/json_annotation.dart';

part 'technician_service_remote_model.g.dart';

@JsonSerializable()
class TechnicianServiceRemoteModel {
  final String id;
  @JsonKey(name: 'technician_id')
  final String technicianId;
  @JsonKey(name: 'sub_service_id')
  final String subServiceId;
  @JsonKey(name: 'capacity_per_day')
  final int capacityPerDay;
  @JsonKey(name: 'is_active')
  final bool isActive;

  // Optional: join with sub_services to get names
  @JsonKey(name: 'sub_services')
  final Map<String, dynamic>? subService;

  TechnicianServiceRemoteModel({
    required this.id,
    required this.technicianId,
    required this.subServiceId,
    required this.capacityPerDay,
    this.isActive = true,
    this.subService,
  });

  factory TechnicianServiceRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$TechnicianServiceRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$TechnicianServiceRemoteModelToJson(this);
}
