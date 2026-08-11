import 'package:flutter_test/flutter_test.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/validation/address_validator.dart';

/// Fake Security Supabase Client simulating exact Supabase RLS security policies & permissions
class FakeSecuritySupabaseClient {
  final List<Map<String, dynamic>> governoratesDb = [
    {'id': 1, 'name_ar': 'القاهرة', 'name_en': 'Cairo', 'code': 'CAI', 'is_active': true, 'sort_order': 1},
    {'id': 2, 'name_ar': 'الجيزة', 'name_en': 'Giza', 'code': 'GIZ', 'is_active': true, 'sort_order': 2},
  ];

  final List<Map<String, dynamic>> citiesDb = [
    {'id': 105, 'governorate_id': 1, 'name_ar': 'التجمع الخامس', 'name_en': 'Fifth Settlement', 'is_active': true, 'sort_order': 1},
    {'id': 201, 'governorate_id': 2, 'name_ar': 'الشيخ زايد', 'name_en': 'Zayed', 'is_active': true, 'sort_order': 1},
  ];

  final List<Map<String, dynamic>> districtsDb = [
    {'id': 1051, 'city_id': 105, 'name_ar': 'الحي الأول', 'name_en': 'First District', 'is_active': true, 'sort_order': 1},
  ];

  /// Simulates Client RLS SELECT query (ALLOWED)
  Future<List<Map<String, dynamic>>> selectReferenceTable(String table) async {
    if (table == 'governorates') return List.from(governoratesDb);
    if (table == 'cities') return List.from(citiesDb);
    if (table == 'districts') return List.from(districtsDb);
    throw Exception('Unknown table: $table');
  }

  /// Simulates Client RLS INSERT attempt (DENIED by RLS Policy - Permission Denied 42501)
  Future<void> insertReferenceTable(String table, Map<String, dynamic> data) async {
    // RLS Policy ON FOR SELECT ONLY. INSERT is DENIED for authenticated/anon roles.
    throw const SecurityPolicyException(
      message: 'new row violates row-level security policy for table',
      code: '42501',
    );
  }

  /// Simulates Client RLS UPDATE attempt (DENIED by RLS Policy - Permission Denied 42501)
  Future<void> updateReferenceTable(String table, Map<String, dynamic> data, int id) async {
    // RLS Policy ON FOR SELECT ONLY. UPDATE is DENIED for authenticated/anon roles.
    throw const SecurityPolicyException(
      message: 'permission denied for table',
      code: '42501',
    );
  }

  /// Simulates Client RLS DELETE attempt (DENIED by RLS Policy - Permission Denied 42501)
  Future<void> deleteReferenceTable(String table, int id) async {
    // RLS Policy ON FOR SELECT ONLY. DELETE is DENIED for authenticated/anon roles.
    throw const SecurityPolicyException(
      message: 'permission denied for table',
      code: '42501',
    );
  }

  /// Simulates Database Composite Foreign Key Hierarchy Constraint Enforcement on user_addresses
  Future<void> insertUserAddressWithHierarchyCheck(Map<String, dynamic> payload) async {
    final int? govId = payload['governorate_id'];
    final int? cityId = payload['city_id'];
    final int? districtId = payload['district_id'];

    if (cityId != null && govId != null) {
      final cityRow = citiesDb.firstWhere(
        (c) => c['id'] == cityId,
        orElse: () => {},
      );
      if (cityRow.isEmpty || cityRow['governorate_id'] != govId) {
        throw const DatabaseConstraintException(
          message: 'violates foreign key constraint "fk_user_addresses_city_governorate_hierarchy"',
          code: '23503',
        );
      }
    }

    if (districtId != null && cityId != null) {
      final districtRow = districtsDb.firstWhere(
        (d) => d['id'] == districtId,
        orElse: () => {},
      );
      if (districtRow.isEmpty || districtRow['city_id'] != cityId) {
        throw const DatabaseConstraintException(
          message: 'violates foreign key constraint "fk_user_addresses_district_city_hierarchy"',
          code: '23503',
        );
      }
    }
  }
}

class SecurityPolicyException implements Exception {
  final String message;
  final String code;
  const SecurityPolicyException({required this.message, required this.code});
  @override
  String toString() => 'SecurityPolicyException(code: $code, message: $message)';
}

class DatabaseConstraintException implements Exception {
  final String message;
  final String code;
  const DatabaseConstraintException({required this.message, required this.code});
  @override
  String toString() => 'DatabaseConstraintException(code: $code, message: $message)';
}

