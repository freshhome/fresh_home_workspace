import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/city.dart';
import 'package:shared/domain/user/entities/user/district.dart';
import 'package:shared/domain/user/entities/user/governorate.dart';
import 'package:shared/domain/user/repositories/geographic_reference_repository.dart';
import 'package:shared/domain/user/usecases/get_active_cities_by_governorate_usecase.dart';
import 'package:shared/domain/user/usecases/get_active_districts_by_city_usecase.dart';
import 'package:shared/domain/user/usecases/get_active_governorates_usecase.dart';
import 'package:shared/presentation/location/cubit/geographic_reference_cubit.dart';

class FakeGeographicReferenceRepository implements GeographicReferenceRepository {
  final List<Governorate> governorates;
  final Map<int, List<City>> citiesMap;
  final Map<int, List<District>> districtsMap;

  FakeGeographicReferenceRepository({
    required this.governorates,
    required this.citiesMap,
    required this.districtsMap,
  });

  @override
  Future<Either<Failure, List<Governorate>>> getGovernorates() async {
    return Right(governorates);
  }

  @override
  Future<Either<Failure, List<City>>> getCitiesByGovernorate(int governorateId) async {
    return Right(citiesMap[governorateId] ?? []);
  }

  @override
  Future<Either<Failure, List<District>>> getDistrictsByCity(int cityId) async {
    return Right(districtsMap[cityId] ?? []);
  }
}

