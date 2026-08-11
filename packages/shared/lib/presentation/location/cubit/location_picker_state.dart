import 'package:equatable/equatable.dart';

enum LocationPermissionStatus { unknown, granted, denied, restricted, manualOnly }

class LocationPickerState extends Equatable {
  final double? latitude;
  final double? longitude;
  final bool isLoadingLocation;
  final LocationPermissionStatus permissionStatus;
  final String? errorMessage;

  const LocationPickerState({
    this.latitude,
    this.longitude,
    this.isLoadingLocation = false,
    this.permissionStatus = LocationPermissionStatus.unknown,
    this.errorMessage,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  LocationPickerState copyWith({
    double? latitude,
    double? longitude,
    bool? isLoadingLocation,
    LocationPermissionStatus? permissionStatus,
    String? errorMessage,
    bool clearCoordinates = false,
    bool clearError = false,
  }) {
    return LocationPickerState(
      latitude: clearCoordinates ? null : (latitude ?? this.latitude),
      longitude: clearCoordinates ? null : (longitude ?? this.longitude),
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, isLoadingLocation, permissionStatus, errorMessage];
}
