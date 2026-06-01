import 'package:equatable/equatable.dart';

class Technician extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final double rating;
  final int completedJobs;
  final bool isVerified;
  final bool isAvailable;
  final String? bio;
  final String? mainServiceId;

  const Technician({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.rating,
    required this.completedJobs,
    required this.isVerified,
    required this.isAvailable,
    this.bio,
    this.mainServiceId,
  });

  String get fullName => '$firstName $lastName';

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      completedJobs: json['completedJobs'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      isAvailable: json['isAvailable'] ?? false,
      bio: json['bio'],
      mainServiceId: json['mainServiceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'rating': rating,
      'completedJobs': completedJobs,
      'isVerified': isVerified,
      'isAvailable': isAvailable,
      'bio': bio,
      'mainServiceId': mainServiceId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        phone,
        avatarUrl,
        rating,
        completedJobs,
        isVerified,
        isAvailable,
        bio,
        mainServiceId,
      ];
}
