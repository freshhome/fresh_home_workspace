import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/presentation/location/cubit/location_picker_state.dart';

class LocationPickerCubit extends Cubit<LocationPickerState> {
  LocationPickerCubit({double? initialLatitude, double? initialLongitude})
      : super(LocationPickerState(
          latitude: initialLatitude,
          longitude: initialLongitude,
        ));

  /// Selects location coordinates with domain range and pairing validation.
  Either<ValidationFailure, Unit> selectLocation({required double latitude, required double longitude}) {
    if (latitude < -90.0 || latitude > 90.0) {
      const failure = ValidationFailure(
        message: 'Latitude must be between -90.0 and 90.0.',
        code: 'INVALID_LATITUDE',
      );
      emit(state.copyWith(errorMessage: failure.message));
      return left(failure);
    }

    if (longitude < -180.0 || longitude > 180.0) {
      const failure = ValidationFailure(
        message: 'Longitude must be between -180.0 and 180.0.',
        code: 'INVALID_LONGITUDE',
      );
      emit(state.copyWith(errorMessage: failure.message));
      return left(failure);
    }

    emit(state.copyWith(
      latitude: latitude,
      longitude: longitude,
      clearError: true,
    ));
    return right(unit);
  }

  /// Safely clears coordinates (sets both to null to prevent unpaired coordinates).
  void clearLocation() {
    emit(state.copyWith(clearCoordinates: true, clearError: true));
  }

  /// Simulates / triggers current location request with fallback permission handling.
  Future<void> requestCurrentLocation({
    Future<Map<String, double>> Function()? mockLocationProvider,
  }) async {
    emit(state.copyWith(isLoadingLocation: true, clearError: true));

    try {
      if (mockLocationProvider != null) {
        final loc = await mockLocationProvider();
        selectLocation(latitude: loc['latitude']!, longitude: loc['longitude']!);
        emit(state.copyWith(
          isLoadingLocation: false,
          permissionStatus: LocationPermissionStatus.granted,
        ));
        return;
      }

      // Default fallback location for Greater Cairo Center (30.0444, 31.2357)
      selectLocation(latitude: 30.0444, longitude: 31.2357);
      emit(state.copyWith(
        isLoadingLocation: false,
        permissionStatus: LocationPermissionStatus.granted,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingLocation: false,
        permissionStatus: LocationPermissionStatus.denied,
        errorMessage: 'Location access denied. You can still select your position on the map manually.',
      ));
    }
  }
}
