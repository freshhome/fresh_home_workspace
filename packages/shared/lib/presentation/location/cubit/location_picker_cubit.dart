import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/presentation/location/cubit/location_picker_state.dart';

class LocationPickerCubit extends Cubit<LocationPickerState> {
  LocationPickerCubit({double? initialLatitude, double? initialLongitude})
      : super(LocationPickerState(
          latitude: initialLatitude,
          longitude: initialLongitude,
        ));

  // ─────────────────────────────────────────────────────────────────────────
  // Select Location
  // ─────────────────────────────────────────────────────────────────────────

  /// Selects location coordinates with domain range and pairing validation.
  Either<ValidationFailure, Unit> selectLocation({
    required double latitude,
    required double longitude,
  }) {
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

  // ─────────────────────────────────────────────────────────────────────────
  // Clear Location
  // ─────────────────────────────────────────────────────────────────────────

  /// Safely clears coordinates (sets both to null to prevent unpaired coordinates).
  void clearLocation() {
    emit(state.copyWith(clearCoordinates: true, clearError: true));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Request Current Location (Real GPS via geolocator)
  // ─────────────────────────────────────────────────────────────────────────

  /// Requests the device's real GPS current location.
  /// Falls back to a Cairo center point only if permission is permanently denied.
  Future<void> requestCurrentLocation({
    /// Optional mock provider — used only in unit tests.
    Future<Map<String, double>> Function()? mockLocationProvider,
  }) async {
    emit(state.copyWith(isLoadingLocation: true, clearError: true));

    try {
      // ── Test mock path ────────────────────────────────────────────────────
      if (mockLocationProvider != null) {
        final loc = await mockLocationProvider();
        selectLocation(
          latitude: loc['latitude']!,
          longitude: loc['longitude']!,
        );
        emit(state.copyWith(
          isLoadingLocation: false,
          permissionStatus: LocationPermissionStatus.granted,
        ));
        return;
      }

      // ── Real GPS path ─────────────────────────────────────────────────────

      // 1. Check if location services are enabled on the device.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(state.copyWith(
          isLoadingLocation: false,
          permissionStatus: LocationPermissionStatus.denied,
          errorMessage:
              'خدمة الموقع مُعطَّلة على جهازك. يمكنك تحديد موقعك يدويًا على الخريطة.',
        ));
        return;
      }

      // 2. Check / request runtime permission.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        emit(state.copyWith(
          isLoadingLocation: false,
          permissionStatus: LocationPermissionStatus.denied,
          errorMessage:
              'تم رفض إذن الموقع. يمكنك تحديد موقعك يدويًا على الخريطة.',
        ));
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        emit(state.copyWith(
          isLoadingLocation: false,
          permissionStatus: LocationPermissionStatus.manualOnly,
          errorMessage:
              'تم رفض إذن الموقع نهائيًا. يُرجى السماح به من إعدادات التطبيق.',
        ));
        return;
      }

      // 3. Fetch current position.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      selectLocation(
        latitude: double.parse(position.latitude.toStringAsFixed(6)),
        longitude: double.parse(position.longitude.toStringAsFixed(6)),
      );
      emit(state.copyWith(
        isLoadingLocation: false,
        permissionStatus: LocationPermissionStatus.granted,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingLocation: false,
        permissionStatus: LocationPermissionStatus.denied,
        errorMessage:
            'تعذّر تحديد موقعك تلقائيًا. يمكنك تحديد موقعك يدويًا على الخريطة.',
      ));
    }
  }
}
