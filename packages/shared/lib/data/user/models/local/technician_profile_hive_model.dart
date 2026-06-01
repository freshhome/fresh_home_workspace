import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/domain/user/entities/user/technician_profile.dart';

part 'technician_profile_hive_model.g.dart';

@HiveType(typeId: HiveTypeIds.technicianProfile)
class TechnicianProfileHiveModel extends TechnicianProfile {
  @HiveField(0)
  @override
  final String userId;
  @HiveField(1)
  @override
  final String? bio;
  @HiveField(2)
  @override
  final double rating;
  @HiveField(3)
  @override
  final int completedJobs;
  @HiveField(4)
  @override
  final bool isVerified;
  @HiveField(5)
  @override
  final bool isAvailable;
  @HiveField(6)
  @override
  final Map<String, dynamic>? serviceArea;
  @HiveField(7)
  @override
  final DateTime createdAt;
  @HiveField(8)
  @override
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
  }) : super(
          userId: userId,
          bio: bio,
          rating: rating,
          completedJobs: completedJobs,
          isVerified: isVerified,
          isAvailable: isAvailable,
          serviceArea: serviceArea,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory TechnicianProfileHiveModel.fromEntity(TechnicianProfile entity) {
    return TechnicianProfileHiveModel(
      userId: entity.userId,
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
