import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';

part 'technician_profile_hive_model.g.dart';

@HiveType(typeId: HiveTypeIds.technicianProfile)
class TechnicianProfileHiveModel {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final String? bio;
  @HiveField(2)
  final double rating;
  @HiveField(3)
  final int completedJobs;
  @HiveField(4)
  final bool isVerified;
  @HiveField(5)
  final bool isAvailable;
  @HiveField(6)
  final Map<String, dynamic>? serviceArea;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final DateTime updatedAt;

  const TechnicianProfileHiveModel({
    required this.userId,
    this.bio,
    this.rating = 5.0,
    this.completedJobs = 0,
    this.isVerified = false,
    this.isAvailable = false,
    this.serviceArea,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TechnicianProfileHiveModel.fromEntity(TechnicianProfile entity) {
    return TechnicianProfileHiveModel(
      userId: entity.uid,
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
