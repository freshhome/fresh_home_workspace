import 'package:equatable/equatable.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/city.dart';
import 'package:shared/domain/user/entities/user/district.dart';
import 'package:shared/domain/user/entities/user/governorate.dart';

/// Unified State for Geographic Reference Cascading Selection.
class GeographicReferenceState extends Equatable {
  final List<Governorate> governorates;
  final List<City> cities;
  final List<District> districts;

  final int? selectedGovernorateId;
  final int? selectedCityId;
  final int? selectedDistrictId;

  final bool isLoadingGovernorates;
  final bool isLoadingCities;
  final bool isLoadingDistricts;

  final Failure? failure;

  final String districtSearchQuery;

  const GeographicReferenceState({
    this.governorates = const [],
    this.cities = const [],
    this.districts = const [],
    this.selectedGovernorateId,
    this.selectedCityId,
    this.selectedDistrictId,
    this.isLoadingGovernorates = false,
    this.isLoadingCities = false,
    this.isLoadingDistricts = false,
    this.districtSearchQuery = '',
    this.failure,
  });

  /// Selected Governorate entity if available in list.
  Governorate? get selectedGovernorate {
    if (selectedGovernorateId == null) return null;
    try {
      return governorates.firstWhere((g) => g.id == selectedGovernorateId);
    } catch (_) {
      return null;
    }
  }

  /// Selected City entity if available in list.
  City? get selectedCity {
    if (selectedCityId == null) return null;
    try {
      return cities.firstWhere((c) => c.id == selectedCityId);
    } catch (_) {
      return null;
    }
  }

  /// Selected District entity if available in list.
  District? get selectedDistrict {
    if (selectedDistrictId == null) return null;
    try {
      return districts.firstWhere((d) => d.id == selectedDistrictId);
    } catch (_) {
      return null;
    }
  }

  /// Bilingual local search filter for districts (Arabic and English case-insensitive).
  List<District> get filteredDistricts {
    if (districtSearchQuery.trim().isEmpty) return districts;
    final query = districtSearchQuery.trim().toLowerCase();
    return districts.where((d) =>
      d.nameAr.toLowerCase().contains(query) ||
      d.nameEn.toLowerCase().contains(query)
    ).toList();
  }

  // UX State helpers
  bool get isCitiesDisabled => selectedGovernorateId == null;
  bool get isDistrictsDisabled => selectedCityId == null;
  bool get isCitiesEmpty => !isLoadingCities && selectedGovernorateId != null && cities.isEmpty;
  bool get isDistrictsEmpty => !isLoadingDistricts && selectedCityId != null && districts.isEmpty;

  GeographicReferenceState copyWith({
    List<Governorate>? governorates,
    List<City>? cities,
    List<District>? districts,
    int? selectedGovernorateId,
    int? selectedCityId,
    int? selectedDistrictId,
    bool? isLoadingGovernorates,
    bool? isLoadingCities,
    bool? isLoadingDistricts,
    String? districtSearchQuery,
    Failure? failure,
    bool clearSelectedGovernorate = false,
    bool clearSelectedCity = false,
    bool clearSelectedDistrict = false,
    bool clearFailure = false,
  }) {
    return GeographicReferenceState(
      governorates: governorates ?? this.governorates,
      cities: cities ?? this.cities,
      districts: districts ?? this.districts,
      selectedGovernorateId: clearSelectedGovernorate
          ? null
          : (selectedGovernorateId ?? this.selectedGovernorateId),
      selectedCityId: clearSelectedCity
          ? null
          : (selectedCityId ?? this.selectedCityId),
      selectedDistrictId: clearSelectedDistrict
          ? null
          : (selectedDistrictId ?? this.selectedDistrictId),
      isLoadingGovernorates: isLoadingGovernorates ?? this.isLoadingGovernorates,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      isLoadingDistricts: isLoadingDistricts ?? this.isLoadingDistricts,
      districtSearchQuery: districtSearchQuery ?? this.districtSearchQuery,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
        governorates,
        cities,
        districts,
        selectedGovernorateId,
        selectedCityId,
        selectedDistrictId,
        isLoadingGovernorates,
        isLoadingCities,
        isLoadingDistricts,
        districtSearchQuery,
        failure,
      ];

}
