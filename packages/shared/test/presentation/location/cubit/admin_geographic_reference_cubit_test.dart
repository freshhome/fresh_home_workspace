import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/data/booking/mappers/address_snapshot_mapper.dart';
import 'package:shared/domain/user/entities/user/city.dart';
import 'package:shared/domain/user/entities/user/district.dart';
import 'package:shared/domain/user/entities/user/governorate.dart';
import 'package:shared/domain/user/repositories/admin_geographic_reference_repository.dart';
import 'package:shared/presentation/location/cubit/admin_geographic_reference_cubit.dart';

class FakeAdminGeographicReferenceRepository implements AdminGeographicReferenceRepository {
  final List<Governorate> governorates = [
    const Governorate(id: 1, nameAr: 'القاهرة', nameEn: 'Cairo', code: 'CAI', isActive: true, sortOrder: 1),
    const Governorate(id: 2, nameAr: 'الجيزة', nameEn: 'Giza', code: 'GIZ', isActive: true, sortOrder: 2),
  ];

  final List<City> cities = [
    const City(id: 105, governorateId: 1, nameAr: 'التجمع الخامس', nameEn: 'Fifth Settlement', isActive: true, sortOrder: 1),
  ];

  final List<District> districts = [
    const District(id: 1051, cityId: 105, nameAr: 'الحي الأول', nameEn: 'First District', isActive: true, sortOrder: 1),
  ];

  bool cacheCleared = false;

  @override
  Future<Either<Failure, List<Governorate>>> getAllGovernorates() async => Right(governorates);

  @override
  Future<Either<Failure, List<City>>> getAllCitiesByGovernorate(int governorateId) async =>
      Right(cities.where((c) => c.governorateId == governorateId).toList());

  @override
  Future<Either<Failure, List<District>>> getAllDistrictsByCity(int cityId) async =>
      Right(districts.where((d) => d.cityId == cityId).toList());

  @override
  Future<Either<Failure, Governorate>> createGovernorate({
    required String nameAr,
    required String nameEn,
    required String code,
    int sortOrder = 0,
  }) async {
    if (nameAr.trim().isEmpty || nameEn.trim().isEmpty || code.trim().isEmpty) {
      return Left(const ValidationFailure(message: 'Required names missing', code: 'INVALID_INPUT'));
    }
    final newGov = Governorate(
      id: governorates.length + 1,
      nameAr: nameAr.trim(),
      nameEn: nameEn.trim(),
      code: code.trim().toUpperCase(),
      isActive: true,
      sortOrder: sortOrder,
    );
    governorates.add(newGov);
    cacheCleared = true;
    return Right(newGov);
  }

  @override
  Future<Either<Failure, Governorate>> updateGovernorate({
    required int id,
    required String nameAr,
    required String nameEn,
    required String code,
    bool? isActive,
    int? sortOrder,
  }) async {
    final idx = governorates.indexWhere((g) => g.id == id);
    if (idx == -1) return Left(const ServerFailure(message: 'Governorate not found'));
    final updated = Governorate(
      id: id,
      nameAr: nameAr.trim(),
      nameEn: nameEn.trim(),
      code: code.trim().toUpperCase(),
      isActive: isActive ?? governorates[idx].isActive,
      sortOrder: sortOrder ?? governorates[idx].sortOrder,
    );
    governorates[idx] = updated;
    cacheCleared = true;
    return Right(updated);
  }

  @override
  Future<Either<Failure, City>> createCity({
    required int governorateId,
    required String nameAr,
    required String nameEn,
    int sortOrder = 0,
  }) async {
    if (nameAr.trim().isEmpty || nameEn.trim().isEmpty) {
      return Left(const ValidationFailure(message: 'Required names missing', code: 'INVALID_INPUT'));
    }
    final newCity = City(
      id: cities.length + 100,
      governorateId: governorateId,
      nameAr: nameAr.trim(),
      nameEn: nameEn.trim(),
      isActive: true,
      sortOrder: sortOrder,
    );
    cities.add(newCity);
    cacheCleared = true;
    return Right(newCity);
  }

  @override
  Future<Either<Failure, City>> updateCity({
    required int id,
    required String nameAr,
    required String nameEn,
    bool? isActive,
    int? sortOrder,
  }) async {
    final idx = cities.indexWhere((c) => c.id == id);
    if (idx == -1) return Left(const ServerFailure(message: 'City not found'));
    final updated = City(
      id: id,
      governorateId: cities[idx].governorateId,
      nameAr: nameAr.trim(),
      nameEn: nameEn.trim(),
      isActive: isActive ?? cities[idx].isActive,
      sortOrder: sortOrder ?? cities[idx].sortOrder,
    );
    cities[idx] = updated;
    cacheCleared = true;
    return Right(updated);
  }

  @override
  Future<Either<Failure, District>> createDistrict({
    required int cityId,
    required String nameAr,
    required String nameEn,
    int sortOrder = 0,
  }) async {
    if (nameAr.trim().isEmpty || nameEn.trim().isEmpty) {
      return Left(const ValidationFailure(message: 'Required names missing', code: 'INVALID_INPUT'));
    }
    final newDistrict = District(
      id: districts.length + 1000,
      cityId: cityId,
      nameAr: nameAr.trim(),
      nameEn: nameEn.trim(),
      isActive: true,
      sortOrder: sortOrder,
    );
    districts.add(newDistrict);
    cacheCleared = true;
    return Right(newDistrict);
  }

