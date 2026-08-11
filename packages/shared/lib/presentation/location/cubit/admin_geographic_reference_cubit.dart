import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/user/repositories/admin_geographic_reference_repository.dart';
import 'admin_geographic_reference_state.dart';

class AdminGeographicReferenceCubit extends Cubit<AdminGeographicReferenceState> {
  final AdminGeographicReferenceRepository repository;

  AdminGeographicReferenceCubit({required this.repository})
      : super(const AdminGeographicReferenceState());

  /// Admin: Loads all governorates.
  Future<void> loadGovernorates({bool keepSuccessMessage = false}) async {
    emit(state.copyWith(
      isLoading: true,
      clearFailure: true,
      clearSuccess: !keepSuccessMessage,
    ));
    final result = await repository.getAllGovernorates();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (governorates) => emit(state.copyWith(isLoading: false, governorates: governorates)),
    );
  }


  /// Admin: Loads all cities for a governorate.
  Future<void> loadCities(int governorateId) async {
    emit(state.copyWith(
      isLoading: true,
      selectedGovernorateId: governorateId,
      clearFailure: true,
      clearSuccess: true,
    ));
    final result = await repository.getAllCitiesByGovernorate(governorateId);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (cities) => emit(state.copyWith(isLoading: false, cities: cities)),
    );
  }

  /// Admin: Loads all districts for a city.
  Future<void> loadDistricts(int cityId) async {
    emit(state.copyWith(
      isLoading: true,
      selectedCityId: cityId,
      clearFailure: true,
      clearSuccess: true,
    ));
    final result = await repository.getAllDistrictsByCity(cityId);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (districts) => emit(state.copyWith(isLoading: false, districts: districts)),
    );
  }

  /// Admin: Creates a new governorate.
  Future<void> createGovernorate({
    required String nameAr,
    required String nameEn,
    required String code,
    int sortOrder = 0,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearFailure: true, clearSuccess: true));
    final result = await repository.createGovernorate(
      nameAr: nameAr,
      nameEn: nameEn,
      code: code,
      sortOrder: sortOrder,
    );
    result.fold(
      (failure) => emit(state.copyWith(isSubmitting: false, failure: failure)),
      (newGov) async {
        emit(state.copyWith(
          isSubmitting: false,
          successMessage: 'Governorate created successfully.',
        ));
        await loadGovernorates(keepSuccessMessage: true);
      },

    );
  }

  /// Admin: Updates an existing governorate.
  Future<void> updateGovernorate({
    required int id,
    required String nameAr,
    required String nameEn,
    required String code,
    bool? isActive,
    int? sortOrder,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearFailure: true, clearSuccess: true));
    final result = await repository.updateGovernorate(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      code: code,
      isActive: isActive,
      sortOrder: sortOrder,
    );
    result.fold(
      (failure) => emit(state.copyWith(isSubmitting: false, failure: failure)),
      (updatedGov) async {
        await loadGovernorates();
        emit(state.copyWith(
          isSubmitting: false,
          successMessage: 'Governorate updated successfully.',
        ));
      },
    );
  }

  /// Admin: Creates a new city under a governorate.
  Future<void> createCity({
    required int governorateId,
    required String nameAr,
    required String nameEn,
    int sortOrder = 0,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearFailure: true, clearSuccess: true));
    final result = await repository.createCity(
      governorateId: governorateId,
      nameAr: nameAr,
      nameEn: nameEn,
      sortOrder: sortOrder,
    );
    result.fold(
      (failure) => emit(state.copyWith(isSubmitting: false, failure: failure)),
      (newCity) async {
        await loadCities(governorateId);
        emit(state.copyWith(
          isSubmitting: false,
          successMessage: 'City created successfully.',
        ));
      },
    );
  }

  /// Admin: Updates an existing city.
  Future<void> updateCity({
    required int id,
    required String nameAr,
    required String nameEn,
    bool? isActive,
    int? sortOrder,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearFailure: true, clearSuccess: true));
    final result = await repository.updateCity(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      isActive: isActive,
      sortOrder: sortOrder,
    );
    result.fold(
      (failure) => emit(state.copyWith(isSubmitting: false, failure: failure)),
      (updatedCity) async {
        if (state.selectedGovernorateId != null) {
          await loadCities(state.selectedGovernorateId!);
        }
        emit(state.copyWith(
          isSubmitting: false,
          successMessage: 'City updated successfully.',
        ));
      },
    );
  }

  /// Admin: Creates a new district under a city.
  Future<void> createDistrict({
    required int cityId,
    required String nameAr,
    required String nameEn,
    int sortOrder = 0,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearFailure: true, clearSuccess: true));
    final result = await repository.createDistrict(
      cityId: cityId,
      nameAr: nameAr,
      nameEn: nameEn,
      sortOrder: sortOrder,
    );
    result.fold(
      (failure) => emit(state.copyWith(isSubmitting: false, failure: failure)),
      (newDistrict) async {
        await loadDistricts(cityId);
        emit(state.copyWith(
          isSubmitting: false,
          successMessage: 'District created successfully.',
        ));
      },
    );
  }

  /// Admin: Updates an existing district.
  Future<void> updateDistrict({
    required int id,
    required String nameAr,
    required String nameEn,
    bool? isActive,
    int? sortOrder,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearFailure: true, clearSuccess: true));
    final result = await repository.updateDistrict(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      isActive: isActive,
      sortOrder: sortOrder,
    );
    result.fold(
      (failure) => emit(state.copyWith(isSubmitting: false, failure: failure)),
      (updatedDistrict) async {
        if (state.selectedCityId != null) {
          await loadDistricts(state.selectedCityId!);
        }
        emit(state.copyWith(
          isSubmitting: false,
          successMessage: 'District updated successfully.',
        ));
      },
    );
  }

  /// Admin: Soft toggles enable/disable status for a reference record without hard deletion.
  Future<void> toggleActiveStatus({
    required String table,
    required int id,
    required bool isActive,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearFailure: true, clearSuccess: true));
    final result = await repository.toggleActiveStatus(
      table: table,
      id: id,
      isActive: isActive,
    );
    result.fold(
      (failure) => emit(state.copyWith(isSubmitting: false, failure: failure)),
      (_) async {
        if (table == 'governorates') await loadGovernorates();
        if (table == 'cities' && state.selectedGovernorateId != null) await loadCities(state.selectedGovernorateId!);
        if (table == 'districts' && state.selectedCityId != null) await loadDistricts(state.selectedCityId!);

        emit(state.copyWith(
          isSubmitting: false,
          successMessage: 'Status toggled successfully.',
        ));
      },
    );
  }
}
