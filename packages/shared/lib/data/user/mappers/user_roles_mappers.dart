import 'package:shared/domain/user/enums/user_role.dart';

Map<UserRole, int> userRoleCodes = {
  UserRole.client: 10,
  UserRole.technician: 20,
  UserRole.admin: 30,
};

List<int> userRoleToCode({required List<UserRole> userRoles}) {
  return userRoles.map((userRole) => userRoleCodes[userRole]!).toList();
}

List<UserRole> userRoleFromCode({required List<int> codes}) {
  return codes
      .map(
        (code) => userRoleCodes.entries
            .firstWhere(
              (entry) => entry.value == code,
              orElse: () => MapEntry(UserRole.client, 10),
            )
            .key,
      )
      .toList();
}
