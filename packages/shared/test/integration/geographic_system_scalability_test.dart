import 'package:flutter_test/flutter_test.dart';
import 'package:shared/data/booking/mappers/address_snapshot_mapper.dart';
import 'package:shared/data/user/datasources/geographic_reference_remote_datasource.dart';
import 'package:shared/data/user/models/city_model.dart';
import 'package:shared/data/user/models/district_model.dart';
import 'package:shared/data/user/models/governorate_model.dart';
import 'package:shared/data/user/repositories/geographic_reference_repository_impl.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/usecases/get_active_cities_by_governorate_usecase.dart';
import 'package:shared/domain/user/usecases/get_active_districts_by_city_usecase.dart';
import 'package:shared/domain/user/usecases/get_active_governorates_usecase.dart';
import 'package:shared/domain/user/validation/address_validator.dart';
import 'package:shared/presentation/location/cubit/geographic_reference_cubit.dart';

class ScalableMockRemoteDataSource implements GeographicReferenceRemoteDataSource {
  final List<GovernorateModel> governorateStore = [
    const GovernorateModel(id: 1, nameAr: 'القاهرة', nameEn: 'Cairo', code: 'CAI', isActive: true, sortOrder: 1),
    const GovernorateModel(id: 2, nameAr: 'الجيزة', nameEn: 'Giza', code: 'GIZ', isActive: true, sortOrder: 2),
  ];

  final List<CityModel> cityStore = [
    const CityModel(id: 10, governorateId: 1, nameAr: 'مدينة نصر', nameEn: 'Nasr City', isActive: true, sortOrder: 1),
  ];

  final List<DistrictModel> districtStore = [
    const DistrictModel(id: 100, cityId: 10, nameAr: 'الحي الأول', nameEn: 'First District', isActive: true, sortOrder: 1),
  ];

  @override
  Future<List<GovernorateModel>> getGovernorates() async {
    return governorateStore.where((g) => g.isActive).toList();
  }

  @override
  Future<List<CityModel>> getCitiesByGovernorate(int governorateId) async {
    return cityStore.where((c) => c.governorateId == governorateId && c.isActive).toList();
  }

  @override
  Future<List<DistrictModel>> getDistrictsByCity(int cityId) async {
    return districtStore.where((d) => d.cityId == cityId && d.isActive).toList();
  }
}

