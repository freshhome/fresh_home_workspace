import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Represents an in-progress booking draft saved locally by the admin/user.
class BookingDraft extends Equatable {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int currentStepIndex;

  // Client identification
  final String? clientName;
  final String? clientPhone;

  // Service overview
  final String? serviceName;
  final Map<String, String>? serviceTitle;
  final String? subServiceId;
  final String? serviceImage;

  // Pricing & Inputs
  final double? priceTotal;
  final double? area;
  final double? totalLinearMeters;
  final bool useWindowsCalculator;
  final List<Map<String, dynamic>> windows;
  final List<String> selectedOptions;
  final Map<String, dynamic> dynamicInputs;
  final bool isPriceCalculated;
  final Map<String, dynamic>? servicePriceData;

  // Schedule
  final DateTime? scheduledAt;

  // Client Address & Location Details (Admin)
  final String? manualClientGovernorate;
  final String? manualClientCity;
  final String? manualClientDistrict;
  /// V3: Single free-text field replacing street, building, floor, apartment, landmark.
  final String? manualClientAddressDetails;
  final String? manualClientLocationUrl;
  final double? manualClientLatitude;
  final double? manualClientLongitude;

  const BookingDraft({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.currentStepIndex = 0,
    this.clientName,
    this.clientPhone,
    this.serviceName,
    this.serviceTitle,
    this.subServiceId,
    this.serviceImage,
    this.priceTotal,
    this.area,
    this.totalLinearMeters,
    this.useWindowsCalculator = true,
    this.windows = const [],
    this.selectedOptions = const [],
    this.dynamicInputs = const {},
    this.isPriceCalculated = false,
    this.servicePriceData,
    this.scheduledAt,
    this.manualClientGovernorate,
    this.manualClientCity,
    this.manualClientDistrict,
    this.manualClientAddressDetails,
    this.manualClientLocationUrl,
    this.manualClientLatitude,
    this.manualClientLongitude,
  });

