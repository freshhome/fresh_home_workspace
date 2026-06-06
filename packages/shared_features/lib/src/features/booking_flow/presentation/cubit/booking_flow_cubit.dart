import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/dynamic_field.dart';
import 'package:shared/domain/user/entities/user/phone.dart';
import 'package:shared/shared.dart';
import 'package:shared_features/src/features/booking_flow/domain/booking_flow_config.dart';
import 'package:shared_features/src/features/profile/domain/profile_domain.dart';
import 'package:uuid/uuid.dart';
import 'booking_flow_state.dart';

class BookingFlowCubit extends Cubit<BookingFlowState> {
  final BookingFlowConfig config;
  final CalculatePriceUseCase calculatePriceUseCase;
  final CreateBookingUseCase createBookingUseCase;
  final GetAvailableDaysUseCase getAvailableDaysUseCase;
  final CheckActiveCouponsUseCase checkActiveCouponsUseCase;

  // Optional – only required in customer mode for profile sync
  final ProfileRepository? profileRepository;

  // Optional – only required in admin mode for service loading
  final ServiceRepository? serviceRepository;

  Timer? _debounceTimer;
  int _pricingRequestToken = 0;

  BookingFlowCubit({
    required this.config,
    required this.calculatePriceUseCase,
    required this.createBookingUseCase,
    required this.getAvailableDaysUseCase,
    required this.checkActiveCouponsUseCase,
    this.profileRepository,
    this.serviceRepository,
  }) : super(
         BookingFlowState(
           service: config.preSelectedService,
           servicePrice: config.initialServicePrice,
           dynamicInputs: _getInitialDynamicInputs(config.initialServicePrice),
         ),
       ) {
    _init();
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> _init() async {
    if (config.requiresProfileSync) {
      await _loadProfile();
    }
    if (serviceRepository != null && state.service != null) {
      final result = await serviceRepository!.getServiceById(
        state.service!.subServiceId,
      );
      result.fold((failure) => null, (serviceEntity) {
        emit(state.copyWith(computedFields: serviceEntity.computedFields));
      });
    }
    await _checkActiveCoupons();
  }

  Future<void> _loadProfile() async {
    final result = await profileRepository!.loadProfile();
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (profile) => emit(state.copyWith(currentUserProfile: profile)),
    );
  }

  // ── Service Selection (Admin) ───────────────────────────────────────────────

  void selectService(SubServiceEntity subService) {
    final bookedService = BookedService(
      id: Uuid().v4(),
      subServiceId: subService.id,
      name: subService.title,
      image: subService.image ?? '',
    );
    emit(
      state.copyWith(
        service: bookedService,
        servicePrice: subService.price,
        computedFields: subService.computedFields,
        dynamicInputs: _getInitialDynamicInputs(subService.price),
        isPriceCalculated: false,
        clearPrice: true,
        hasActiveCoupons: false, // temporarily reset while fetching
      ),
    );
    _validateCurrentStep();
    _checkActiveCoupons();
  }

  // ── Pricing ────────────────────────────────────────────────────────────────
  
  Future<void> _checkActiveCoupons() async {
    final subServiceId = state.service?.subServiceId;
    if (subServiceId == null) return;

    final result = await checkActiveCouponsUseCase(subServiceId);
    if (isClosed) return;
    result.fold(
      (failure) => null,
      (hasCoupons) {
        emit(state.copyWith(hasActiveCoupons: hasCoupons));
      },
    );
  }

  // ── Pricing ────────────────────────────────────────────────────────────────

