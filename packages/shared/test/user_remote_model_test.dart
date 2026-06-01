
import 'package:flutter_test/flutter_test.dart';

import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:shared/domain/user/enums/user_role.dart';

void main() {
  group('UserRemoteModel Roles Parsing', () {
    final baseJson = {
      'id': 'user-123',
      'first_name': 'Test',
      'last_name': 'User',
      'email': 'test@example.com',
      'account_status': 'active',
      'gender': 'male',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    test('should parse roles when roles is a Map (standard Supabase)', () {
      final json = Map<String, dynamic>.from(baseJson)..addAll({
        'user_roles': [
          {'roles': {'name': 'admin'}},
          {'roles': {'name': 'client'}},
        ]
      });

      final model = UserRemoteModel.fromJson(json);
      expect(model.roles, containsAll([UserRole.admin, UserRole.client]));
      expect(model.roles.length, 2);
    });

    test('should parse roles when roles is a List (Supabase nested join quirk)', () {
      final json = Map<String, dynamic>.from(baseJson)..addAll({
        'user_roles': [
          {'roles': [{'name': 'technician'}]},
        ]
      });

      final model = UserRemoteModel.fromJson(json);
      expect(model.roles, contains(UserRole.technician));
      expect(model.roles.length, 1);
    });

    test('should handle case-insensitivity and whitespace', () {
      final json = Map<String, dynamic>.from(baseJson)..addAll({
        'user_roles': [
          {'roles': {'name': ' Admin '}},
        ]
      });

      final model = UserRemoteModel.fromJson(json);
      expect(model.roles, contains(UserRole.admin));
    });

    test('should default to client role if user_roles is missing or empty', () {
      final jsonMissing = Map<String, dynamic>.from(baseJson);
      final modelMissing = UserRemoteModel.fromJson(jsonMissing);
      expect(modelMissing.roles, [UserRole.client]);

      final jsonEmpty = Map<String, dynamic>.from(baseJson)..addAll({'user_roles': []});
      final modelEmpty = UserRemoteModel.fromJson(jsonEmpty);
      expect(modelEmpty.roles, [UserRole.client]);
    });
  });
}
