import 'package:equatable/equatable.dart';

class TechnicianProfile extends Equatable {
  final String userId;
  final String? mainServiceId; // Binds technician to one main service category
  final String? bio;
  final double rating;
  final int completedJobs;
  final bool isVerified;
  final bool isAvailable;
  final Map<String, dynamic>? serviceArea;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TechnicianProfile({
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

  @override
  List<Object?> get props => [
        userId,
        mainServiceId,
        bio,
        rating,
        completedJobs,
        isVerified,
        isAvailable,
        serviceArea,
        createdAt,
        updatedAt,
      ];
}
