import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/service/entities/sub_entities/service_price.dart';
import 'package:shared/domain/service/entities/sub_entities/computed_field.dart';

import 'package:shared_features/src/features/profile/domain/profile_domain.dart';

enum BookingStep { pricing, schedule, address, confirmation }

/// Admin-specific step inserted between schedule and confirmation.
enum AdminBookingStep { serviceSelection, pricing, schedule, clientData, confirmation }

enum BookingStatus { initial, loading, success, failure }

class BookingFlowState {
  // ── Service ────────────────────────────────────────────────────────────────
  final BookedService? service;
  final PriceEntity? servicePrice;
  final List<ComputedFieldEntity>? computedFields;

  // ── Steps ──────────────────────────────────────────────────────────────────
  /// Index shared by both customer and admin flows.
  final int currentStepIndex;

  // ── Pricing ────────────────────────────────────────────────────────────────
  final double? area;
  final List<WindowDimension> windows;
  final List<String> selectedOptions;
  final Map<String, dynamic> dynamicInputs;
  final BookingPricing? price;
  final bool isPriceCalculated;
  final bool useWindowsCalculator;
  final double? totalLinearMeters;

  // ── Schedule ───────────────────────────────────────────────────────────────
  final DateTime? scheduledAt;
  final Map<DateTime, bool> availabilityMap;
  final bool isLoadingAvailability;
  final String? availabilityError;

  // ── Address (Customer) ─────────────────────────────────────────────────────
  final Address? address;
  final int validateAddressTrigger;

  // ── Contact ────────────────────────────────────────────────────────────────
  final Contact? contact;

  // ── Manual client data (Admin) ─────────────────────────────────────────────
  final String? manualClientName;
  final String? manualClientPhone;
  final String? manualClientGovernorate;
  final String? manualClientCity;
  final String? manualClientStreet;
  final String? manualClientBuilding;
  final String? manualClientFloor;
  final String? manualClientApartment;
  final int validateManualClientTrigger;

  // ── Profile (Customer) ─────────────────────────────────────────────────────
  final UserWithProfile? currentUserProfile;

  // ── Status ─────────────────────────────────────────────────────────────────
  final BookingStatus status;
  final bool isCurrentStepValid;
  final String? errorMessage;
  final String? generatedBookingId;
  final bool hasActiveCoupons;

  const BookingFlowState({
    this.service,
    this.servicePrice,
    this.computedFields,
    this.currentStepIndex = 0,
    this.area,
    this.windows = const [],
    this.selectedOptions = const [],
    this.dynamicInputs = const {},
    this.price,
    this.isPriceCalculated = false,
    this.useWindowsCalculator = true,
    this.totalLinearMeters,
    this.scheduledAt,
    this.availabilityMap = const {},
    this.isLoadingAvailability = false,
    this.availabilityError,
    this.address,
    this.validateAddressTrigger = 1,
    this.contact,
    this.manualClientName,
    this.manualClientPhone,
    this.manualClientGovernorate,
    this.manualClientCity,
    this.manualClientStreet,
    this.manualClientBuilding,
    this.manualClientFloor,
    this.manualClientApartment,
    this.validateManualClientTrigger = 0,
    this.currentUserProfile,
    this.status = BookingStatus.initial,
    this.isCurrentStepValid = false,
    this.errorMessage,
    this.generatedBookingId,
    this.hasActiveCoupons = false,
  });

  BookingFlowState copyWith({
    BookedService? service,
    PriceEntity? servicePrice,
    List<ComputedFieldEntity>? computedFields,
    int? currentStepIndex,
    double? area,
    bool clearArea = false,
    List<WindowDimension>? windows,
    List<String>? selectedOptions,
    Map<String, dynamic>? dynamicInputs,
    BookingPricing? price,
    bool clearPrice = false,
    bool? isPriceCalculated,
    bool? useWindowsCalculator,
    double? totalLinearMeters,
    bool clearTotalLinearMeters = false,
    DateTime? scheduledAt,
    Map<DateTime, bool>? availabilityMap,
    bool? isLoadingAvailability,
    String? availabilityError,
    Address? address,
    int? validateAddressTrigger,
    Contact? contact,
    String? manualClientName,
    String? manualClientPhone,
    String? manualClientGovernorate,
    String? manualClientCity,
    String? manualClientStreet,
    String? manualClientBuilding,
    String? manualClientFloor,
    String? manualClientApartment,
    int? validateManualClientTrigger,
    UserWithProfile? currentUserProfile,
    BookingStatus? status,
    bool? isCurrentStepValid,
    String? errorMessage,
    String? generatedBookingId,
    bool? hasActiveCoupons,
  }) {
    return BookingFlowState(
      service: service ?? this.service,
      servicePrice: servicePrice ?? this.servicePrice,
      computedFields: computedFields ?? this.computedFields,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      area: clearArea ? null : (area ?? this.area),
      windows: windows ?? this.windows,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      dynamicInputs: dynamicInputs ?? this.dynamicInputs,
      price: clearPrice ? null : (price ?? this.price),
      isPriceCalculated: isPriceCalculated ?? this.isPriceCalculated,
      useWindowsCalculator: useWindowsCalculator ?? this.useWindowsCalculator,
      totalLinearMeters: clearTotalLinearMeters ? null : (totalLinearMeters ?? this.totalLinearMeters),
      scheduledAt: scheduledAt ?? this.scheduledAt,
      availabilityMap: availabilityMap ?? this.availabilityMap,
      isLoadingAvailability: isLoadingAvailability ?? this.isLoadingAvailability,
      availabilityError: availabilityError ?? this.availabilityError,
      address: address ?? this.address,
      validateAddressTrigger: validateAddressTrigger ?? this.validateAddressTrigger,
      contact: contact ?? this.contact,
      manualClientName: manualClientName ?? this.manualClientName,
      manualClientPhone: manualClientPhone ?? this.manualClientPhone,
      manualClientGovernorate: manualClientGovernorate ?? this.manualClientGovernorate,
      manualClientCity: manualClientCity ?? this.manualClientCity,
      manualClientStreet: manualClientStreet ?? this.manualClientStreet,
      manualClientBuilding: manualClientBuilding ?? this.manualClientBuilding,
      manualClientFloor: manualClientFloor ?? this.manualClientFloor,
      manualClientApartment: manualClientApartment ?? this.manualClientApartment,
      validateManualClientTrigger: validateManualClientTrigger ?? this.validateManualClientTrigger,
      currentUserProfile: currentUserProfile ?? this.currentUserProfile,
      status: status ?? this.status,
      isCurrentStepValid: isCurrentStepValid ?? this.isCurrentStepValid,
      errorMessage: errorMessage,   // explicitly null-able
      generatedBookingId: generatedBookingId ?? this.generatedBookingId,
      hasActiveCoupons: hasActiveCoupons ?? this.hasActiveCoupons,
    );
  }
}
