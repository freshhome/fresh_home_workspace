import 'package:json_annotation/json_annotation.dart';

part 'admin_profile_remote_model.g.dart';

@JsonSerializable(explicitToJson: true)
class AdminProfileRemoteModel {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'admin_permissions', defaultValue: [])
  final List<String> adminPermissions;

  AdminProfileRemoteModel({
    required this.userId,
    required this.adminPermissions,
  });

  factory AdminProfileRemoteModel.fromJson(Map<String, dynamic> json) {
    final adminData = json['admin_profiles'] != null
        ? (json['admin_profiles'] is List
            ? (json['admin_profiles'] as List).firstOrNull as Map<String, dynamic>?
            : json['admin_profiles'] as Map<String, dynamic>?)
        : null;

    return AdminProfileRemoteModel(
      userId: json['id'] as String? ?? adminData?['user_id'] as String? ?? '',
      adminPermissions: adminData != null && adminData['admin_permissions'] != null
          ? (adminData['admin_permissions'] as List).map((e) => e.toString()).toList()
          : (json['admin_permissions'] != null
              ? (json['admin_permissions'] as List).map((e) => e.toString()).toList()
              : []),
    );
  }

  Map<String, dynamic> toJson() => _$AdminProfileRemoteModelToJson(this);
}
