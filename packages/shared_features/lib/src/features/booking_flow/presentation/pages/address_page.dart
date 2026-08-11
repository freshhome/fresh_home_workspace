import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/booking_flow_state.dart';

/// Address step for the **customer** booking flow.
/// Renders saved addresses from the customer's profile + a manual form option.
/// In admin mode this page is skipped; the address is entered in [ManualClientPage].
class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final _districtController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController(text: '1');
  final _floorController = TextEditingController(text: '1');
  final _apartmentController = TextEditingController(text: '1');
  final _landmarkController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otherCityController = TextEditingController();

  late final GeographicReferenceCubit _geoCubit;

  String? _selectedGovernorate;
  String? _selectedCity;
  String _selectedPropertyType = 'residential';
  double? _latitude;
  double? _longitude;
  int? _selectedAddressIndex;
  int? _selectedPhoneIndex;

  final ScrollController _scrollController = ScrollController();
  final _addressFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  bool _showAddressError = false;
  bool _showPhoneError = false;

  @override
  void initState() {
    super.initState();
    _geoCubit = GetIt.I<GeographicReferenceCubit>();

    final state = context.read<BookingFlowCubit>().state;
    final profile = state.currentUserProfile;

    final addressesList = profile is CustomerProfile
        ? profile.addresses
        : const <Address>[];
    final phoneList = profile?.phoneNumbers ?? [];

    _geoCubit.loadGovernorates().then((_) {
      if (state.address != null) {
        _fillAddressFields(state.address!);
        final idx = addressesList.indexWhere(
          (a) =>
              a.governorate == state.address!.governorate &&
              a.city == state.address!.city &&
              a.streetOrCompound == state.address!.streetOrCompound &&
              a.buildingIdentifier == state.address!.buildingIdentifier &&
              a.floor == state.address!.floor &&
              a.apartmentOrUnit == state.address!.apartmentOrUnit,
        );
        _selectedAddressIndex = idx != -1 ? idx : -1;
      } else {
        if (addressesList.isNotEmpty) {
          _selectedAddressIndex = 0;
          final addr = addressesList[0];
          _fillAddressFields(addr);
          context.read<BookingFlowCubit>().updateAddress(addr);
        }
      }
    });

    if (state.contact != null) {
      final phone = state.contact!.phone.firstOrNull ?? '';
      _phoneController.text = phone;

      final idx = phoneList.indexWhere((p) => p.phoneNumber == phone);
      _selectedPhoneIndex = idx != -1 ? idx : -1;
    } else {
      if (phoneList.isNotEmpty) {
        _selectedPhoneIndex = 0;
        final phone = phoneList[0].phoneNumber;
        _phoneController.text = phone;
        final contactName = profile != null
            ? '${profile.firstName} ${profile.lastName}'
            : '';
        context.read<BookingFlowCubit>().updateContact(
          Contact(name: contactName, phone: [phone]),
        );
      }
    }
  }

  @override
  void dispose() {
    _districtController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    _otherCityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  AddressPropertyType _parsePropertyType(String? type) {
    if (type == 'office') return AddressPropertyType.office;
    if (type == 'commercial') return AddressPropertyType.commercial;
    if (type == 'landmark') return AddressPropertyType.landmark;
    return AddressPropertyType.residential;
  }

  void _onChanged() {
    final state = context.read<BookingFlowCubit>().state;
    final locale = Localizations.localeOf(context).languageCode;
    final geoState = _geoCubit.state;
    final selectedGov = geoState.selectedGovernorate;
    final selectedCity = geoState.selectedCity;
    final selectedDistrict = geoState.selectedDistrict;

    final govName =
        selectedGov?.getName(locale) ??
        selectedGov?.nameAr ??
        _selectedGovernorate ??
        '';
    final cityName =
        selectedCity?.getName(locale) ??
        selectedCity?.nameAr ??
        _selectedCity ??
        '';
    final districtName =
        selectedDistrict?.getName(locale) ??
        (_districtController.text.trim().isNotEmpty
            ? _districtController.text.trim()
            : cityName);

    final address = Address(
      id: '',
      userId: state.currentUserProfile?.uid ?? '',
      governorate: govName,
      city: cityName,
      district: districtName,
      governorateId: selectedGov?.id,
      cityId: selectedCity?.id,
      districtId: selectedDistrict?.id,
      streetOrCompound: _streetController.text,
      buildingIdentifier: _buildingController.text,
      floor: _floorController.text,
      apartmentOrUnit: _apartmentController.text,
      propertyType: _selectedPropertyType,
      landmark: _landmarkController.text,
      latitude: _latitude,
      longitude: _longitude,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final contactName = state.currentUserProfile != null
        ? '${state.currentUserProfile!.firstName} ${state.currentUserProfile!.lastName}'
        : '';

    final contact = Contact(name: contactName, phone: [_phoneController.text]);

    context.read<BookingFlowCubit>().updateAddress(address);
    context.read<BookingFlowCubit>().updateContact(contact);
  }

  void _validateAndProceed(AppLocalizations l10n) {
    setState(() {
      _showAddressError = false;
      _showPhoneError = false;
    });

    final cubit = context.read<BookingFlowCubit>();
    final state = cubit.state;
    final hasAddresses = state.currentUserProfile is CustomerProfile
        ? (state.currentUserProfile as CustomerProfile).addresses.isNotEmpty
        : false;
    final phones =
        state.currentUserProfile?.phoneNumbers
            .map((e) => e.phoneNumber)
            .toList() ??
        [];
    final hasPhones = phones.isNotEmpty;

    if (hasAddresses) {
      if (_selectedAddressIndex == null) {
        setState(() => _showAddressError = true);
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
        return;
      }
      if (_selectedAddressIndex == -1) {
        if (!(_addressFormKey.currentState?.validate() ?? false)) return;
      }
    } else {
      if (!(_addressFormKey.currentState?.validate() ?? false)) return;
    }

    if (hasPhones) {
      if (_selectedPhoneIndex == null) {
        setState(() => _showPhoneError = true);
        return;
      }
      if (_selectedPhoneIndex == -1) {
        if (!(_phoneFormKey.currentState?.validate() ?? false)) return;
      }
    } else {
      if (!(_phoneFormKey.currentState?.validate() ?? false)) return;
    }

    if (_selectedAddressIndex == -1 || !hasAddresses) {
      final locale = Localizations.localeOf(context).languageCode;
      final geoState = _geoCubit.state;
      final selectedGov = geoState.selectedGovernorate;
      final selectedCity = geoState.selectedCity;
      final selectedDistrict = geoState.selectedDistrict;

      final govName =
          selectedGov?.getName(locale) ??
          selectedGov?.nameAr ??
          _selectedGovernorate ??
          '';
      final cityName =
          selectedCity?.getName(locale) ??
          selectedCity?.nameAr ??
          _selectedCity ??
          '';
      final districtName =
          selectedDistrict?.getName(locale) ??
          (_districtController.text.trim().isNotEmpty
              ? _districtController.text.trim()
              : cityName);

      cubit.updateAddress(
        Address(
          id: '',
          userId: state.currentUserProfile?.uid ?? '',
          governorate: govName,
          city: cityName,
          district: districtName,
          governorateId: selectedGov?.id,
          cityId: selectedCity?.id,
          districtId: selectedDistrict?.id,
          streetOrCompound: _streetController.text,
          buildingIdentifier: _buildingController.text,
          floor: _floorController.text,
          apartmentOrUnit: _apartmentController.text,
          propertyType: _selectedPropertyType,
          landmark: _landmarkController.text,
          latitude: _latitude,
          longitude: _longitude,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } else if (_selectedAddressIndex != null) {
      cubit.updateAddress(
        (state.currentUserProfile as CustomerProfile)
            .addresses[_selectedAddressIndex!],
      );
    }

    final selectedPhone = (_selectedPhoneIndex == -1 || !hasPhones)
        ? _phoneController.text
        : (hasPhones ? phones[_selectedPhoneIndex!] : _phoneController.text);

    cubit.updateContact(
      Contact(
        name: state.currentUserProfile != null
            ? '${state.currentUserProfile!.firstName} ${state.currentUserProfile!.lastName}'
            : '',
        phone: [selectedPhone],
      ),
    );

    cubit.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<BookingFlowCubit, BookingFlowState>(
      listenWhen: (prev, curr) =>
          prev.validateAddressTrigger != curr.validateAddressTrigger,
      listener: (context, state) => _validateAndProceed(l10n),
      child: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          final addressesList = state.currentUserProfile is CustomerProfile
              ? (state.currentUserProfile as CustomerProfile).addresses
              : const <Address>[];
          final phoneList = state.currentUserProfile?.phoneNumbers ?? [];
          final bool showSavedAddresses = addressesList.isNotEmpty;

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Address Section
                _buildSectionWrapper(
                  title: l10n.address_details_title,
                  icon: Icons.location_on_rounded,
                  themeColor: themeColor,
                  children: [
                    if (showSavedAddresses) ...[
                      _buildSavedAddresses(state, themeColor, themeText, l10n),
                      if (_showAddressError)
                        _buildErrorBox(
                          l10n.validation_address_selection_required,
                          themeColor,
                          themeText,
                        ),
                      const SizedBox(height: 20),
                    ],

                    if (_selectedAddressIndex == -1 || !showSavedAddresses)
                      _buildAddressForm(themeColor, themeText, l10n),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. Phone Section
                _buildSectionWrapper(
                  title: l10n.phone_section_title,
                  icon: Icons.phone_android_rounded,
                  themeColor: themeColor,
                  children: [
                    if (phoneList.isNotEmpty) ...[
                      _buildSavedPhones(state, themeColor, themeText, l10n),
                      if (_showPhoneError)
                        _buildErrorBox(
                          l10n.validation_phone_selection_required,
                          themeColor,
                          themeText,
                        ),
                      const SizedBox(height: 20),
                    ],

                    if (_selectedPhoneIndex == -1 || phoneList.isEmpty)
                      _buildPhoneForm(themeColor, themeText, l10n),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildSectionWrapper({
    required String title,
    required IconData icon,
    required ThemeColorExtension themeColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [themeColor.cardShadow],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: themeColor.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildErrorBox(
    String message,
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeColor.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.error.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: themeColor.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: themeColor.error,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressForm(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
    AppLocalizations l10n,
  ) {
    final locale = Localizations.localeOf(context).languageCode;

    return BlocProvider.value(
      value: _geoCubit,
      child: Form(
        key: _addressFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PropertyTypeSelector(
              selectedType: _parsePropertyType(_selectedPropertyType),
              onChanged: (type) {
                setState(() => _selectedPropertyType = type.name);
                _onChanged();
              },
            ),
            const SizedBox(height: 16),
            BlocBuilder<GeographicReferenceCubit, GeographicReferenceState>(
              builder: (blocContext, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Governorate Dropdown
                    _buildLabeledField(
                      label: l10n.address_governorate_label,
                      child: DropdownButtonFormField<int>(
                        dropdownColor: themeColor.cardBackground,
                        value: state.selectedGovernorateId,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: themeColor.background.withValues(
                            alpha: 0.5,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: themeColor.unselectedItem.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: themeColor.unselectedItem.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: themeColor.primary),
                          ),
                        ),
                        items: state.governorates
                            .map(
                              (g) => DropdownMenuItem<int>(
                                value: g.id,
                                child: Text(
                                  g.getName(locale),
                                  style: TextStyle(
                                    color: themeColor.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: state.isLoadingGovernorates
                            ? null
                            : (val) {
                                _geoCubit.selectGovernorate(val);
                                setState(() {
                                  _selectedGovernorate = state
                                      .selectedGovernorate
                                      ?.getName(locale);
                                  _selectedCity = null;
                                });
                                _onChanged();
                              },
                        validator: (val) =>
                            InputValidator.validateDropdownSelection(
                              val?.toString(),
                              l10n: l10n,
                            ),
                        hint: Text(
                          state.isLoadingGovernorates
                              ? 'جاري تحميل المحافظات...'
                              : l10n.address_governorate_label,
                          style: TextStyle(color: themeColor.secondaryText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. City Dropdown
                    _buildLabeledField(
                      label: l10n.address_region_label,
                      child: DropdownButtonFormField<int>(
                        dropdownColor: themeColor.cardBackground,
                        value: state.selectedCityId,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: themeColor.background.withValues(
                            alpha: 0.5,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: themeColor.unselectedItem.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: themeColor.unselectedItem.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: themeColor.primary),
                          ),
                        ),
                        items: state.cities
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(
                                  c.getName(locale),
                                  style: TextStyle(
                                    color: themeColor.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged:
                            (state.selectedGovernorateId == null ||
                                state.isLoadingCities)
                            ? null
                            : (val) {
                                _geoCubit.selectCity(val);
                                setState(() {
                                  _selectedCity = state.selectedCity?.getName(
                                    locale,
                                  );
                                });
                                _onChanged();
                              },
                        validator: (val) =>
                            InputValidator.validateDropdownSelection(
                              val?.toString(),
                              l10n: l10n,
                            ),
                        hint: Text(
                          state.isLoadingCities
                              ? 'جاري تحميل المدن...'
                              : (state.selectedGovernorateId == null
                                    ? l10n.address_select_governorate_first
                                    : l10n.address_select_city),
                          style: TextStyle(color: themeColor.secondaryText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. District Dropdown / Custom Field
                    if (state.districts.isNotEmpty) ...[
                      _buildLabeledField(
                        label: 'المنطقة / الحي',
                        child: DropdownButtonFormField<int>(
                          dropdownColor: themeColor.cardBackground,
                          value: state.selectedDistrictId,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor: themeColor.background.withValues(
                              alpha: 0.5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: themeColor.unselectedItem.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: themeColor.unselectedItem.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: themeColor.primary),
                            ),
                          ),
                          items: state.districts
                              .map(
                                (d) => DropdownMenuItem<int>(
                                  value: d.id,
                                  child: Text(
                                    d.getName(locale),
                                    style: TextStyle(
                                      color: themeColor.textPrimary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: state.isLoadingDistricts
                              ? null
                              : (val) {
                                  _geoCubit.selectDistrict(val);
                                  if (val != null) {
                                    final dist = state.districts.firstWhere(
                                      (d) => d.id == val,
                                    );
                                    _districtController.text = dist.getName(
                                      locale,
                                    );
                                  }
                                  _onChanged();
                                },
                          validator: (val) =>
                              InputValidator.validateDropdownSelection(
                                val?.toString(),
                                l10n: l10n,
                              ),
                          hint: Text(
                            state.isLoadingDistricts
                                ? 'جاري تحميل الأحياء...'
                                : 'اختر الحي / المنطقة',
                            style: TextStyle(color: themeColor.secondaryText),
                          ),
                        ),
                      ),
                    ] else ...[
                      _buildLabeledField(
                        label: 'المنطقة / الحي',
                        child: BaseTextFormField(
                          controller: _districtController,
                          hint: state.selectedCityId == null
                              ? 'اختر المدينة أولاً'
                              : 'أدخل اسم المنطقة أو الحي (مثال: الحي الأول)',
                          enabled: state.selectedCityId != null,
                          radius: 16,
                          fillColor: themeColor.background.withValues(
                            alpha: 0.5,
                          ),
                          prefixIcon: Icon(
                            Icons.location_city_rounded,
                            color: themeColor.primary.withValues(alpha: 0.7),
                            size: 22,
                          ),
                          onChanged: (_) => _onChanged(),
                          validator: (val) =>
                              InputValidator.validateEmpty(val, l10n: l10n),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _buildLabeledField(
              label: l10n.address_street_label,
              child: BaseTextFormField(
                controller: _streetController,
                hint: l10n.address_street_hint,
                radius: 16,
                fillColor: themeColor.background.withValues(alpha: 0.5),
                prefixIcon: Icon(
                  Icons.edit_road_rounded,
                  color: themeColor.primary.withValues(alpha: 0.7),
                  size: 22,
                ),
                validator: (val) =>
                    InputValidator.validateEmpty(val, l10n: l10n),
              ),
            ),
            const SizedBox(height: 20),

            // Improved Numeric Grid
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              decoration: BoxDecoration(
                color: themeColor.background.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: themeColor.unselectedItem.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildNumericInputItem(
                      label: l10n.address_building_label,
                      controller: _buildingController,
                      icon: Icons.home_work_rounded,
                      themeColor: themeColor,
                      l10n: l10n,
                    ),
                  ),
                  _buildVerticalDivider(themeColor),
                  Expanded(
                    child: _buildNumericInputItem(
                      label: l10n.address_floor_label,
                      controller: _floorController,
                      icon: Icons.layers_rounded,
                      themeColor: themeColor,
                      l10n: l10n,
                    ),
                  ),
                  _buildVerticalDivider(themeColor),
                  Expanded(
                    child: _buildNumericInputItem(
                      label: l10n.address_apartment_label,
                      controller: _apartmentController,
                      icon: Icons.door_front_door_rounded,
                      themeColor: themeColor,
                      l10n: l10n,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildLabeledField(
              label: 'علامة مميزة (اختياري)',
              child: BaseTextFormField(
                controller: _landmarkController,
                hint: 'مثال: بجوار مسجد المصطفى / أمام الصيدلية',
                radius: 16,
                fillColor: themeColor.background.withValues(alpha: 0.5),
                prefixIcon: Icon(
                  Icons.turned_in_not_rounded,
                  color: themeColor.primary.withValues(alpha: 0.7),
                  size: 22,
                ),
                onChanged: (_) => _onChanged(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final result = await AddressLocationPickerSheet.show(
                  context,
                  initialLatitude: _latitude,
                  initialLongitude: _longitude,
                );
                if (result != null) {
                  setState(() {
                    _latitude = result.latitude;
                    _longitude = result.longitude;
                  });
                }
              },

              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: themeColor.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeColor.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.my_location_rounded,
                      color: themeColor.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تحديد الموقع من الخريطة (GPS)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: themeColor.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _latitude != null && _longitude != null
                                ? 'الإحداثيات الحالية: $_latitude, $_longitude'
                                : 'انقر لتحديد موقعك بدقة على الخريطة',
                            style: TextStyle(
                              fontSize: 11,
                              color: themeColor.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: themeColor.secondaryText,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneForm(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
    AppLocalizations l10n,
  ) {
    return Form(
      key: _phoneFormKey,
      child: _buildLabeledField(
        label: l10n.address_phone_label,
        child: BaseTextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          hint: '01xxxxxxxxx',
          radius: 16,
          fillColor: themeColor.background.withValues(alpha: 0.5),
          onChanged: (_) => _onChanged(),
          validator: (val) =>
              InputValidator.validateEgyptianPhone(val, l10n: l10n),
          prefixIcon: Icon(
            Icons.phone_android_rounded,
            color: themeColor.primary,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildSavedAddresses(
    BookingFlowState state,
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
    AppLocalizations l10n,
  ) {
    final addressesList = state.currentUserProfile is CustomerProfile
        ? (state.currentUserProfile as CustomerProfile).addresses
        : const <Address>[];
    final activeColor = themeColor.primary;

    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: addressesList.length + 1,
        itemBuilder: (context, index) {
          final isAddNew = index == addressesList.length;
          final isSelected = _selectedAddressIndex == (isAddNew ? -1 : index);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedAddressIndex = isAddNew ? -1 : index;
                _showAddressError = false;
              });
              if (!isAddNew) {
                _fillAddressFields(addressesList[index]);
              } else {
                _clearAddressFields();
              }
              _onChanged();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 180,
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.04)
                    : themeColor.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : themeColor.unselectedItem.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: isAddNew
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_location_alt_rounded,
                          color: activeColor,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.add_new_address,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.home_rounded,
                              size: 14,
                              color: isSelected
                                  ? activeColor
                                  : themeColor.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                addressesList[index].city,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: isSelected
                                      ? activeColor
                                      : themeColor.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${addressesList[index].streetOrCompound}, ${l10n.address_building_label} ${addressesList[index].buildingIdentifier}',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: themeColor.secondaryText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavedPhones(
    BookingFlowState state,
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
    AppLocalizations l10n,
  ) {
    final phones = state.currentUserProfile?.phoneNumbers ?? [];
    final activeColor = themeColor.primary;

    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: phones.length + 1,
        itemBuilder: (context, index) {
          final bool isAddNew = index == phones.length;
          final bool isSelected =
              _selectedPhoneIndex == (isAddNew ? -1 : index);
          final phoneNumber = isAddNew ? null : phones[index].phoneNumber;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPhoneIndex = isAddNew ? -1 : index;
                _showPhoneError = false;
              });
              if (!isAddNew) {
                _phoneController.text = phoneNumber!;
              } else {
                _phoneController.clear();
              }
              _onChanged();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 150,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.04)
                    : themeColor.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : themeColor.unselectedItem.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isAddNew
                              ? Icons.add_ic_call_rounded
                              : Icons.phone_android_rounded,
                          color: isSelected
                              ? activeColor
                              : themeColor.secondaryText,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAddNew ? l10n.add_new_phone : phoneNumber!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected
                                ? activeColor
                                : themeColor.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Positioned(
                      top: 10,
                      right: 10,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    final themeColor = context.themeColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: themeColor.secondaryText,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildVerticalDivider(ThemeColorExtension themeColor) {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: themeColor.unselectedItem.withValues(alpha: 0.1),
    );
  }

  Widget _buildNumericInputItem({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required ThemeColorExtension themeColor,
    required AppLocalizations l10n,
  }) {
    return FormField<String>(
      validator: (val) =>
          InputValidator.validateAddressNumeric(controller.text, l10n: l10n),
      builder: (state) {
        final hasError = state.hasError;
        return Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: hasError ? themeColor.error : themeColor.secondaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            BaseTextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (val) {
                state.didChange(val);
                _onChanged();
              },
              hint: "00",
              radius: 12,
              fillColor: hasError
                  ? themeColor.error.withValues(alpha: 0.05)
                  : themeColor.cardBackground,
              errorBorderColor: themeColor.error,
              enabledBorderColor: themeColor.unselectedItem.withValues(
                alpha: 0.1,
              ),
              focusedBorderColor: themeColor.primary,
            ),
          ],
        );
      },
    );
  }

  void _fillAddressFields(Address address) {
    if (address.governorateId != null) {
      _geoCubit.selectGovernorate(address.governorateId).then((_) {
        if (address.cityId != null) {
          _geoCubit.selectCity(address.cityId).then((_) {
            if (address.districtId != null) {
              _geoCubit.selectDistrict(address.districtId);
            }
          });
        }
      });
    } else if (address.governorate.isNotEmpty) {
      try {
        final govs = _geoCubit.state.governorates;
        final matchedGov = govs.firstWhere(
          (g) =>
              g.nameAr == address.governorate ||
              g.nameEn == address.governorate,
        );
        _geoCubit.selectGovernorate(matchedGov.id).then((_) {
          try {
            final cities = _geoCubit.state.cities;
            final matchedCity = cities.firstWhere(
              (c) => c.nameAr == address.city || c.nameEn == address.city,
            );
            _geoCubit.selectCity(matchedCity.id).then((_) {
              try {
                final districts = _geoCubit.state.districts;
                final matchedDistrict = districts.firstWhere(
                  (d) =>
                      d.nameAr == address.district ||
                      d.nameEn == address.district,
                );
                _geoCubit.selectDistrict(matchedDistrict.id);
              } catch (_) {}
            });
          } catch (_) {}
        });
      } catch (_) {}
    }
    setState(() {
      _selectedGovernorate = address.governorate;
      _selectedCity = address.city;
    });
    _districtController.text = address.district;
    _streetController.text = address.streetOrCompound;
    _buildingController.text = address.buildingIdentifier;
    _floorController.text = address.floor ?? '';
    _apartmentController.text = address.apartmentOrUnit ?? '';
  }

  void _clearAddressFields() {
    _geoCubit.reset();
    setState(() {
      _selectedGovernorate = null;
      _selectedCity = null;
    });
    _districtController.clear();
    _streetController.clear();
    _buildingController.text = '1';
    _floorController.text = '1';
    _apartmentController.text = '1';
    _landmarkController.clear();
  }
}