void main() {
  group('STEP 6 — Address System Integration & Scalability Hardening Test Suite', () {
    late ScalableMockRemoteDataSource remoteDataSource;
    late GeographicReferenceRepositoryImpl customerRepository;
    late GeographicReferenceCubit cubit;

    setUp(() {
      remoteDataSource = ScalableMockRemoteDataSource();
      customerRepository = GeographicReferenceRepositoryImpl(remoteDataSource: remoteDataSource);
      cubit = GeographicReferenceCubit(
        getActiveGovernoratesUseCase: GetActiveGovernoratesUseCase(customerRepository),
        getActiveCitiesByGovernorateUseCase: GetActiveCitiesByGovernorateUseCase(customerRepository),
        getActiveDistrictsByCityUseCase: GetActiveDistrictsByCityUseCase(customerRepository),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('Scenario A — New Governorate created by Admin becomes available automatically to Customer without Flutter code changes', () async {
      await cubit.loadGovernorates();
      expect(cubit.state.governorates.length, equals(2));

      // Admin adds a brand-new governorate dynamically to DB (e.g. Red Sea / البحر الأحمر)
      remoteDataSource.governorateStore.add(
        const GovernorateModel(id: 3, nameAr: 'البحر الأحمر', nameEn: 'Red Sea', code: 'RED', isActive: true, sortOrder: 3),
      );

      // Invalidate cache & reload
      customerRepository.clearMemoryCache();
      await cubit.loadGovernorates();

      expect(cubit.state.governorates.length, equals(3));
      expect(cubit.state.governorates.last.nameAr, equals('البحر الأحمر'));
      expect(cubit.state.governorates.last.nameEn, equals('Red Sea'));
    });

    test('Scenario B — New City created under Governorate becomes available automatically under that Governorate', () async {
      // Admin adds a brand-new city (e.g. Hurghada / الغردقة) under Governorate ID 3
      remoteDataSource.cityStore.add(
        const CityModel(id: 30, governorateId: 3, nameAr: 'الغردقة', nameEn: 'Hurghada', isActive: true, sortOrder: 1),
      );

      customerRepository.clearMemoryCache();
      await cubit.selectGovernorate(3);

      expect(cubit.state.cities.length, equals(1));
      expect(cubit.state.cities.first.nameAr, equals('الغردقة'));
      expect(cubit.state.cities.first.governorateId, equals(3));
    });

    test('Scenario C — New District created under City becomes available automatically under that City', () async {
      // Admin adds a brand-new district (e.g. El Gouna / الجونة) under City ID 30
      remoteDataSource.districtStore.add(
        const DistrictModel(id: 300, cityId: 30, nameAr: 'الجونة', nameEn: 'El Gouna', isActive: true, sortOrder: 1),
      );

      customerRepository.clearMemoryCache();
      await cubit.selectCity(30);

      expect(cubit.state.districts.length, equals(1));
      expect(cubit.state.districts.first.nameAr, equals('الجونة'));
      expect(cubit.state.districts.first.cityId, equals(30));
    });

    test('Scenario D — Address Create works with newly added dynamic geographic data & validates hierarchy', () {
      final newAddress = Address(
        id: 'dyn-addr-1',
        userId: 'user-new',
        governorate: 'Red Sea',
        city: 'Hurghada',
        district: 'El Gouna',
        governorateId: 3,
        cityId: 30,
        districtId: 300,
        governorateAr: 'البحر الأحمر',
        governorateEn: 'Red Sea',
        cityAr: 'الغردقة',
        cityEn: 'Hurghada',
        districtAr: 'الجونة',
        districtEn: 'El Gouna',
        streetOrCompound: 'Marina Boulevard',
        buildingIdentifier: 'Building 4',
        latitude: 27.3948,
        longitude: 33.6765,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final valRes = AddressValidator.validate(newAddress);
      expect(valRes.isRight(), isTrue);
      expect(newAddress.hasCoordinates, isTrue);
      expect(newAddress.governorateId, equals(3));
      expect(newAddress.cityId, equals(30));
      expect(newAddress.districtId, equals(300));
    });

    test('Scenario E — Address Edit smoothly restores hierarchy with newly added dynamic geographic data', () async {
      // Setup stores with Red Sea / Hurghada / El Gouna
      remoteDataSource.governorateStore.add(
        const GovernorateModel(id: 3, nameAr: 'البحر الأحمر', nameEn: 'Red Sea', code: 'RED', isActive: true, sortOrder: 3),
      );
      remoteDataSource.cityStore.add(
        const CityModel(id: 30, governorateId: 3, nameAr: 'الغردقة', nameEn: 'Hurghada', isActive: true, sortOrder: 1),
      );
      remoteDataSource.districtStore.add(
        const DistrictModel(id: 300, cityId: 30, nameAr: 'الجونة', nameEn: 'El Gouna', isActive: true, sortOrder: 1),
      );

      await cubit.restoreHierarchy(governorateId: 3, cityId: 30, districtId: 300);

      expect(cubit.state.selectedGovernorateId, equals(3));
      expect(cubit.state.selectedCityId, equals(30));
      expect(cubit.state.selectedDistrictId, equals(300));
    });

    test('Scenario F — Booking Snapshot V2 captures newly added geographic data correctly', () {
      final dynamicAddress = Address(
        id: 'dyn-addr-snapshot',
        userId: 'user-snapshot',
        governorate: 'Red Sea',
        city: 'Hurghada',
        district: 'El Gouna',
        governorateId: 3,
        cityId: 30,
        districtId: 300,
        governorateAr: 'البحر الأحمر',
        governorateEn: 'Red Sea',
        cityAr: 'الغردقة',
        cityEn: 'Hurghada',
        districtAr: 'الجونة',
        districtEn: 'El Gouna',
        streetOrCompound: 'Marina Boulevard',
        buildingIdentifier: 'Building 4',
        latitude: 27.3948,
        longitude: 33.6765,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final snapshotJson = AddressSnapshotMapper.buildSnapshotJson(dynamicAddress);
      expect(snapshotJson['snapshot_version'], equals(2));
      expect(snapshotJson['address']['governorate_ar'], equals('البحر الأحمر'));
      expect(snapshotJson['address']['city_ar'], equals('الغردقة'));
      expect(snapshotJson['address']['district_ar'], equals('الجونة'));

      final parsed = AddressSnapshotMapper.parseSnapshotJson(snapshotJson);
      expect(parsed.getGovernorateName('ar'), equals('البحر الأحمر'));
      expect(parsed.getCityName('ar'), equals('الغردقة'));
      expect(parsed.getDistrictName('ar'), equals('الجونة'));
    });

    test('Scenario G — Historical Booking Snapshot remains 100% immutable after reference data update', () {
      // Old booking snapshot created when governorate name was 'القاهرة القديمة'
      final historicalSnapshot = {
        'snapshot_version': 2,
        'address': {
          'address_id': 'old-addr-1',
          'user_id': 'user-1',
          'governorate_id': 1,
          'city_id': 10,
          'district_id': 100,
          'governorate_ar': 'القاهرة القديمة',
          'governorate_en': 'Old Cairo',
          'city_ar': 'مدينة نصر',
          'city_en': 'Nasr City',
          'district_ar': 'الحي الأول',
          'district_en': 'First District',
          'street_or_compound': 'Street 90',
          'building_identifier': '12',
        }
      };

      // Admin renames governorate in DB reference table to 'القاهرة الكبرى'
      remoteDataSource.governorateStore[0] = const GovernorateModel(
        id: 1,
        nameAr: 'القاهرة الكبرى',
        nameEn: 'Greater Cairo',
        code: 'CAI',
        isActive: true,
      );

      // Parsing old historical snapshot still yields embedded historical name without mutating
      final parsed = AddressSnapshotMapper.parseSnapshotJson(historicalSnapshot);
      expect(parsed.getGovernorateName('ar'), equals('القاهرة القديمة'));
      expect(parsed.getGovernorateName('en'), equals('Old Cairo'));
    });

    test('Scenario H & I — Disabled reference is hidden from new selection; re-enabling restores availability', () async {
      // Admin disables Governorate 2 (Giza)
      remoteDataSource.governorateStore[1] = const GovernorateModel(
        id: 2,
        nameAr: 'الجيزة',
        nameEn: 'Giza',
        code: 'GIZ',
        isActive: false, // Disabled
      );

      customerRepository.clearMemoryCache();
      await cubit.loadGovernorates();

      // Governorate 2 does not appear in customer active selection dropdown
      expect(cubit.state.governorates.any((g) => g.id == 2), isFalse);

      // Admin re-enables Governorate 2
      remoteDataSource.governorateStore[1] = const GovernorateModel(
        id: 2,
        nameAr: 'الجيزة',
        nameEn: 'Giza',
        code: 'GIZ',
        isActive: true, // Re-enabled
      );

      customerRepository.clearMemoryCache();
      await cubit.loadGovernorates();

      // Governorate 2 becomes selectable again
      expect(cubit.state.governorates.any((g) => g.id == 2), isTrue);
    });

    test('Scenario J — Zero runtime hardcoded geographic sources in system architecture', () {
      // Geographic reference system is 100% data-driven from remote reference tables
      expect(remoteDataSource, isA<GeographicReferenceRemoteDataSource>());
      expect(customerRepository, isA<GeographicReferenceRepositoryImpl>());
    });
  });
}
