import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';
import 'package:shared/presentation/dialogs/dialog_helper.dart';
import 'package:fresh_home_customer/features/my_orders/presentation/cubit/edit_order_cubit.dart';


class EditAddressScreen extends StatefulWidget {
  final Booking order;

  const EditAddressScreen({super.key, required this.order});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _districtController;
  late TextEditingController _streetController;
  late TextEditingController _buildingController;
  late TextEditingController _floorController;
  late TextEditingController _apartmentController;
  late TextEditingController _landmarkController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _otherCityController;

  late final GeographicReferenceCubit _geoCubit;

  String? _selectedGovernorate;
  String? _selectedCity;
  AddressPropertyType _propertyType = AddressPropertyType.residential;

  @override
  void initState() {
    super.initState();
    _geoCubit = GetIt.I<GeographicReferenceCubit>();

    _districtController = TextEditingController(
      text: widget.order.address.district,
    );
    _streetController = TextEditingController(
      text: widget.order.address.streetOrCompound,
    );
    _buildingController = TextEditingController(
      text: widget.order.address.buildingIdentifier,
    );
    _floorController = TextEditingController(
      text: widget.order.address.floor ?? '',
    );
    _apartmentController = TextEditingController(
      text: widget.order.address.apartmentOrUnit ?? '',
    );
    _landmarkController = TextEditingController(
      text: widget.order.address.landmark ?? '',
    );
    _nameController = TextEditingController(text: widget.order.contact.name);
    _phoneController = TextEditingController(
      text: widget.order.contact.phone.isNotEmpty
          ? widget.order.contact.phone.first
          : '',
    );
    _otherCityController = TextEditingController();

    _selectedGovernorate = widget.order.address.governorate.isNotEmpty
        ? widget.order.address.governorate
        : null;
    _selectedCity = widget.order.address.city.isNotEmpty
        ? widget.order.address.city
        : null;

    if (widget.order.address.propertyType != null) {
      if (widget.order.address.propertyType == 'office') {
        _propertyType = AddressPropertyType.office;
      } else if (widget.order.address.propertyType == 'commercial') {
        _propertyType = AddressPropertyType.commercial;
      } else if (widget.order.address.propertyType == 'landmark') {
        _propertyType = AddressPropertyType.landmark;
      }
    }

    _geoCubit.loadGovernorates().then((_) {
      if (widget.order.address.governorateId != null) {
        _geoCubit.selectGovernorate(widget.order.address.governorateId).then((_) {
          if (widget.order.address.cityId != null) {
            _geoCubit.selectCity(widget.order.address.cityId).then((_) {
              if (widget.order.address.districtId != null) {
                _geoCubit.selectDistrict(widget.order.address.districtId);
              }
            });
          }
        });
      } else if (_selectedGovernorate != null && _selectedGovernorate!.isNotEmpty) {
        try {
          final govs = _geoCubit.state.governorates;
          final matchedGov = govs.firstWhere(
            (g) => g.nameAr == _selectedGovernorate || g.nameEn == _selectedGovernorate,
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
                        (d) => d.nameAr == _districtController.text || d.nameEn == _districtController.text,
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
    _districtController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _landmarkController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otherCityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<EditOrderCubit, EditOrderState>(
      listener: (context, state) {
        if (state is EditOrderSuccess) {
          DialogHelper.showSuccess(
            context,
            message: l10n.general_operation_success,
            onOkPress: () => context.pop(true),
          );
        } else if (state is EditOrderFailure) {
          DialogHelper.showError(context, message: state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            l10n.address_details_title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: themeColor.textPrimary,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AddressFormComponents.buildSectionTitle(
                  l10n.address_details_title,
                  context,
                ),
                const SizedBox(height: 24),

                PropertyTypeSelector(
                  selectedType: _propertyType,
                  onChanged: (val) {
                    setState(() {
                      _propertyType = val;
                    });
                  },
                ),
                const SizedBox(height: 16),

                BlocProvider.value(
                  value: _geoCubit,
                  child: BlocBuilder<GeographicReferenceCubit, GeographicReferenceState>(
                    builder: (context, state) {
                      final locale = Localizations.localeOf(context).languageCode;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AddressFormComponents.buildLabeledField(
                            label: l10n.address_governorate_label,
                            context: context,
                            child: DropdownButtonFormField<int>(
                              value: state.selectedGovernorateId,
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: themeColor.textPrimary.withValues(alpha: 0.5),
                              ),
                              decoration: AddressFormComponents.inputDecoration(context),
                              items: state.governorates
                                  .map((g) => DropdownMenuItem<int>(
                                        value: g.id,
                                        child: Text(g.getName(locale)),
                                      ))
                                  .toList(),
                              onChanged: state.isLoadingGovernorates
                                  ? null
                                  : (val) {
                                      _geoCubit.selectGovernorate(val);
                                      setState(() {
                                        _selectedGovernorate = state.selectedGovernorate?.getName(locale);
                                        _selectedCity = null;
                                      });
                                    },
                              validator: (val) => InputValidator.validateDropdownSelection(
                                val?.toString(),
                                l10n: l10n,
                              ),
                              hint: Text(
                                state.isLoadingGovernorates
                                    ? 'تحميل...'
                                    : l10n.address_governorate_label,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          AddressFormComponents.buildLabeledField(
                            label: l10n.address_region_label,
                            context: context,
                            child: DropdownButtonFormField<int>(
                              value: state.selectedCityId,
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: themeColor.textPrimary.withValues(alpha: 0.5),
                              ),
                              decoration: AddressFormComponents.inputDecoration(context).copyWith(
                                fillColor: state.selectedGovernorateId == null
                                    ? themeColor.cardBackground.withValues(alpha: 0.5)
                                    : Colors.white,
                              ),
                              hint: Text(
                                state.isLoadingCities
                                    ? 'تحميل...'
                                    : (state.selectedGovernorateId == null
                                        ? l10n.address_select_governorate_first
                                        : l10n.address_select_city),
                                style: themeText.textBodyPrimary.copyWith(
                                  color: themeColor.textPrimary.withValues(alpha: 0.4),
                                ),
                              ),
                              items: state.cities
                                  .map((c) => DropdownMenuItem<int>(
                                        value: c.id,
                                        child: Text(c.getName(locale)),
                                      ))
                                  .toList(),
                              onChanged: (state.selectedGovernorateId == null || state.isLoadingCities)
                                  ? null
                                  : (val) {
                                      _geoCubit.selectCity(val);
                                      setState(() {
                                        _selectedCity = state.selectedCity?.getName(locale);
                                      });
                                    },
                              validator: (val) => InputValidator.validateDropdownSelection(
                                val?.toString(),
                                l10n: l10n,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (state.districts.isNotEmpty) ...[
                            AddressFormComponents.buildLabeledField(
                              label: 'المنطقة / الحي',
                              context: context,
                              child: DropdownButtonFormField<int>(
                                value: state.selectedDistrictId,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: themeColor.textPrimary.withValues(alpha: 0.5),
                                ),
                                decoration: AddressFormComponents.inputDecoration(context),
                                items: state.districts
                                    .map((d) => DropdownMenuItem<int>(
                                          value: d.id,
                                          child: Text(d.getName(locale)),
                                        ))
                                    .toList(),
                                onChanged: state.isLoadingDistricts
                                    ? null
                                    : (val) {
                                        _geoCubit.selectDistrict(val);
                                        if (val != null) {
                                          final dist = state.districts.firstWhere((d) => d.id == val);
                                          _districtController.text = dist.getName(locale);
                                        }
                                      },
                                validator: (val) => InputValidator.validateDropdownSelection(
                                  val?.toString(),
                                  l10n: l10n,
                                ),
                                hint: Text(
                                  state.isLoadingDistricts ? 'تحميل...' : 'اختر الحي / المنطقة',
                                ),
                              ),
                            ),
                          ] else ...[
                            AddressFormComponents.buildLabeledField(
                              label: 'المنطقة / الحي',
                              context: context,
                              child: BaseTextFormField(
                                controller: _districtController,
                                hint: state.selectedCityId == null
                                    ? 'اختر المدينة أولاً'
                                    : 'أدخل اسم المنطقة أو الحي',
                                enabled: state.selectedCityId != null,
                                radius: 12,
                                validator: (val) => InputValidator.validateEmpty(val, l10n: l10n),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                AddressFormComponents.buildLabeledField(
                  label: l10n.address_street_label,

                  context: context,
                  child: BaseTextFormField(
                    controller: _streetController,
                    hint: l10n.address_street_hint,
                    radius: 12,
                    validator: (val) =>
                        InputValidator.validateEmpty(val, l10n: l10n),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AddressFormComponents.buildLabeledField(
                        label: l10n.address_building_label,
                        context: context,
                        child: BaseTextFormField(
                          controller: _buildingController,
                          hint: '01',
                          radius: 12,
                          keyboardType: TextInputType.number,
                          validator: (val) =>
                              InputValidator.validateAddressNumeric(
                                val,
                                l10n: l10n,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AddressFormComponents.buildLabeledField(
                        label: l10n.address_floor_label,
                        context: context,
                        child: BaseTextFormField(
                          controller: _floorController,
                          hint: '02',
                          radius: 12,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AddressFormComponents.buildLabeledField(
                        label: l10n.address_apartment_label,
                        context: context,
                        child: BaseTextFormField(
                          controller: _apartmentController,
                          hint: '03',
                          radius: 12,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                AddressFormComponents.buildLabeledField(
                  label: 'علامة مميزة (اختياري)',
                  context: context,
                  child: BaseTextFormField(
                    controller: _landmarkController,
                    hint: 'علامة مميزة كمسجد أو محل مشهور',
                    radius: 12,
                  ),
                ),
                const SizedBox(height: 32),

                AddressFormComponents.buildSectionTitle(
                  l10n.address_contact_title,
                  context,
                ),
                const SizedBox(height: 24),

                AddressFormComponents.buildLabeledField(
                  label: l10n.address_full_name_label,
                  context: context,
                  child: BaseTextFormField(
                    controller: _nameController,
                    hint: l10n.address_full_name_hint,
                    radius: 12,
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: themeColor.primary,
                      size: 22,
                    ),
                    validator: (val) =>
                        InputValidator.validateEmpty(val, l10n: l10n),
                  ),
                ),
                const SizedBox(height: 16),

                AddressFormComponents.buildLabeledField(
                  label: l10n.address_phone_label,
                  context: context,
                  child: BaseTextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    hint: '01xxxxxxxxx',
                    radius: 12,
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: themeColor.primary,
                      size: 22,
                    ),
                    validator: (val) =>
                        InputValidator.validateEgyptianPhone(val, l10n: l10n),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BlocBuilder<EditOrderCubit, EditOrderState>(
            builder: (context, state) {
              return ElevatedButton(
                onPressed: state is EditOrderLoading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          final locale = Localizations.localeOf(context).languageCode;
                          final geoState = _geoCubit.state;
                          final selectedGov = geoState.selectedGovernorate;
                          final selectedCity = geoState.selectedCity;
                          final selectedDistrict = geoState.selectedDistrict;

                          final govName = selectedGov?.getName(locale) ?? selectedGov?.nameAr ?? _selectedGovernorate ?? '';
                          final cityName = selectedCity?.getName(locale) ?? selectedCity?.nameAr ?? _selectedCity ?? '';
                          final districtName = selectedDistrict?.getName(locale) ??
                              (_districtController.text.trim().isNotEmpty ? _districtController.text.trim() : cityName);

                          context.read<EditOrderCubit>().updateOrderAddress(
                            orderId: widget.order.id,
                            address: Address(
                              id: widget.order.address.id,
                              userId: widget.order.address.userId,
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
                              landmark: _landmarkController.text,
                              propertyType: _propertyType.name,
                              createdAt: widget.order.address.createdAt,
                              updatedAt: DateTime.now(),
                            ),
                            contact: Contact(
                              name: _nameController.text,
                              phone: [_phoneController.text],
                            ),
                          );
                        }

                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: state is EditOrderLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        l10n.general_save,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
