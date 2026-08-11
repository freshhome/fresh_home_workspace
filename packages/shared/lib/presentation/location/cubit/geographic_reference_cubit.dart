import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/user/usecases/get_active_cities_by_governorate_usecase.dart';
import 'package:shared/domain/user/usecases/get_active_districts_by_city_usecase.dart';
import 'package:shared/domain/user/usecases/get_active_governorates_usecase.dart';
import 'package:shared/presentation/location/cubit/geographic_reference_state.dart';

/// Cubit managing cascading geographic reference data selections with race-condition protection.
class GeographicReferenceCubit extends Cubit<GeographicReferenceState> {
  final GetActiveGovernoratesUseCase getActiveGovernoratesUseCase;
  final GetActiveCitiesByGovernorateUseCase getActiveCitiesByGovernorateUseCase;
  final GetActiveDistrictsByCityUseCase getActiveDistrictsByCityUseCase;

  // Race condition sequence tokens
  int _governorateRequestToken = 0;
  int _cityRequestToken = 0;
  int _districtRequestToken = 0;

  GeographicReferenceCubit({
    required this.getActiveGovernoratesUseCase,
    required this.getActiveCitiesByGovernorateUseCase,
    required this.getActiveDistrictsByCityUseCase,
  }) : super(const GeographicReferenceState());

  /// Loads all active governorates.
  Future<void> loadGovernorates() async {
    final token = ++_governorateRequestToken;
    emit(state.copyWith(isLoadingGovernorates: true, clearFailure: true));

    final result = await getActiveGovernoratesUseCase();

    if (token != _governorateRequestToken) return;

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingGovernorates: false,
        failure: failure,
      )),
      (governorates) => emit(state.copyWith(
        isLoadingGovernorates: false,
        governorates: governorates,
      )),
    );
  }

  /// Selects a governorate and handles cascading reset of dependent cities & districts.
  Future<void> selectGovernorate(int? governorateId) async {
    if (governorateId == state.selectedGovernorateId && state.cities.isNotEmpty) {
      return;
    }

    // Cascading reset: clear cities & districts state
    final cityToken = ++_cityRequestToken;
    _districtRequestToken++;

    if (governorateId == null) {
      emit(state.copyWith(
        clearSelectedGovernorate: true,
        clearSelectedCity: true,
        clearSelectedDistrict: true,
        cities: const [],
        districts: const [],
      ));
      return;
    }

    emit(state.copyWith(
      selectedGovernorateId: governorateId,
      clearSelectedCity: true,
      clearSelectedDistrict: true,
      cities: const [],
      districts: const [],
      isLoadingCities: true,
      clearFailure: true,
    ));

    final result = await getActiveCitiesByGovernorateUseCase(governorateId);

    if (cityToken != _cityRequestToken) return;

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingCities: false,
        failure: failure,
      )),
      (cities) => emit(state.copyWith(
        isLoadingCities: false,
        cities: cities,
      )),
    );
  }

  /// Selects a city and handles cascading reset of dependent districts.
  Future<void> selectCity(int? cityId) async {
    if (cityId == state.selectedCityId && state.districts.isNotEmpty) {
      return;
    }

    // Cascading reset: clear districts state
    final districtToken = ++_districtRequestToken;

    if (cityId == null) {
      emit(state.copyWith(
        clearSelectedCity: true,
        clearSelectedDistrict: true,
        districts: const [],
      ));
      return;
    }

    emit(state.copyWith(
      selectedCityId: cityId,
      clearSelectedDistrict: true,
      districts: const [],
      isLoadingDistricts: true,
      clearFailure: true,
    ));

    final result = await getActiveDistrictsByCityUseCase(cityId);

    if (districtToken != _districtRequestToken) return;

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingDistricts: false,
        failure: failure,
      )),
      (districts) => emit(state.copyWith(
        isLoadingDistricts: false,
        districts: districts,
      )),
    );
  }

  /// Selects a district.
  void selectDistrict(int? districtId) {
    if (districtId == null) {
      emit(state.copyWith(clearSelectedDistrict: true));
    } else {
      emit(state.copyWith(selectedDistrictId: districtId));
    }
  }

  /// Sets the local search filter query for districts.
  void searchDistricts(String query) {
    emit(state.copyWith(districtSearchQuery: query));
  }

  /// Smoothly restores existing address hierarchy (for Editing Existing Addresses).
  Future<void> restoreHierarchy({
    required int governorateId,
    required int cityId,
    int? districtId,
  }) async {
    if (state.governorates.isEmpty) {
      await loadGovernorates();
    }
    await selectGovernorate(governorateId);
    await selectCity(cityId);
    if (districtId != null) {
      selectDistrict(districtId);
    }
  }

  /// Resets all geographic selections to initial blank state.
  void reset() {
    _governorateRequestToken++;
    _cityRequestToken++;
    _districtRequestToken++;
    emit(const GeographicReferenceState());
  }
}