  BookingDraft copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? currentStepIndex,
    String? clientName,
    String? clientPhone,
    String? serviceName,
    Map<String, String>? serviceTitle,
    String? subServiceId,
    String? serviceImage,
    double? priceTotal,
    double? area,
    double? totalLinearMeters,
    bool? useWindowsCalculator,
    List<Map<String, dynamic>>? windows,
    List<String>? selectedOptions,
    Map<String, dynamic>? dynamicInputs,
    bool? isPriceCalculated,
    Map<String, dynamic>? servicePriceData,
    DateTime? scheduledAt,
    String? manualClientGovernorate,
    String? manualClientCity,
    String? manualClientDistrict,
    String? manualClientAddressDetails,
    String? manualClientLocationUrl,
    double? manualClientLatitude,
    double? manualClientLongitude,
  }) {
    return BookingDraft(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      serviceName: serviceName ?? this.serviceName,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      subServiceId: subServiceId ?? this.subServiceId,
      serviceImage: serviceImage ?? this.serviceImage,
      priceTotal: priceTotal ?? this.priceTotal,
      area: area ?? this.area,
      totalLinearMeters: totalLinearMeters ?? this.totalLinearMeters,
      useWindowsCalculator: useWindowsCalculator ?? this.useWindowsCalculator,
      windows: windows ?? this.windows,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      dynamicInputs: dynamicInputs ?? this.dynamicInputs,
      isPriceCalculated: isPriceCalculated ?? this.isPriceCalculated,
      servicePriceData: servicePriceData ?? this.servicePriceData,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      manualClientGovernorate: manualClientGovernorate ?? this.manualClientGovernorate,
      manualClientCity: manualClientCity ?? this.manualClientCity,
      manualClientDistrict: manualClientDistrict ?? this.manualClientDistrict,
      manualClientAddressDetails: manualClientAddressDetails ?? this.manualClientAddressDetails,
      manualClientLocationUrl: manualClientLocationUrl ?? this.manualClientLocationUrl,
      manualClientLatitude: manualClientLatitude ?? this.manualClientLatitude,
      manualClientLongitude: manualClientLongitude ?? this.manualClientLongitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'currentStepIndex': currentStepIndex,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'serviceName': serviceName,
      'serviceTitle': serviceTitle,
      'subServiceId': subServiceId,
      'serviceImage': serviceImage,
      'priceTotal': priceTotal,
      'area': area,
      'totalLinearMeters': totalLinearMeters,
      'useWindowsCalculator': useWindowsCalculator,
      'windows': windows,
      'selectedOptions': selectedOptions,
      'dynamicInputs': dynamicInputs,
      'isPriceCalculated': isPriceCalculated,
      'servicePriceData': servicePriceData,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'manualClientGovernorate': manualClientGovernorate,
      'manualClientCity': manualClientCity,
      'manualClientDistrict': manualClientDistrict,
      'manualClientAddressDetails': manualClientAddressDetails,
      'manualClientLocationUrl': manualClientLocationUrl,
      'manualClientLatitude': manualClientLatitude,
      'manualClientLongitude': manualClientLongitude,
    };
  }

  factory BookingDraft.fromMap(Map<String, dynamic> map) {
    return BookingDraft(
      id: map['id'] as String,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      currentStepIndex: (map['currentStepIndex'] as num?)?.toInt() ?? 0,
      clientName: map['clientName'] as String?,
      clientPhone: map['clientPhone'] as String?,
      serviceName: map['serviceName'] as String?,
      serviceTitle: (map['serviceTitle'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      subServiceId: map['subServiceId'] as String?,
      serviceImage: map['serviceImage'] as String?,
      priceTotal: (map['priceTotal'] as num?)?.toDouble(),
      area: (map['area'] as num?)?.toDouble(),
      totalLinearMeters: (map['totalLinearMeters'] as num?)?.toDouble(),
      useWindowsCalculator: map['useWindowsCalculator'] as bool? ?? true,
      windows: (map['windows'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      selectedOptions: (map['selectedOptions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      dynamicInputs: (map['dynamicInputs'] as Map?) != null
          ? Map<String, dynamic>.from(map['dynamicInputs'] as Map)
          : const {},
      isPriceCalculated: map['isPriceCalculated'] as bool? ?? false,
      servicePriceData: (map['servicePriceData'] as Map?) != null
          ? Map<String, dynamic>.from(map['servicePriceData'] as Map)
          : null,
      scheduledAt: map['scheduledAt'] != null
          ? DateTime.tryParse(map['scheduledAt'] as String)
          : null,
      manualClientGovernorate: map['manualClientGovernorate'] as String?,
      manualClientCity: map['manualClientCity'] as String?,
      manualClientDistrict: map['manualClientDistrict'] as String?,
      manualClientAddressDetails: map['manualClientAddressDetails'] as String?
          ?? _reconstructAddressDetails(
               street: map['manualClientStreet'] as String? ?? '',
               building: map['manualClientBuilding'] as String? ?? '',
               floor: map['manualClientFloor'] as String?,
               apartment: map['manualClientApartment'] as String?,
               landmark: map['manualClientLandmark'] as String?,
             ),
      manualClientLocationUrl: map['manualClientLocationUrl'] as String?,
      manualClientLatitude: (map['manualClientLatitude'] as num?)?.toDouble(),
      manualClientLongitude: (map['manualClientLongitude'] as num?)?.toDouble(),
    );
  }

  /// Reconstructs addressDetails from legacy V2 fields for backward-compatible deserialization.
  static String _reconstructAddressDetails({
    required String street,
    required String building,
    String? floor,
    String? apartment,
    String? landmark,
  }) {
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (building.isNotEmpty) parts.add(building);
    if (floor != null && floor.isNotEmpty) parts.add('الدور $floor');
    if (apartment != null && apartment.isNotEmpty) parts.add('شقة $apartment');
    if (landmark != null && landmark.isNotEmpty) parts.add('($landmark)');
    return parts.isEmpty ? '' : parts.join('، ');
  }

  String toJson() => jsonEncode(toMap());

  factory BookingDraft.fromJson(String source) =>
      BookingDraft.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        id,
        createdAt,
        updatedAt,
        currentStepIndex,
        clientName,
        clientPhone,
        serviceName,
        serviceTitle,
        subServiceId,
        serviceImage,
        priceTotal,
        area,
        totalLinearMeters,
        useWindowsCalculator,
        windows,
        selectedOptions,
        dynamicInputs,
        isPriceCalculated,
        scheduledAt,
        manualClientGovernorate,
        manualClientCity,
        manualClientDistrict,
        manualClientAddressDetails,
        manualClientLocationUrl,
        manualClientLatitude,
        manualClientLongitude,
      ];
}