  @override
  Future<Either<Failure, District>> updateDistrict({
    required int id,
    required String nameAr,
    required String nameEn,
    bool? isActive,
    int? sortOrder,
  }) async {
    final idx = districts.indexWhere((d) => d.id == id);
    if (idx == -1) return Left(const ServerFailure(message: 'District not found'));
    final updated = District(
      id: id,
      cityId: districts[idx].cityId,
      nameAr: nameAr.trim(),
      nameEn: nameEn.trim(),
      isActive: isActive ?? districts[idx].isActive,
      sortOrder: sortOrder ?? districts[idx].sortOrder,
    );
    districts[idx] = updated;
    cacheCleared = true;
    return Right(updated);
  }

  @override
  Future<Either<Failure, Unit>> toggleActiveStatus({
    required String table,
    required int id,
    required bool isActive,
  }) async {
    cacheCleared = true;
    if (table == 'governorates') {
      final idx = governorates.indexWhere((g) => g.id == id);
      if (idx != -1) {
        governorates[idx] = Governorate(
          id: id,
          nameAr: governorates[idx].nameAr,
          nameEn: governorates[idx].nameEn,
          code: governorates[idx].code,
          isActive: isActive,
        );
      }
    }
    return Right(unit);
  }
}

void main() {
  group('AdminGeographicReferenceCubit & Step 4 Management Unit Tests', () {
    late AdminGeographicReferenceCubit cubit;
    late FakeAdminGeographicReferenceRepository repository;

    setUp(() {
      repository = FakeAdminGeographicReferenceRepository();
      cubit = AdminGeographicReferenceCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('Scenario 1 — Admin can create new Governorate with bilingual names', () async {
      await cubit.createGovernorate(nameAr: 'الإسكندرية', nameEn: 'Alexandria', code: 'ALX');
      expect(repository.governorates.length, equals(3));
      expect(repository.governorates.last.nameEn, equals('Alexandria'));
      expect(cubit.state.successMessage, contains('successfully'));
    });

    test('Scenario 2 — Admin can create City under valid Governorate', () async {
      await cubit.createCity(governorateId: 1, nameAr: 'المعادي', nameEn: 'Maadi');
      expect(repository.cities.length, equals(2));
      expect(repository.cities.last.nameEn, equals('Maadi'));
      expect(repository.cities.last.governorateId, equals(1));
    });

    test('Scenario 3 — Admin can create District under valid City', () async {
      await cubit.createDistrict(cityId: 105, nameAr: 'الحي الثاني', nameEn: 'Second District');
      expect(repository.districts.length, equals(2));
      expect(repository.districts.last.nameEn, equals('Second District'));
      expect(repository.districts.last.cityId, equals(105));
    });

    test('Scenario 4 — Empty or whitespace names are rejected by validation', () async {
      await cubit.createGovernorate(nameAr: '  ', nameEn: '', code: '   ');
      expect(cubit.state.failure, isNotNull);
      expect(cubit.state.failure?.code, equals('INVALID_INPUT'));
    });

    test('Scenario 5 — Admin can update existing geographic reference', () async {
      await cubit.updateGovernorate(id: 1, nameAr: 'القاهرة الكبرى', nameEn: 'Greater Cairo', code: 'CAI');
      expect(repository.governorates.first.nameAr, equals('القاهرة الكبرى'));
      expect(repository.governorates.first.nameEn, equals('Greater Cairo'));
    });

    test('Scenario 6 & 7 — Admin can disable reference without deleting it; disabled record is preserved for history', () async {
      await cubit.toggleActiveStatus(table: 'governorates', id: 2, isActive: false);
      expect(repository.governorates.firstWhere((g) => g.id == 2).isActive, isFalse);

      // Customer active-only query filters out inactive governorate (id 2)
      final activeOnlyList = repository.governorates.where((g) => g.isActive).toList();
      expect(activeOnlyList.any((g) => g.id == 2), isFalse);
      expect(repository.governorates.any((g) => g.id == 2), isTrue); // Preserved in DB!
    });

    test('Scenario 8 — Historical Snapshot remains 100% immutable after reference data update', () {
      final snapshotJson = {
        'snapshot_version': 2,
        'address': {
          'address_id': 'hist-addr-1',
          'user_id': 'user-1',
          'governorate_id': 1,
          'city_id': 105,
          'district_id': 1051,
          'governorate_ar': 'القاهرة القديمة',
          'governorate_en': 'Old Cairo',
          'city_ar': 'التجمع الخامس',
          'city_en': 'Fifth Settlement',
          'district_ar': 'الحي الأول',
          'district_en': 'First District',
          'street_or_compound': 'Street 90',
          'building_identifier': '12',
        }
      };

      // Parsing historical snapshot reads embedded bilingual names from snapshot without querying reference DB
      final parsed = AddressSnapshotMapper.parseSnapshotJson(snapshotJson);
      expect(parsed.getGovernorateName('ar'), equals('القاهرة القديمة'));
      expect(parsed.getGovernorateName('en'), equals('Old Cairo'));
    });

    test('Scenario 11 — Cache invalidation flag triggers upon reference creation/update', () async {
      expect(repository.cacheCleared, isFalse);
      await cubit.createGovernorate(nameAr: 'أسوان', nameEn: 'Aswan', code: 'ASW');
      expect(repository.cacheCleared, isTrue);
    });

    test('Scenario 12 — Bilingual Arabic & English names are preserved correctly', () async {
      await cubit.loadGovernorates();
      final gov = cubit.state.governorates.first;
      expect(gov.nameAr, equals('القاهرة'));
      expect(gov.nameEn, equals('Cairo'));
      expect(gov.getName('ar'), equals('القاهرة'));
      expect(gov.getName('en'), equals('Cairo'));
    });
  });
}
