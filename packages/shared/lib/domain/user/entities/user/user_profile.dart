import 'package:equatable/equatable.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/entities/user/capacity_pool.dart';
import 'package:shared/domain/user/entities/user/phone.dart';
import 'package:shared/domain/user/entities/user/technician_skill.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/domain/user/enums/user_status.dart';

/// Base sealed class for all user profile roles in the system.
sealed class UserProfile extends Equatable {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final UserStatus accountStatus;
  final String gender;
  final String? avatarUrl;
  final List<UserRole> roles;
  final List<Phone> phoneNumbers;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.accountStatus,
    required this.gender,
    this.avatarUrl,
    required this.roles,
    this.phoneNumbers = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isClient => roles.contains(UserRole.client);
  bool get isTechnician => roles.contains(UserRole.technician);
  bool get isAdmin => roles.contains(UserRole.admin);

  @override
  List<Object?> get props => [
        uid,
        firstName,
        lastName,
        email,
        accountStatus,
        gender,
        avatarUrl,
        roles,
        phoneNumbers,
        createdAt,
        updatedAt,
      ];
}

/// Represents the profile of a Customer (Client App)
class CustomerProfile extends UserProfile {
  final String preferredPaymentMethod;
  final List<Address> addresses;

  const CustomerProfile({
    required super.uid,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.accountStatus,
    required super.gender,
    super.avatarUrl,
    required super.roles,
    super.phoneNumbers = const [],
    required super.createdAt,
    required super.updatedAt,
    required this.preferredPaymentMethod,
    this.addresses = const [],
  });

  @override
  List<Object?> get props => [
        ...super.props,
        preferredPaymentMethod,
        addresses,
      ];
}

/// Represents the profile of a Technician (Staff App)
class TechnicianProfile extends UserProfile {
  final String? mainServiceId;
  final String? bio;
  final double rating;
  final int completedJobs;
  final bool isVerified;
  final bool isAvailable;
  final Map<String, dynamic>? serviceArea;
  final List<CapacityPool> capacityPools;
  final List<TechnicianSkill> technicianSkills;
  final Map<String, String> subServiceNames;

  const TechnicianProfile({
    required super.uid,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.accountStatus,
    required super.gender,
    super.avatarUrl,
    required super.roles,
    super.phoneNumbers = const [],
    required super.createdAt,
    required super.updatedAt,
    this.mainServiceId,
    this.bio,
    this.rating = 5.0,
    this.completedJobs = 0,
    this.isVerified = false,
    this.isAvailable = false,
    this.serviceArea,
    this.capacityPools = const [],
    this.technicianSkills = const [],
    this.subServiceNames = const {},
  });

  @override
  List<Object?> get props => [
        ...super.props,
        mainServiceId,
        bio,
        rating,
        completedJobs,
        isVerified,
        isAvailable,
        serviceArea,
        capacityPools,
        technicianSkills,
        subServiceNames,
      ];
}

/// Represents the profile of an Administrator (Admin Dashboard)
class AdminProfile extends UserProfile {
  final List<String> adminPermissions;

  const AdminProfile({
    required super.uid,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.accountStatus,
    required super.gender,
    super.avatarUrl,
    required super.roles,
    super.phoneNumbers = const [],
    required super.createdAt,
    required super.updatedAt,
    required this.adminPermissions,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        adminPermissions,
      ];
}