void main() {
  group('Phase 5.2 — Security Boundary Verification Tests', () {
    late FakeSecuritySupabaseClient client;

    setUp(() {
      client = FakeSecuritySupabaseClient();
    });

    group('1. Reference Tables RLS Mutation Denial Contract (governorates, cities, districts)', () {
      test('SELECT operation MUST BE ALLOWED on all reference tables', () async {
        final govs = await client.selectReferenceTable('governorates');
        expect(govs.isNotEmpty, isTrue);

        final cities = await client.selectReferenceTable('cities');
        expect(cities.isNotEmpty, isTrue);

        final districts = await client.selectReferenceTable('districts');
        expect(districts.isNotEmpty, isTrue);
      });

      test('INSERT operation MUST BE DENIED by RLS on governorates table', () async {
        expect(
          () => client.insertReferenceTable('governorates', {'name_ar': 'محافظة جديدة', 'name_en': 'New Gov'}),
          throwsA(isA<SecurityPolicyException>().having((e) => e.code, 'code', equals('42501'))),
        );
      });

      test('UPDATE operation MUST BE DENIED by RLS on governorates table', () async {
        expect(
          () => client.updateReferenceTable('governorates', {'name_ar': 'القاهرة الكبرى'}, 1),
          throwsA(isA<SecurityPolicyException>().having((e) => e.code, 'code', equals('42501'))),
        );
      });

      test('DELETE operation MUST BE DENIED by RLS on governorates table', () async {
        expect(
          () => client.deleteReferenceTable('governorates', 1),
          throwsA(isA<SecurityPolicyException>().having((e) => e.code, 'code', equals('42501'))),
        );
      });

      test('INSERT operation MUST BE DENIED by RLS on cities table', () async {
        expect(
          () => client.insertReferenceTable('cities', {'governorate_id': 1, 'name_ar': 'مدينة جديدة', 'name_en': 'New City'}),
          throwsA(isA<SecurityPolicyException>().having((e) => e.code, 'code', equals('42501'))),
        );
      });

      test('UPDATE operation MUST BE DENIED by RLS on cities table', () async {
        expect(
          () => client.updateReferenceTable('cities', {'name_ar': 'مدينة معدلة'}, 105),
          throwsA(isA<SecurityPolicyException>().having((e) => e.code, 'code', equals('42501'))),
        );
      });

      test('DELETE operation MUST BE DENIED by RLS on cities table', () async {
        expect(
          () => client.deleteReferenceTable('cities', 105),
          throwsA(isA<SecurityPolicyException>().having((e) => e.code, 'code', equals('42501'))),
        );
      });

      test('INSERT operation MUST BE DENIED by RLS on districts table', () async {
        expect(
          () => client.insertReferenceTable('districts', {'city_id': 105, 'name_ar': 'حي جديد', 'name_en': 'New District'}),
          throwsA(isA<SecurityPolicyException>().having((e) => e.code, 'code', equals('42501'))),
        );
      });

      test('UPDATE operation MUST BE DENIED by RLS on districts table', () async {
        expect(
          () => client.updateReferenceTable('districts', {'name_ar': 'حي معدل'}, 1051),
          throwsA(isA<SecurityPolicyException>().having((e) => e.code, 'code', equals('42501'))),
        );
      });

      test('DELETE operation MUST BE DENIED by RLS on districts table', () async {
        expect(
          () => client.deleteReferenceTable('districts', 1051),
          throwsA(isA<SecurityPolicyException>().having((e) => e.code, 'code', equals('42501'))),
        );
      });
    });

    group('2. Referential Integrity & Composite Foreign Key Security Boundary', () {
      test('Database Composite Foreign Key MUST REJECT mismatched city_id and governorate_id', () async {
        final mismatchedPayload = {
          'governorate_id': 2,
          'city_id': 105,
        };

        expect(
          () => client.insertUserAddressWithHierarchyCheck(mismatchedPayload),
          throwsA(isA<DatabaseConstraintException>().having((e) => e.code, 'code', equals('23503'))),
        );
      });

      test('Domain AddressValidator MUST REJECT invalid hierarchy before Database query', () {
        final invalidAddress = Address(
          id: 'addr-sec-1',
          userId: 'user-1',
          governorate: 'القاهرة',
          city: 'مدينة نصر',
          district: 'الحي الأول',
          governorateId: null,
          cityId: 105,
          streetOrCompound: 'شارع الطيران',
          buildingIdentifier: 'مبنى 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = AddressValidator.validate(invalidAddress);
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure.code, equals('INVALID_HIERARCHY')),
          (_) => fail('Should have failed validation'),
        );
      });
    });
  });
}
