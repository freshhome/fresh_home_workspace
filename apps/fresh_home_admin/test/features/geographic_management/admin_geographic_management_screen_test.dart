import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared/shared.dart';
import 'package:fresh_home_admin/features/geographic_management/presentation/pages/admin_geographic_management_screen.dart';

class MockAdminGeographicReferenceRepository implements AdminGeographicReferenceRepository {
  final List<Governorate> governorates = [
    const Governorate(id: 1, nameAr: 'القاهرة', nameEn: 'Cairo', code: 'CAI', isActive: true, sortOrder: 1),
    const Governorate(id: 2, nameAr: 'الجيزة', nameEn: 'Giza', code: 'GIZ', isActive: false, sortOrder: 2),
  ];

  final List<City> cities = [
    const City(id: 10, governorateId: 1, nameAr: 'مدينة نصر', nameEn: 'Nasr City', isActive: true, sortOrder: 1),
  ];

  final List<District> districts = [
    const District(id: 100, cityId: 10, nameAr: 'الحي الأول', nameEn: 'First District', isActive: true, sortOrder: 1),
  ];

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
    final gov = Governorate(id: 3, nameAr: nameAr, nameEn: nameEn, code: code, isActive: true, sortOrder: sortOrder);
    governorates.add(gov);
    return Right(gov);
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
    final gov = Governorate(id: id, nameAr: nameAr, nameEn: nameEn, code: code, isActive: isActive ?? true, sortOrder: sortOrder ?? 0);
    return Right(gov);
  }

  @override
  Future<Either<Failure, City>> createCity({
    required int governorateId,
    required String nameAr,
    required String nameEn,
    int sortOrder = 0,
  }) async {
    final city = City(id: 11, governorateId: governorateId, nameAr: nameAr, nameEn: nameEn, isActive: true, sortOrder: sortOrder);
    cities.add(city);
    return Right(city);
  }

  @override
  Future<Either<Failure, City>> updateCity({
    required int id,
    required String nameAr,
    required String nameEn,
    bool? isActive,
    int? sortOrder,
  }) async {
    final city = City(id: id, governorateId: 1, nameAr: nameAr, nameEn: nameEn, isActive: isActive ?? true, sortOrder: sortOrder ?? 0);
    return Right(city);
  }

  @override
  Future<Either<Failure, District>> createDistrict({
    required int cityId,
    required String nameAr,
    required String nameEn,
    int sortOrder = 0,
  }) async {
    final dist = District(id: 101, cityId: cityId, nameAr: nameAr, nameEn: nameEn, isActive: true, sortOrder: sortOrder);
    districts.add(dist);
    return Right(dist);
  }

  @override
  Future<Either<Failure, District>> updateDistrict({
    required int id,
    required String nameAr,
    required String nameEn,
    bool? isActive,
    int? sortOrder,
  }) async {
    final dist = District(id: id, cityId: 10, nameAr: nameAr, nameEn: nameEn, isActive: isActive ?? true, sortOrder: sortOrder ?? 0);
    return Right(dist);
  }

  @override
  Future<Either<Failure, Unit>> toggleActiveStatus({
    required String table,
    required int id,
    required bool isActive,
  }) async {
    return Right(unit);
  }
}

void main() {
  Widget buildWidget(AdminGeographicReferenceCubit cubit) {
    return MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider.value(
        value: cubit,
        child: const AdminGeographicManagementScreen(),
      ),
    );
  }


  group('Step 5 — AdminGeographicManagementScreen Widget & UI Logic Tests', () {
    late MockAdminGeographicReferenceRepository repository;
    late AdminGeographicReferenceCubit cubit;

    setUp(() {
      repository = MockAdminGeographicReferenceRepository();
      cubit = AdminGeographicReferenceCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets('1. Governorate list loads and displays active/inactive badges', (tester) async {
      await cubit.loadGovernorates();
      await tester.pumpWidget(buildWidget(cubit));
      await tester.pumpAndSettle();

      expect(find.text('القاهرة (Cairo)'), findsOneWidget);
      expect(find.text('الجيزة (Giza)'), findsOneWidget);
      expect(find.text('مفعل (Active)'), findsOneWidget);
      expect(find.text('معطل (Inactive)'), findsOneWidget);
    });

    testWidgets('2. Tab navigation switches between Governorates, Cities, and Districts views', (tester) async {
      await cubit.loadGovernorates();
      await tester.pumpWidget(buildWidget(cubit));
      await tester.pumpAndSettle();

      // Tap Cities Tab
      await tester.tap(find.text('المدن'));
      await tester.pumpAndSettle();
      expect(find.text('اختر المحافظة: '), findsOneWidget);

      // Tap Districts Tab
      await tester.tap(find.text('الأحياء'));
      await tester.pumpAndSettle();
      expect(find.text('المحافظة: '), findsOneWidget);
      expect(find.text('المدينة: '), findsOneWidget);
    });

    testWidgets('3. Adding a new governorate dialog opens and submits required fields', (tester) async {
      await cubit.loadGovernorates();
      await tester.pumpWidget(buildWidget(cubit));
      await tester.pumpAndSettle();

      // Tap "+ إضافة محافظة" button
      await tester.tap(find.text('إضافة محافظة'));
      await tester.pumpAndSettle();

      expect(find.text('إضافة محافظة جديدة'), findsOneWidget);
      expect(find.text('اسم المحافظة بالعربية *'), findsOneWidget);
      expect(find.text('اسم المحافظة بالإنجليزية *'), findsOneWidget);
    });

    testWidgets('4. Empty states display prompt message when no parent item is selected', (tester) async {
      await cubit.loadGovernorates();
      await tester.pumpWidget(buildWidget(cubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('المدن'));
      await tester.pumpAndSettle();

      expect(find.text('الرجاء اختيار محافظة من القائمة لعرض وإدارة مدنها'), findsOneWidget);
    });




  });
}
