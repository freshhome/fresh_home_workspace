import 'package:json_annotation/json_annotation.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/domain/user/enums/user_status.dart';

part 'user_remote_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserRemoteModel {
  final String id;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  final String email;
  @JsonKey(name: 'account_status')
  final UserStatus accountStatus;
  final String gender;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final List<UserRole> roles;
  
  // New fields for detailed view
  @JsonKey(name: 'user_phones', includeFromJson: true, includeToJson: false)
  final List<UserPhoneRemoteModel>? phones;
  @JsonKey(name: 'user_addresses', includeFromJson: true, includeToJson: false)
  final List<UserAddressRemoteModel>? addresses;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName'.trim();
  String get uid => id;

  const UserRemoteModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.accountStatus,
    required this.gender,
    this.avatarUrl,
    required this.roles,
    this.phones,
    this.addresses,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserRemoteModel.fromJson(Map<String, dynamic> json) {
    // Extract roles from nested user_roles(roles(name))
    List<UserRole> extractedRoles = [];
    if (json['user_roles'] != null) {
      final userRolesList = json['user_roles'] as List;
      for (var ur in userRolesList) {
        final roleRaw = ur['roles'];
        
        // Supabase select user_roles(roles(name)) can return roles as a single Object or a List
        if (roleRaw != null) {
          String? roleName;
          
          if (roleRaw is Map && roleRaw['name'] != null) {
            roleName = roleRaw['name'] as String;
          } else if (roleRaw is List && roleRaw.isNotEmpty) {
            final firstRole = roleRaw[0] as Map;
            roleName = firstRole['name'] as String?;
          }
          
          if (roleName != null) {
            final normalizedName = roleName.trim().toLowerCase();
            final matchedRole = UserRole.values.cast<UserRole?>().firstWhere(
              (e) => e!.name.toLowerCase() == normalizedName,
              orElse: () => null,
            );
            
            if (matchedRole != null && !extractedRoles.contains(matchedRole)) {
              extractedRoles.add(matchedRole);
            }
          }
        }
      }
    }
    
    // Ensure every user has at least the client role if no roles are explicitly found
    if (extractedRoles.isEmpty) {
      extractedRoles.add(UserRole.client);
    }

    return UserRemoteModel(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      accountStatus: UserStatus.values.firstWhere(
        (e) => e.name == (json['account_status'] as String? ?? 'active'),
        orElse: () => UserStatus.active,
      ),
      gender: json['gender'] as String? ?? 'unspecified',
      avatarUrl: json['avatar_url'] as String?,
      roles: extractedRoles,
      phones: json['user_phones'] != null 
          ? (json['user_phones'] as List).map((e) => UserPhoneRemoteModel.fromJson(e)).toList() 
          : null,
      addresses: json['user_addresses'] != null 
          ? (json['user_addresses'] as List).map((e) => UserAddressRemoteModel.fromJson(e)).toList() 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  UserRemoteModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    UserStatus? accountStatus,
    String? gender,
    String? avatarUrl,
    List<UserRole>? roles,
    List<UserPhoneRemoteModel>? phones,
    List<UserAddressRemoteModel>? addresses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserRemoteModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      accountStatus: accountStatus ?? this.accountStatus,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      roles: roles ?? this.roles,
      phones: phones ?? this.phones,
      addresses: addresses ?? this.addresses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'account_status': accountStatus.name,
      'gender': gender,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class UserPhoneRemoteModel {
  final String id;
  final String phoneNumber;
  final bool isPrimary;
  final bool isVerified;

  UserPhoneRemoteModel({
    required this.id,
    required this.phoneNumber,
    required this.isPrimary,
    required this.isVerified,
  });

  factory UserPhoneRemoteModel.fromJson(Map<String, dynamic> json) {
    return UserPhoneRemoteModel(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }
}

class UserAddressRemoteModel {
  final String id;
  final String governorate;
  final String city;
  final String street;
  final String buildingNumber;
  final String? floor;
  final String? apartment;
  final bool isPrimary;

  UserAddressRemoteModel({
    required this.id,
    required this.governorate,
    required this.city,
    required this.street,
    required this.buildingNumber,
    this.floor,
    this.apartment,
    required this.isPrimary,
  });

  factory UserAddressRemoteModel.fromJson(Map<String, dynamic> json) {
    return UserAddressRemoteModel(
      id: json['id'] as String,
      governorate: json['governorate'] as String,
      city: json['city'] as String,
      street: json['street'] as String,
      buildingNumber: json['building_number'] as String,
      floor: json['floor'] as String?,
      apartment: json['apartment'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  String get fullAddress => '$buildingNumber $street, $city, $governorate';
}
