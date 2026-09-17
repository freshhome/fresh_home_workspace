import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/booking_flow_state.dart';

/// Admin-only step: the admin enters the client's contact details manually.
/// This replaces the profile-based [AddressPage] used in customer mode.
class ManualClientPage extends StatefulWidget {
  const ManualClientPage({super.key});

  @override
  State<ManualClientPage> createState() => _ManualClientPageState();
}

class _ManualClientPageState extends State<ManualClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _districtController = TextEditingController();
  final _addressDetailsController = TextEditingController();
  final _locationUrlController = TextEditingController();
  final _customDistrictController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _governorateFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _districtFocus = FocusNode();
  final _customDistrictFocus = FocusNode();
  final _locationUrlFocus = FocusNode();
  final _addressDetailsFocus = FocusNode();

  late final GeographicReferenceCubit _geoCubit;

  String? _selectedGovernorate;
  String? _selectedCity;
  String? _selectedDistrictString;
  bool _isCustomDistrict = false;
  String _selectedPropertyType = 'residential';

  @override
  void initState() {
    super.initState();
    _geoCubit = GetIt.I<GeographicReferenceCubit>();

    final state = context.read<BookingFlowCubit>().state;
    _nameController.text = state.manualClientName ?? '';
    _phoneController.text = state.manualClientPhone ?? '';
    _selectedGovernorate = state.manualClientGovernorate;
    _selectedCity = state.manualClientCity;
    _districtController.text = state.manualClientDistrict ?? '';
    _addressDetailsController.text = state.manualClientAddressDetails ?? '';
    _locationUrlController.text =
        state.manualClientLocationUrl ?? state.address?.locationUrl ?? '';
    _selectedDistrictString = state.manualClientDistrict;

    _geoCubit.loadGovernorates().then((_) {
      if (state.address != null && state.address!.governorateId != null) {
        _geoCubit.selectGovernorate(state.address!.governorateId).then((_) {
          if (state.address!.cityId != null) {
            _geoCubit.selectCity(state.address!.cityId).then((_) {
              if (state.address!.districtId != null) {
                _geoCubit.selectDistrict(state.address!.districtId);
              }
            });
          }
        });
      } else if (_selectedGovernorate != null &&
          _selectedGovernorate!.isNotEmpty) {
        try {
          final govs = _geoCubit.state.governorates;
          final matchedGov = govs.firstWhere(
            (g) =>
                g.nameAr == _selectedGovernorate ||
                g.nameEn == _selectedGovernorate,
          );
          _geoCubit.selectGovernorate(matchedGov.id).then((_) {
            if (_selectedCity != null && _selectedCity!.isNotEmpty) {
              try {
                final cities = _geoCubit.state.cities;
                final matchedCity = cities.firstWhere(
                  (c) => c.nameAr == _selectedCity || c.nameEn == _selectedCity,
                );
                _geoCubit.selectCity(matchedCity.id).then((_) {
                  if (_districtController.text.isNotEmpty) {
                    try {
                      final districts = _geoCubit.state.districts;
                      final matchedDistrict = districts.firstWhere(
                        (d) =>
                            d.nameAr == _districtController.text ||
                            d.nameEn == _districtController.text,
                      );
                      _geoCubit.selectDistrict(matchedDistrict.id);
                    } catch (_) {}
                  }
                });
              } catch (_) {}
            }
          });
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _addressDetailsController.dispose();
    _locationUrlController.dispose();
    _customDistrictController.dispose();

    _nameFocus.dispose();
    _phoneFocus.dispose();
    _governorateFocus.dispose();
    _cityFocus.dispose();
    _districtFocus.dispose();
    _customDistrictFocus.dispose();
    _locationUrlFocus.dispose();
    _addressDetailsFocus.dispose();
    super.dispose();
  }

  AddressPropertyType _parsePropertyType(String? type) {
    if (type == 'office') return AddressPropertyType.office;
    if (type == 'commercial') return AddressPropertyType.commercial;
    if (type == 'landmark') return AddressPropertyType.landmark;
    return AddressPropertyType.residential;
  }

  void _syncToState() {
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

    final String districtName;
    if (_isCustomDistrict) {
      districtName = _customDistrictController.text.trim().isNotEmpty
          ? _customDistrictController.text.trim()
          : cityName;
    } else if (_selectedDistrictString != null &&
        _selectedDistrictString!.isNotEmpty) {
      districtName = _selectedDistrictString!;
    } else if (selectedDistrict != null) {
      districtName = selectedDistrict.getName(locale);
    } else if (_districtController.text.trim().isNotEmpty) {
      districtName = _districtController.text.trim();
    } else {
      districtName = cityName;
    }

    final locationUrl = _locationUrlController.text.trim().isNotEmpty
        ? _locationUrlController.text.trim()
        : null;

    final String resolvedGovAr = selectedGov?.nameAr ??
        (govName.toLowerCase().contains('giza')
            ? 'الجيزة'
            : (govName.toLowerCase().contains('cairo') ? 'القاهرة' : govName));
    final String resolvedGovEn = selectedGov?.nameEn ??
        (govName.contains('جيزة')
            ? 'Giza'
            : (govName.contains('قاهرة') ? 'Cairo' : govName));

    final address = Address(
      id: '',
      userId: '',
      governorate: resolvedGovAr.isNotEmpty ? resolvedGovAr : govName,
      city: cityName,
      district: districtName,
      governorateId: selectedGov?.id,
      cityId: selectedCity?.id,
      districtId: selectedDistrict?.id,
      governorateAr: resolvedGovAr,
      governorateEn: resolvedGovEn,
      cityAr: selectedCity?.nameAr ?? cityName,
      cityEn: selectedCity?.nameEn ?? cityName,
      districtAr: selectedDistrict?.nameAr ?? districtName,
      districtEn: selectedDistrict?.nameEn ?? districtName,
      addressDetails: _addressDetailsController.text.trim(),
      locationUrl: locationUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<BookingFlowCubit>().updateManualClientData(
      name: _nameController.text,
      phone: _phoneController.text,
      governorate: govName,
      city: cityName,
      district: districtName,
      addressDetails: _addressDetailsController.text.trim(),
      locationUrl: locationUrl,
    );
    context.read<BookingFlowCubit>().updateAddress(address);
  }

  void _validateAndProceed(AppLocalizations l10n) {
    _syncToState();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<BookingFlowCubit>().nextStep();
    } else {
      // Logic to find the first error and scroll to it
      FocusNode? firstErrorFocus;

      if (InputValidator.validateEmpty(_nameController.text) != null) {
        firstErrorFocus = _nameFocus;
      } else if (InputValidator.validateEgyptianPhone(_phoneController.text) !=
          null) {
        firstErrorFocus = _phoneFocus;
      } else if (_selectedGovernorate == null) {
        firstErrorFocus = _governorateFocus;
      } else if (_selectedCity == null) {
        firstErrorFocus = _cityFocus;
      } else if (_isCustomDistrict &&
          InputValidator.validateEmpty(_customDistrictController.text) !=
              null) {
        firstErrorFocus = _customDistrictFocus;
      } else if (!_isCustomDistrict &&
          _selectedDistrictString == null &&
          InputValidator.validateEmpty(_districtController.text) != null) {
        firstErrorFocus = _districtFocus;
      } else if (_addressDetailsController.text.trim().length < 5) {
        firstErrorFocus = _addressDetailsFocus;
      }

      if (firstErrorFocus != null) {
        Scrollable.ensureVisible(
          firstErrorFocus.context!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.5, // Center the field
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<BookingFlowCubit, BookingFlowState>(
      listenWhen: (prev, curr) =>
          prev.validateManualClientTrigger != curr.validateManualClientTrigger,
      listener: (context, state) {
        _validateAndProceed(l10n);
      },
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🧪 Development Helper: Auto-Fill
              _buildAutoFillButton(themeColor),
              const SizedBox(height: 16),

              // 1. Contact Information Section
              _buildSectionWrapper(
                title: l10n.address_contact_title,
                icon: Icons.contact_phone_rounded,
                themeColor: themeColor,
                children: [
                  _buildLabeledField(
                    label: l10n.manual_client_name,
                    child: _buildTextFormField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      icon: Icons.person_outline_rounded,
                      themeColor: themeColor,
                      validator: (val) =>
                          InputValidator.validateEmpty(val, l10n: l10n),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLabeledField(
                    label: l10n.manual_client_phone,
                    child: _buildTextFormField(
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      themeColor: themeColor,
                      validator: (val) =>
                          InputValidator.validateEgyptianPhone(val, l10n: l10n),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 2. Main Address Section
              _buildSectionWrapper(
                title: l10n.address_details_title,
                icon: Icons.location_on_rounded,
                themeColor: themeColor,
                children: [
                  PropertyTypeSelector(
                    selectedType: _parsePropertyType(_selectedPropertyType),
                    onChanged: (type) {
                      setState(() => _selectedPropertyType = type.name);
                      _syncToState();
                    },
                  ),
                  const SizedBox(height: 16),

                  BlocProvider.value(
                    value: _geoCubit,
                    child: BlocBuilder<GeographicReferenceCubit, GeographicReferenceState>(
                      builder: (context, state) {
                        final locale = Localizations.localeOf(
                          context,
                        ).languageCode;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row for Governorate & City
                            Row(
                              children: [
                                // 1. Governorate Dropdown
                                Expanded(
                                  child: _buildLabeledField(
                                    label: l10n.address_governorate_label,
                                    child: DropdownButtonFormField<int>(
                                      isExpanded: true,
                                      dropdownColor: themeColor.cardBackground,
                                      initialValue: state.selectedGovernorateId,
                                      focusNode: _governorateFocus,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                        filled: true,
                                        fillColor: themeColor.background
                                            .withValues(alpha: 0.5),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: themeColor.unselectedItem
                                                .withValues(alpha: 0.1),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: themeColor.unselectedItem
                                                .withValues(alpha: 0.1),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: themeColor.primary,
                                          ),
                                        ),
                                      ),
                                      items: state.governorates
                                          .map(
                                            (g) => DropdownMenuItem<int>(
                                              value: g.id,
                                              child: Text(
                                                g.getName(locale),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  color: themeColor.textPrimary,
                                                  fontSize: 13,
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
                                                _selectedDistrictString = null;
                                                _isCustomDistrict = false;
                                                _customDistrictController
                                                    .clear();
                                                _districtController.clear();
                                              });
                                              _syncToState();
                                            },
                                      validator: (val) =>
                                          InputValidator.validateDropdownSelection(
                                            val?.toString(),
                                            l10n: l10n,
                                          ),
                                      hint: Text(
                                        state.isLoadingGovernorates
                                            ? 'تحميل...'
                                            : l10n.address_governorate_label,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: themeColor.secondaryText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // 2. City Dropdown
                                Expanded(
                                  child: _buildLabeledField(
                                    label: l10n.address_region_label,
                                    child: DropdownButtonFormField<int>(
                                      isExpanded: true,
                                      dropdownColor: themeColor.cardBackground,
                                      initialValue: state.selectedCityId,
                                      focusNode: _cityFocus,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                        filled: true,
                                        fillColor: themeColor.background
                                            .withValues(alpha: 0.5),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: themeColor.unselectedItem
                                                .withValues(alpha: 0.1),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: themeColor.unselectedItem
                                                .withValues(alpha: 0.1),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: themeColor.primary,
                                          ),
                                        ),
                                      ),
                                      items: state.cities
                                          .map(
                                            (c) => DropdownMenuItem<int>(
                                              value: c.id,
                                              child: Text(
                                                c.getName(locale),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  color: themeColor.textPrimary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged:
                                          (state.selectedGovernorateId ==
                                                  null ||
                                              state.isLoadingCities)
                                          ? null
                                          : (val) {
                                              _geoCubit.selectCity(val);
                                              setState(() {
                                                _selectedCity = state
                                                    .selectedCity
                                                    ?.getName(locale);
                                                _selectedDistrictString = null;
                                                _isCustomDistrict = false;
                                                _customDistrictController
                                                    .clear();
                                                _districtController.clear();
                                              });
                                              _syncToState();
                                            },
                                      validator: (val) =>
                                          InputValidator.validateDropdownSelection(
                                            val?.toString(),
                                            l10n: l10n,
                                          ),
                                      hint: Text(
                                        state.isLoadingCities
                                            ? 'تحميل...'
                                            : (state.selectedGovernorateId ==
                                                      null
                                                  ? l10n.address_select_governorate_first
                                                  : l10n.address_select_city),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: themeColor.secondaryText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // 3. District Dropdown / Custom Field
                            Builder(
                              builder: (context) {
                                final dbDistricts = state.districts
                                    .map((d) => d.getName(locale))
                                    .toList();
                                final staticDistricts =
                                    EgyptGeographicHierarchy.getDistricts(
                                      _selectedGovernorate ??
                                          state.selectedGovernorate?.getName(
                                            locale,
                                          ),
                                      _selectedCity ??
                                          state.selectedCity?.getName(locale),
                                    );
                                final availableDistricts =
                                    dbDistricts.isNotEmpty
                                    ? dbDistricts
                                    : staticDistricts;

                                if (availableDistricts.isNotEmpty) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabeledField(
                                        label: 'المنطقة / الحي',
                                        child: DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          dropdownColor:
                                              themeColor.cardBackground,
                                          initialValue:
                                              availableDistricts.contains(
                                                _selectedDistrictString,
                                              )
                                              ? _selectedDistrictString
                                              : null,
                                          focusNode: _districtFocus,
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 12,
                                                ),
                                            filled: true,
                                            fillColor: themeColor.background
                                                .withValues(alpha: 0.5),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: themeColor.unselectedItem
                                                    .withValues(alpha: 0.1),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: themeColor.unselectedItem
                                                    .withValues(alpha: 0.1),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: themeColor.primary,
                                              ),
                                            ),
                                          ),
                                          items: availableDistricts
                                              .map(
                                                (d) => DropdownMenuItem<String>(
                                                  value: d,
                                                  child: Text(
                                                    d,
                                                    style: TextStyle(
                                                      color: themeColor
                                                          .textPrimary,
                                                      fontSize: 13,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedDistrictString = val;
                                              _isCustomDistrict =
                                                  (val == 'أخرى');
                                              if (!_isCustomDistrict) {
                                                _districtController.text =
                                                    val ?? '';
                                              }
                                            });
                                            _syncToState();
                                          },
                                          validator: (val) =>
                                              InputValidator.validateDropdownSelection(
                                                val,
                                                l10n: l10n,
                                              ),
                                          hint: Text(
                                            state.isLoadingDistricts
                                                ? 'تحميل...'
                                                : 'اختر الحي / المنطقة',
                                            style: TextStyle(
                                              color: themeColor.secondaryText,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                      if (_isCustomDistrict) ...[
                                        const SizedBox(height: 12),
                                        _buildLabeledField(
                                          label: 'اسم الحي / المنطقة يدوياً',
                                          child: _buildTextFormField(
                                            controller:
                                                _customDistrictController,
                                            focusNode: _customDistrictFocus,
                                            icon:
                                                Icons.edit_location_alt_rounded,
                                            themeColor: themeColor,
                                            hint:
                                                'أدخل اسم الحي أو المنطقة بدقة',
                                            validator: (val) =>
                                                InputValidator.validateEmpty(
                                                  val,
                                                  l10n: l10n,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                }

                                return _buildLabeledField(
                                  label: 'المنطقة / الحي',
                                  child: _buildTextFormField(
                                    controller: _districtController,
                                    focusNode: _districtFocus,
                                    icon: Icons.location_city_rounded,
                                    themeColor: themeColor,
                                    hint: state.selectedCityId == null
                                        ? 'اختر المدينة أولاً'
                                        : 'أدخل اسم المنطقة أو الحي (مثال: الحي الأول)',
                                    validator: (val) =>
                                        InputValidator.validateEmpty(
                                          val,
                                          l10n: l10n,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabeledField(
                    label: 'تفاصيل العنوان والوصول',
                    child: _buildTextFormField(
                      controller: _addressDetailsController,
                      focusNode: _addressDetailsFocus,
                      icon: Icons.home_rounded,
                      themeColor: themeColor,
                      hint: 'اسم الشارع، رقم المبنى أو الفيلا، الدور، الشقة، وأي علامة مميزة',
                      maxLines: 3,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'يرجى إدخال تفاصيل العنوان';
                        }
                        if (val.trim().length < 5) {
                          return 'تفاصيل العنوان يجب ألا تقل عن 5 أحرف';
                        }
                        if (val.trim().length > 500) {
                          return 'تفاصيل العنوان يجب ألا تزيد عن 500 حرف';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildLabeledField(
                    label: 'رابط الموقع على الخريطة (Google Maps) - اختياري',
                    child: _buildTextFormField(
                      controller: _locationUrlController,
                      focusNode: _locationUrlFocus,
                      icon: Icons.map_rounded,
                      themeColor: themeColor,
                      hint: 'مثال: https://maps.google.com/?q=...',
                      keyboardType: TextInputType.url,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required ThemeColorExtension themeColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String hint = '',
    int maxLines = 1,
  }) {
    return BaseTextFormField(
      controller: controller,
      hint: hint,
      focusNode: focusNode,
      keyboardType: keyboardType ?? TextInputType.text,
      validator: validator,
      maxLines: maxLines,
      onChanged: (_) => _syncToState(),
      prefixIcon: Icon(
        icon,
        color: themeColor.primary.withValues(alpha: 0.7),
        size: 22,
      ),
      radius: 16,
      fillColor: themeColor.background.withValues(alpha: 0.5),
    );
  }


  Widget _buildAutoFillButton(ThemeColorExtension themeColor) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _autoFill(l10n),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeColor.primary,
              themeColor.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: themeColor.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_fix_high_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.booking_autofill_debug,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _autoFill(AppLocalizations l10n) {
    _nameController.text = l10n.role_client;
    _phoneController.text = "01012345678";
    _addressDetailsController.text = "90 Street, Building 10, Floor 2, Apt 5";

    final govs = _geoCubit.state.governorates;
    if (govs.isNotEmpty) {
      final firstGov = govs.first;
      _selectedGovernorate = firstGov.getName('ar');
      _geoCubit.selectGovernorate(firstGov.id).then((_) {
        final cities = _geoCubit.state.cities;
        if (cities.isNotEmpty) {
          final firstCity = cities.first;
          _selectedCity = firstCity.getName('ar');
          _geoCubit.selectCity(firstCity.id).then((_) {
            final districts = _geoCubit.state.districts;
            if (districts.isNotEmpty) {
              _geoCubit.selectDistrict(districts.first.id);
              _districtController.text = districts.first.getName('ar');
              _selectedDistrictString = districts.first.getName('ar');
            } else {
              final staticDistricts = EgyptGeographicHierarchy.getDistricts(
                _selectedGovernorate,
                _selectedCity,
              );
              if (staticDistricts.isNotEmpty) {
                _selectedDistrictString = staticDistricts.first;
                _districtController.text = staticDistricts.first;
              }
            }
            setState(() {});
            _syncToState();
          });
        } else {
          setState(() {});
          _syncToState();
        }
      });
    } else {
      _syncToState();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.booking_autofill_success),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