void main() {
  group('GeographicReferenceCubit Cascading State Unit Tests', () {
    late GeographicReferenceCubit cubit;
    late FakeGeographicReferenceRepository repository;

    const sampleGovs = [
      Governorate(id: 1, nameAr: 'القاهرة', nameEn: 'Cairo', code: 'CAI'),
      Governorate(id: 2, nameAr: 'الجيزة', nameEn: 'Giza', code: 'GIZ'),
    ];

    const cairoCities = [
      City(id: 105, governorateId: 1, nameAr: 'التجمع الخامس', nameEn: 'Fifth Settlement'),
    ];

    const gizaCities = [
      City(id: 201, governorateId: 2, nameAr: 'الشيخ زايد', nameEn: 'Zayed'),
    ];

    const fifthSettlementDistricts = [
      District(id: 1051, cityId: 105, nameAr: 'الحي الأول', nameEn: 'First District'),
    ];

    setUp(() {
      repository = FakeGeographicReferenceRepository(
        governorates: sampleGovs,
        citiesMap: {1: cairoCities, 2: gizaCities},
        districtsMap: {105: fifthSettlementDistricts},
      );

      cubit = GeographicReferenceCubit(
        getActiveGovernoratesUseCase: GetActiveGovernoratesUseCase(repository),
        getActiveCitiesByGovernorateUseCase: GetActiveCitiesByGovernorateUseCase(repository),
        getActiveDistrictsByCityUseCase: GetActiveDistrictsByCityUseCase(repository),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('loadGovernorates should fetch active governorates', () async {
      await cubit.loadGovernorates();
      expect(cubit.state.governorates.length, equals(2));
      expect(cubit.state.governorates.first.nameEn, equals('Cairo'));
    });

    test('selectGovernorate should load cities and clear previous city & district selections', () async {
      await cubit.loadGovernorates();
      await cubit.selectGovernorate(1);

      expect(cubit.state.selectedGovernorateId, equals(1));
      expect(cubit.state.cities.length, equals(1));
      expect(cubit.state.cities.first.nameEn, equals('Fifth Settlement'));
      expect(cubit.state.selectedCityId, isNull);
      expect(cubit.state.selectedDistrictId, isNull);
    });

    test('changing governorate should clear old city and district selections (Cascading Integrity)', () async {
      await cubit.loadGovernorates();
      await cubit.selectGovernorate(1);
      await cubit.selectCity(105);
      cubit.selectDistrict(1051);

      expect(cubit.state.selectedCityId, equals(105));
      expect(cubit.state.selectedDistrictId, equals(1051));

      // Change governorate to Giza (2)
      await cubit.selectGovernorate(2);

      expect(cubit.state.selectedGovernorateId, equals(2));
      expect(cubit.state.cities.first.nameEn, equals('Zayed'));
      expect(cubit.state.selectedCityId, isNull);
      expect(cubit.state.selectedDistrictId, isNull);
      expect(cubit.state.districts, isEmpty);
    });

    test('selectCity should load correct districts and keep selected city ID', () async {

      await cubit.loadGovernorates();
      await cubit.selectGovernorate(1);
      await cubit.selectCity(105);

      expect(cubit.state.selectedCityId, equals(105));
      expect(cubit.state.districts.length, equals(1));
      expect(cubit.state.districts.first.nameEn, equals('First District'));
    });

    test('changing city should clear district selection and district list', () async {
      await cubit.loadGovernorates();
      await cubit.selectGovernorate(1);
      await cubit.selectCity(105);
      cubit.selectDistrict(1051);

      expect(cubit.state.selectedDistrictId, equals(1051));

      await cubit.selectCity(null);

      expect(cubit.state.selectedCityId, isNull);
      expect(cubit.state.selectedDistrictId, isNull);
      expect(cubit.state.districts, isEmpty);
    });

    test('re-selecting same governorate or city should skip redundant duplicate loading', () async {
      int citiesFetchCount = 0;

      final countingRepo = CountingGeographicReferenceRepository(
        onFetchCities: () => citiesFetchCount++,
        governorates: sampleGovs,
        citiesMap: {1: cairoCities},
        districtsMap: {105: fifthSettlementDistricts},
      );

      final testCubit = GeographicReferenceCubit(
        getActiveGovernoratesUseCase: GetActiveGovernoratesUseCase(countingRepo),
        getActiveCitiesByGovernorateUseCase: GetActiveCitiesByGovernorateUseCase(countingRepo),
        getActiveDistrictsByCityUseCase: GetActiveDistrictsByCityUseCase(countingRepo),
      );

      await testCubit.selectGovernorate(1);
      expect(citiesFetchCount, equals(1));

      // Re-select same governorate when cities are already loaded
      await testCubit.selectGovernorate(1);
      expect(citiesFetchCount, equals(1)); // Skipped redundant fetch!

      testCubit.close();
    });

    test('UX state helpers (disabled, empty) work correctly', () async {
      expect(cubit.state.isCitiesDisabled, isTrue);
      expect(cubit.state.isDistrictsDisabled, isTrue);

      await cubit.loadGovernorates();
      await cubit.selectGovernorate(1);

      expect(cubit.state.isCitiesDisabled, isFalse);
      expect(cubit.state.isDistrictsDisabled, isTrue);

      await cubit.selectCity(105);

      expect(cubit.state.isDistrictsDisabled, isFalse);
      expect(cubit.state.isDistrictsEmpty, isFalse);
    });

    test('bilingual local district search filters districts by Arabic or English name case-insensitively', () async {
      await cubit.loadGovernorates();
      await cubit.selectGovernorate(1);
      await cubit.selectCity(105);

      expect(cubit.state.filteredDistricts.length, equals(1));

      // Search by English text
      cubit.searchDistricts('first');
      expect(cubit.state.filteredDistricts.length, equals(1));

      // Search by Arabic text
      cubit.searchDistricts('الأول');
      expect(cubit.state.filteredDistricts.length, equals(1));

      // Search with non-matching query
      cubit.searchDistricts('NonExistentDistrictQuery');
      expect(cubit.state.filteredDistricts, isEmpty);
    });

    test('restoreHierarchy should smoothly restore full existing address hierarchy for Editing Addresses', () async {
      await cubit.restoreHierarchy(
        governorateId: 1,
        cityId: 105,
        districtId: 1051,
      );

      expect(cubit.state.selectedGovernorateId, equals(1));
      expect(cubit.state.selectedCityId, equals(105));
      expect(cubit.state.selectedDistrictId, equals(1051));
      expect(cubit.state.governorates.isNotEmpty, isTrue);
      expect(cubit.state.cities.isNotEmpty, isTrue);
      expect(cubit.state.districts.isNotEmpty, isTrue);
    });
  });
}

class CountingGeographicReferenceRepository implements GeographicReferenceRepository {
  final void Function() onFetchCities;
  final List<Governorate> governorates;
  final Map<int, List<City>> citiesMap;
  final Map<int, List<District>> districtsMap;


  CountingGeographicReferenceRepository({
    required this.onFetchCities,
    required this.governorates,
    required this.citiesMap,
    required this.districtsMap,
  });

  @override
  Future<Either<Failure, List<Governorate>>> getGovernorates() async => Right(governorates);

  @override
  Future<Either<Failure, List<City>>> getCitiesByGovernorate(int governorateId) async {
    onFetchCities();
    return Right(citiesMap[governorateId] ?? []);
  }

  @override
  Future<Either<Failure, List<District>>> getDistrictsByCity(int cityId) async => Right(districtsMap[cityId] ?? []);
}