  Future<void> calculatePrice({
    double? area,
    double? width,
    double? height,
    double? totalLinearMeters,
  }) async {
    final priceEntity = state.servicePrice;
    if (priceEntity == null) {
      emit(state.copyWith(errorMessage: 'error_pricing_data_unavailable'));
      return;
    }

    double? calcLinearMeters = totalLinearMeters ?? state.totalLinearMeters;
    if (priceEntity.type == PricingMethod.perLinearMeter) {
      if (state.useWindowsCalculator && state.windows.isNotEmpty) {
        calcLinearMeters = state.windows.fold(
          0.0,
          (sum, window) => sum! + window.effectiveLinearMeters,
        );
      }
    }

    final calcArea = area ?? state.area;
    final currentToken = ++_pricingRequestToken;

    emit(state.copyWith(status: BookingStatus.loading, errorMessage: null));

    final result = await calculatePriceUseCase(
      CalculatePriceParams(
        priceEntity: priceEntity,
        subServiceId: state.service?.subServiceId,
        area: calcArea,
        width: width,
        height: height,
        totalLinearMeters: calcLinearMeters,
        windows: state.useWindowsCalculator ? state.windows : null,
        selectedOptions: state.selectedOptions,
        pricingInputs: state.dynamicInputs,
      ),
    );

    if (isClosed || currentToken != _pricingRequestToken) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: BookingStatus.failure,
            errorMessage: failure.message,
            isCurrentStepValid: false,
            isPriceCalculated: false,
            clearPrice: true,
          ),
        );
      },
      (bookingPricing) {
        emit(
          state.copyWith(
            status: BookingStatus.success,
            price: bookingPricing,
            isPriceCalculated: true,
            area: calcArea,
            clearArea: calcArea == null,
          ),
        );
        _validateCurrentStep();
      },
    );
  }

  void updateDynamicInput(String key, dynamic value) {
    final updated = Map<String, dynamic>.from(state.dynamicInputs);
    if (value == null) {
      updated.remove(key);
    } else {
      updated[key] = value;
    }

    // Fallback sync for classic area
    double? syncArea = state.area;
    bool shouldClearArea = false;
    if (key == 'area') {
      if (value != null) {
        syncArea = (value as num).toDouble();
      } else {
        syncArea = null;
        shouldClearArea = true;
      }
    }

    // Fallback sync for total_linear_meters
    double? syncLinearMeters = state.totalLinearMeters;
    bool shouldClearLinearMeters = false;
    if (key == 'total_linear_meters') {
      if (value != null) {
        syncLinearMeters = (value as num).toDouble();
      } else {
        syncLinearMeters = null;
        shouldClearLinearMeters = true;
      }
    }

    emit(
      state.copyWith(
        dynamicInputs: updated,
        area: syncArea,
        clearArea: shouldClearArea,
        totalLinearMeters: syncLinearMeters,
        clearTotalLinearMeters: shouldClearLinearMeters,
        isPriceCalculated: false,
        clearPrice: true,
      ),
    );
    _validateCurrentStep();
  }

  void updateArea(double? area) {
    updateDynamicInput('area', area);
  }

  void updateUseWindowsCalculator(bool value) {
    emit(
      state.copyWith(
        useWindowsCalculator: value,
        isPriceCalculated: false,
        clearPrice: true,
        isCurrentStepValid: false,
      ),
    );
    _validateCurrentStep();
  }

  void updateTotalLinearMeters(double? value) {
    updateDynamicInput('total_linear_meters', value);
  }

  void toggleOption(String key) {
    final updated = List<String>.from(state.selectedOptions);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    emit(
      state.copyWith(
        selectedOptions: updated,
        isPriceCalculated: false,
        clearPrice: true,
      ),
    );
    _validateCurrentStep();
  }

  void addWindow() {
    final updated = List<WindowDimension>.from(state.windows)
      ..add(const WindowDimension(width: 0, height: 0, quantity: 1));
    emit(
      state.copyWith(
        windows: updated,
        isPriceCalculated: false,
        clearPrice: true,
        isCurrentStepValid: false,
      ),
    );
  }

  void updateWindow(int index, WindowDimension window) {
    final updated = List<WindowDimension>.from(state.windows);
    updated[index] = window;
    emit(
      state.copyWith(
        windows: updated,
        isPriceCalculated: false,
        clearPrice: true,
        isCurrentStepValid: false,
      ),
    );
  }

  void removeWindow(int index) {
    final updated = List<WindowDimension>.from(state.windows)..removeAt(index);
    emit(
      state.copyWith(
        windows: updated,
        isPriceCalculated: false,
        clearPrice: true,
        isCurrentStepValid: false,
      ),
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  // ── Schedule ───────────────────────────────────────────────────────────────

  Future<void> fetchAvailability() async {
    if (state.service == null) return;
    emit(state.copyWith(isLoadingAvailability: true, availabilityError: null));

    final startDate = config.earliestSelectableDate;
    final endDate = startDate.add(const Duration(days: 30));

    final result = await getAvailableDaysUseCase(
      serviceId: state.service!.subServiceId,
      startDate: startDate,
      endDate: endDate,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingAvailability: false,
          availabilityError: failure.message,
        ),
      ),
      (availabilities) {
        final Map<DateTime, bool> map = {};
        for (int i = 0; i <= 30; i++) {
          final date = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          ).add(Duration(days: i));
          map[date] = false;
        }
        for (var a in availabilities) {
          final date = DateTime(a.date.year, a.date.month, a.date.day);
          map[date] = a.isAvailable;
        }
        emit(
          state.copyWith(isLoadingAvailability: false, availabilityMap: map),
        );
      },
    );
  }

  void updateSchedule(DateTime scheduledAt) {
    emit(state.copyWith(scheduledAt: scheduledAt));
    _validateCurrentStep();
  }

  // ── Address (Customer) ─────────────────────────────────────────────────────

  void updateAddress(Address address) {
    emit(state.copyWith(address: address));
    _validateCurrentStep();
  }

  void requestAddressValidation() {
    emit(
      state.copyWith(validateAddressTrigger: state.validateAddressTrigger + 1),
    );
  }

  void requestManualClientValidation() {
    emit(
      state.copyWith(
        validateManualClientTrigger: state.validateManualClientTrigger + 1,
      ),
    );
  }

  void updateContact(Contact contact) {
    emit(state.copyWith(contact: contact));
  }

  // ── Manual Client Data (Admin) ─────────────────────────────────────────────

  void updateManualClientData({
    String? name,
    String? phone,
    String? governorate,
    String? city,
    String? street,
    String? building,
    String? floor,
    String? apartment,
  }) {
    emit(
      state.copyWith(
        manualClientName: name ?? state.manualClientName,
        manualClientPhone: phone ?? state.manualClientPhone,
        manualClientGovernorate: governorate ?? state.manualClientGovernorate,
        manualClientCity: city ?? state.manualClientCity,
        manualClientStreet: street ?? state.manualClientStreet,
        manualClientBuilding: building ?? state.manualClientBuilding,
        manualClientFloor: floor ?? state.manualClientFloor,
        manualClientApartment: apartment ?? state.manualClientApartment,
      ),
    );
    _validateCurrentStep();
  }

  // ── Step Navigation ────────────────────────────────────────────────────────

  /// Returns the ordered list of step indices for the current config.
  /// Admin:    0=serviceSelection 1=pricing 2=schedule 3=clientData 4=confirmation
  /// Customer: 0=pricing          1=schedule           2=address    3=confirmation
  int get totalSteps => config.totalSteps;

  void nextStep() {
    final next = state.currentStepIndex + 1;
    if (next >= totalSteps) return;

    // Fetch availability when entering the schedule step
    final scheduleStepIndex = config.requiresServiceSelection ? 2 : 1;
    if (next == scheduleStepIndex) fetchAvailability();

    emit(state.copyWith(currentStepIndex: next));
    _validateCurrentStep();
  }

  void previousStep() {
    resetStatus();
    final prev = state.currentStepIndex - 1;
    if (prev < 0) return;
    emit(state.copyWith(currentStepIndex: prev));
    _validateCurrentStep();
  }

  void resetStatus() {
    emit(state.copyWith(status: BookingStatus.initial));
  }

  // ── Submission ─────────────────────────────────────────────────────────────

  Future<void> submitBooking() async {
    if (state.status == BookingStatus.loading) return;

    // Build address & contact based on mode
    final Address? finalAddress = _resolveAddress();
    final Contact? finalContact = _resolveContact();

    if (state.service == null ||
        state.scheduledAt == null ||
        state.price == null ||
        !state.isPriceCalculated ||
        finalAddress == null ||
        finalContact == null) {
      emit(
        state.copyWith(
          errorMessage: 'error_incomplete_data',
          status: BookingStatus.failure,
        ),
      );
      return;
    }

    emit(state.copyWith(status: BookingStatus.loading));

    // Customer-only: sync new address/phone to profile
    final Address syncedAddress = config.requiresProfileSync
        ? (await _syncNewDataToProfile(finalAddress, finalContact) ??
              finalAddress)
        : finalAddress;

    double? calcLinearMeters;
    if (state.servicePrice?.type == PricingMethod.perLinearMeter) {
      if (state.useWindowsCalculator) {
        if (state.windows.isNotEmpty) {
          calcLinearMeters = state.windows.fold(
            0.0,
            (sum, window) => sum! + window.effectiveLinearMeters,
          );
        }
      } else {
        calcLinearMeters = state.totalLinearMeters;
      }
    }

    final pricingInputs = <String, dynamic>{
      ...state.dynamicInputs,
      if (state.area != null) 'area': state.area,
      'total_linear_meters': calcLinearMeters,
      if (state.useWindowsCalculator)
        'windows': state.windows
            .map(
              (w) => {
                'width': w.width,
                'height': w.height,
                'quantity': w.quantity,
                'is_both_sides': w.isBothSides,
              },
            )
            .toList(),
      'selected_options': state.selectedOptions,
    };

    final booking = Booking(
      id: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
      userId: config.actorId,
      service: state.service!,
      address: syncedAddress,
      scheduledAt: state.scheduledAt!,
      startTimeSlot: DateFormat('HH:mm').format(state.scheduledAt!),
      price: state.price!,
      status: OrderStatus.assigned,
      contact: finalContact,
      addressId: syncedAddress.id,
      serviceId: state.service!.subServiceId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pricingInputs: pricingInputs,
    );

    final result = await createBookingUseCase(booking: booking);

    result.fold(
      (failure) {
        if (isClosed) return;
        emit(
          state.copyWith(
            status: BookingStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (newBookingId) {
        if (isClosed) return;
        emit(
          state.copyWith(
            status: BookingStatus.success,
            generatedBookingId: newBookingId,
          ),
        );
      },
    );
  }

  Address? _resolveAddress() {
    if (config.requiresManualClientData) {
      final gov = state.manualClientGovernorate;
      final city = state.manualClientCity;
      final street = state.manualClientStreet;
      final building = state.manualClientBuilding;
      final floor = state.manualClientFloor;
      final apartment = state.manualClientApartment;
      if (gov == null || city == null || street == null || building == null) {
        return null;
      }
      return Address(
        id: const Uuid().v4(),
        governorate: gov,
        city: city,
        street: street,
        buildingNumber: building,
        floorNumber: floor,
        apartmentNumber: apartment,
      );
    }
    return state.address;
  }

  Contact? _resolveContact() {
    if (config.requiresManualClientData) {
      final name = state.manualClientName;
      final phone = state.manualClientPhone;
      if (name == null || phone == null) return null;
      return Contact(name: name, phone: [phone]);
    }
    return state.contact;
  }

  Future<Address?> _syncNewDataToProfile(
    Address usedAddress,
    Contact usedContact,
  ) async {
    final profile = state.currentUserProfile;
    if (profile == null || profileRepository == null) return usedAddress;

    final usedPhone = usedContact.phone.firstOrNull;
    if (usedPhone == null) return usedAddress;

    final addresses = profile.clientProfile?.addresses ?? [];
    final phones = profile.clientProfile?.phoneNumbers ?? [];

    final isNewAddress = !addresses.any(
      (a) =>
          a.governorate == usedAddress.governorate &&
          a.city == usedAddress.city &&
          a.street == usedAddress.street &&
          a.buildingNumber == usedAddress.buildingNumber &&
          a.floorNumber == usedAddress.floorNumber &&
          a.apartmentNumber == usedAddress.apartmentNumber,
    );

    final isNewPhone = !phones.any((p) => p.phoneNumber == usedPhone);

    if (isNewAddress) {
      await profileRepository!.addAddress(
        address: Address(
          governorate: usedAddress.governorate,
          city: usedAddress.city,
          street: usedAddress.street,
          buildingNumber: usedAddress.buildingNumber,
          floorNumber: usedAddress.floorNumber,
          apartmentNumber: usedAddress.apartmentNumber,
        ),
      );
    }

    if (isNewPhone) {
      final updatedPhones = List<Phone>.from(phones)
        ..add(
          Phone(
            id: '',
            userId: profile.user.uid,
            phoneNumber: usedPhone,
            isPrimary: phones.isEmpty,
            isVerified: false,
            createdAt: DateTime.now(),
          ),
        );
      await profileRepository!.updatePhoneNumbers(phoneNumbers: updatedPhones);
    }

    Address? finalAddress = usedAddress;
    final updatedResult = await profileRepository!.loadProfile();
    updatedResult.fold((_) => null, (updatedProfile) {
      if (isClosed) return;
      emit(state.copyWith(currentUserProfile: updatedProfile));
      final updatedAddresses = updatedProfile.clientProfile?.addresses ?? [];
      finalAddress = updatedAddresses.firstWhere(
        (a) =>
            a.governorate == usedAddress.governorate &&
            a.city == usedAddress.city &&
            a.street == usedAddress.street &&
            a.buildingNumber == usedAddress.buildingNumber &&
            a.floorNumber == usedAddress.floorNumber &&
            a.apartmentNumber == usedAddress.apartmentNumber,
        orElse: () => usedAddress,
      );
    });

    return finalAddress;
  }

  void _validateCurrentStep() {
    bool isValid = false;

    if (config.mode == BookingFlowMode.admin) {
      switch (state.currentStepIndex) {
        case 0: // serviceSelection
          isValid = state.service != null;
          break;
        case 1: // pricing
          isValid = state.isPriceCalculated && state.price != null;
          break;
        case 2: // schedule
          isValid = state.scheduledAt != null;
          break;
        case 3: // clientData
          final phoneRegex = RegExp(r'^(010|011|012|015)\d{8}$');
          isValid =
              state.manualClientName != null &&
              state.manualClientName!.trim().isNotEmpty &&
              state.manualClientPhone != null &&
              phoneRegex.hasMatch(state.manualClientPhone!.trim()) &&
              state.manualClientGovernorate != null &&
              state.manualClientCity != null &&
              state.manualClientStreet != null &&
              state.manualClientStreet!.trim().isNotEmpty &&
              state.manualClientBuilding != null &&
              state.manualClientBuilding!.trim().isNotEmpty;
          break;
        case 4: // confirmation
          isValid = true;
          break;
      }
    } else {
      switch (state.currentStepIndex) {
        case 0: // pricing
          isValid = state.isPriceCalculated && state.price != null;
          break;
        case 1: // schedule
          isValid = state.scheduledAt != null;
          break;
        case 2: // address
          isValid = state.address != null;
          break;
        case 3: // confirmation
          isValid = true;
          break;
      }
    }

    emit(state.copyWith(isCurrentStepValid: isValid));
  }

  static Map<String, dynamic> _getInitialDynamicInputs(
    PriceEntity? priceConfig,
  ) {
    final inputs = <String, dynamic>{};
    if (priceConfig != null) {
      for (final field in priceConfig.fields) {
        if (field.type == DynamicFieldType.toggle) {
          inputs[field.id] = false;
        }
      }
    }
    return inputs;
  }
}
