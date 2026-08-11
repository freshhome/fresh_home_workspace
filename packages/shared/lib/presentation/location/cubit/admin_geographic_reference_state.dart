import 'package:equatable/equatable.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/city.dart';
import 'package:shared/domain/user/entities/user/district.dart';
import 'package:shared/domain/user/entities/user/governorate.dart';

class AdminGeographicReferenceState extends Equatable {
  final List<Governorate> governorates;
  final List<City> cities;
  final List<District> districts;

  final int? selectedGovernorateId;
  final int? selectedCityId;

  final bool isLoading;
  final bool isSubmitting;

  final Failure? failure;
  final String? successMessage;

  const AdminGeographicReferenceState({
    this.governorates = const [],
    this.cities = const [],
    this.districts = const [],
    this.selectedGovernorateId,
    this.selectedCityId,
    this.isLoading = false,
    this.isSubmitting = false,
    this.failure,
    this.successMessage,
  });

  AdminGeographicReferenceState copyWith({
    List<Governorate>? governorates,
    List<City>? cities,
    List<District>? districts,
    int? selectedGovernorateId,
    int? selectedCityId,
    bool? isLoading,
    bool? isSubmitting,
    Failure? failure,
    String? successMessage,
    bool clearFailure = false,
    bool clearSuccess = false,
  }) {
    return AdminGeographicReferenceState(
      governorates: governorates ?? this.governorates,
      cities: cities ?? this.cities,
      districts: districts ?? this.districts,
      selectedGovernorateId: selectedGovernorateId ?? this.selectedGovernorateId,
      selectedCityId: selectedCityId ?? this.selectedCityId,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure ? null : (failure ?? this.failure),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        governorates,
        cities,
        districts,
        selectedGovernorateId,
        selectedCityId,
        isLoading,
        isSubmitting,
        failure,
        successMessage,
      ];
}
