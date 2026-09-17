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
  late TextEditingController _addressDetailsController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _otherCityController;

  late final GeographicReferenceCubit _geoCubit;

  String? _selectedGovernorate;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _geoCubit = GetIt.I<GeographicReferenceCubit>();

    _districtController = TextEditingController(
      text: widget.order.address.district,
    );
    _addressDetailsController = TextEditingController(
      text: widget.order.address.addressDetails,
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

    _geoCubit.loadGovernorates().then((_) {
      if (widget.order.address.governorateId != null) {
        _geoCubit.selectGovernorate(widget.order.address.governorateId).then((
          _,
        ) {
          if (widget.order.address.cityId != null) {
            _geoCubit.selectCity(widget.order.address.cityId).then((_) {
              if (widget.order.address.districtId != null) {
                _geoCubit.selectDistrict(widget.order.address.districtId);
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
    _districtController.dispose();
    _addressDetailsController.dispose();
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
                const SizedBox(height: 16),

                BlocProvider.value(
                  value: _geoCubit,
                  child:
                      BlocBuilder<
                        GeographicReferenceCubit,
                        GeographicReferenceState
                      >(
                        builder: (context, state) {
                          final locale = Localizations.localeOf(
                            context,
                          ).languageCode;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AddressFormComponents.buildLabeledField(
                                label: l10n.address_governorate_label,
                                context: context,
                                child: DropdownButtonFormField<int>(
                                  initialValue: state.selectedGovernorateId,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: themeColor.textPrimary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  decoration:
                                      AddressFormComponents.inputDecoration(
                                        context,
                                      ),
                                  items: state.governorates
                                      .map(
                                        (g) => DropdownMenuItem<int>(
                                          value: g.id,
                                          child: Text(g.getName(locale)),
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
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              AddressFormComponents.buildLabeledField(
                                label: l10n.address_region_label,
                                context: context,
                                child: DropdownButtonFormField<int>(
                                  initialValue: state.selectedCityId,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: themeColor.textPrimary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  decoration:
                                      AddressFormComponents.inputDecoration(
                                        context,
                                      ).copyWith(
                                        fillColor:
                                            state.selectedGovernorateId == null
                                            ? themeColor.cardBackground
                                                  .withValues(alpha: 0.5)
                                            : Colors.white,
                                      ),
                                  hint: Text(
                                    state.isLoadingCities
                                        ? 'تحميل...'
                                        : (state.selectedGovernorateId == null
                                              ? l10n.address_select_governorate_first
                                              : l10n.address_select_city),
                                    style: themeText.textBodyPrimary.copyWith(
                                      color: themeColor.textPrimary.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  items: state.cities
                                      .map(
                                        (c) => DropdownMenuItem<int>(
                                          value: c.id,
                                          child: Text(c.getName(locale)),
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
                                            _selectedCity = state.selectedCity
                                                ?.getName(locale);
                                          });
                                        },
                                  validator: (val) =>
                                      InputValidator.validateDropdownSelection(
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
                                    initialValue: state.selectedDistrictId,
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: themeColor.textPrimary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    decoration:
                                        AddressFormComponents.inputDecoration(
                                          context,
                                        ),
                                    items: state.districts
                                        .map(
                                          (d) => DropdownMenuItem<int>(
                                            value: d.id,
                                            child: Text(d.getName(locale)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: state.isLoadingDistricts
                                        ? null
                                        : (val) {
                                            _geoCubit.selectDistrict(val);
                                            if (val != null) {
                                              final dist = state.districts
                                                  .firstWhere(
                                                    (d) => d.id == val,
                                                  );
                                              _districtController.text = dist
                                                  .getName(locale);
                                            }
                                          },
                                    validator: (val) =>
                                        InputValidator.validateDropdownSelection(
                                          val?.toString(),
                                          l10n: l10n,
                                        ),
                                    hint: Text(
                                      state.isLoadingDistricts
                                          ? 'تحميل...'
                                          : 'اختر الحي / المنطقة',
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
                        },
                      ),
                ),
                const SizedBox(height: 16),

                AddressFormComponents.buildLabeledField(
                  label: 'تفاصيل العنوان والوصول',
                  context: context,
                  child: BaseTextFormField(
                    controller: _addressDetailsController,
                    hint: 'اسم الشارع، رقم المبنى، الدور، الشقة، وأي علامة مميزة',
                    radius: 12,
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
                          final locale = Localizations.localeOf(
                            context,
                          ).languageCode;
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
                              addressDetails: _addressDetailsController.text.trim(),
                              locationUrl: widget.order.address.locationUrl,
                              latitude: widget.order.address.latitude,
                              longitude: widget.order.address.longitude,
                              createdAt: widget.order.address.createdAt,
                              updatedAt: DateTime.now(),
                            ),
                            contact: Contact(
                              name: _nameController.text.trim(),
                              phone: [_phoneController.text.trim()],
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
