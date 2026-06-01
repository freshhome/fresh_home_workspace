import 'package:json_annotation/json_annotation.dart';
import 'package:shared/domain/user/entities/user/technician_profile.dart';

part 'technician_profile_remote_model.g.dart';

@JsonSerializable(explicitToJson: true)
class TechnicianProfileRemoteModel extends TechnicianProfile {
  @JsonKey(name: 'user_id')
  @override
  final String userId;

  @JsonKey(name: 'main_service_id')
  @override
  final String? mainServiceId; // NEW: One-service restriction

  @override
  final String? bio;
  @override
  final double rating;
  @JsonKey(name: 'completed_jobs')
  @override
  final int completedJobs;
  @JsonKey(name: 'is_verified')
  @override
  final bool isVerified;
  @JsonKey(name: 'is_available')
  @override
  final bool isAvailable;
  @JsonKey(name: 'service_area')
  @override
  final Map<String, dynamic>? serviceArea;
  @JsonKey(name: 'created_at')
  @override
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  @override
  final DateTime updatedAt;

  const TechnicianProfileRemoteModel({
    required this.userId,
    this.mainServiceId,
    this.bio,
    this.rating = 5.0,
    this.completedJobs = 0,
    this.isVerified = false,
    this.isAvailable = false,
    this.serviceArea,
    required this.createdAt,
    required this.updatedAt,
  }) : super(
          userId: userId,
          mainServiceId: mainServiceId,
          bio: bio,
          rating: rating,
          completedJobs: completedJobs,
          isVerified: isVerified,
          isAvailable: isAvailable,
          serviceArea: serviceArea,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory TechnicianProfileRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$TechnicianProfileRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$TechnicianProfileRemoteModelToJson(this);

  TechnicianProfile toDomain() => TechnicianProfile(
        userId: userId,
        mainServiceId: mainServiceId,
        bio: bio,
        rating: rating,
        completedJobs: completedJobs,
        isVerified: isVerified,
        isAvailable: isAvailable,
        serviceArea: serviceArea,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory TechnicianProfileRemoteModel.fromEntity(TechnicianProfile entity) {
    return TechnicianProfileRemoteModel(
      userId: entity.userId,
      mainServiceId: entity.mainServiceId,
      bio: entity.bio,
      rating: entity.rating,
      completedJobs: entity.completedJobs,
      isVerified: entity.isVerified,
      isAvailable: entity.isAvailable,
      serviceArea: entity.serviceArea,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
