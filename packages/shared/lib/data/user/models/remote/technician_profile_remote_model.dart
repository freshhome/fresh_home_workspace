import 'package:json_annotation/json_annotation.dart';

part 'technician_profile_remote_model.g.dart';

@JsonSerializable(explicitToJson: true)
class TechnicianProfileRemoteModel {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'main_service_id')
  final String? mainServiceId;

  final String? bio;
  final double rating;

  @JsonKey(name: 'completed_jobs')
  final int completedJobs;

  @JsonKey(name: 'is_verified')
  final bool isVerified;

  @JsonKey(name: 'is_available')
  final bool isAvailable;

  @JsonKey(name: 'service_area')
  final Map<String, dynamic>? serviceArea;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
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
  });

  factory TechnicianProfileRemoteModel.fromJson(Map<String, dynamic> json) {
    final techData = json['technician_profiles'] != null
        ? (json['technician_profiles'] is List
            ? (json['technician_profiles'] as List).firstOrNull as Map<String, dynamic>?
            : json['technician_profiles'] as Map<String, dynamic>?)
        : null;

    final baseMap = techData ?? json;

    return TechnicianProfileRemoteModel(
      userId: json['id'] as String? ?? baseMap['user_id'] as String? ?? '',
      mainServiceId: baseMap['main_service_id'] as String?,
      bio: baseMap['bio'] as String?,
      rating: (baseMap['rating'] as num?)?.toDouble() ?? 5.0,
      completedJobs: baseMap['completed_jobs'] as int? ?? 0,
      isVerified: baseMap['is_verified'] as bool? ?? false,
      isAvailable: baseMap['is_available'] as bool? ?? false,
      serviceArea: baseMap['service_area'] as Map<String, dynamic>?,
      createdAt: baseMap['created_at'] != null 
          ? DateTime.parse(baseMap['created_at']) 
          : DateTime.now(),
      updatedAt: baseMap['updated_at'] != null 
          ? DateTime.parse(baseMap['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => _$TechnicianProfileRemoteModelToJson(this);
}
