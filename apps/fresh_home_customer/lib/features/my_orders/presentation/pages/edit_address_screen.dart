import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/widget/custom_text_form_field/base_text_form_field.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:fresh_home_customer/features/my_orders/presentation/cubit/edit_order_cubit.dart';
import 'package:shared/presentation/dialogs/dialog_helper.dart';
import 'package:shared/presentation/widget/address_form_components.dart';
import 'package:shared/presentation/location/egypt_regions.dart';
import 'package:shared/presentation/validators/input_validator.dart';
import 'package:go_router/go_router.dart';

class EditAddressScreen extends StatefulWidget {
  final Booking order;

  const EditAddressScreen({super.key, required this.order});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _streetController;
  late TextEditingController _buildingController;
  late TextEditingController _floorController;
  late TextEditingController _apartmentController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _otherCityController;

  String? _selectedGovernorate;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _streetController = TextEditingController(
      text: widget.order.address.street,
    );
    _buildingController = TextEditingController(
      text: widget.order.address.buildingNumber,
    );
    _floorController = TextEditingController(
      text: widget.order.address.floorNumber,
    );
    _apartmentController = TextEditingController(
      text: widget.order.address.apartmentNumber,
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
  }

  @override
  void dispose() {
    _streetController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
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

    final List<String> governoratesList = EgyptRegions.getGovernorates(l10n);
    final Map<String, List<String>> citiesMap = EgyptRegions.getCitiesMap(l10n);

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

                AddressFormComponents.buildLabeledField(
                  label: l10n.address_governorate_label,
                  context: context,
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        governoratesList.contains(_selectedGovernorate)
                        ? _selectedGovernorate
                        : null,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: themeColor.textPrimary.withValues(alpha: 0.5),
                    ),
                    decoration: AddressFormComponents.inputDecoration(context),
                    items: governoratesList
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedGovernorate = val;
                        _selectedCity = null;
                      });
                    },
                    validator: (val) =>
                        InputValidator.validateDropdownSelection(
                          val,
                          l10n: l10n,
                        ),
                  ),
                ),
                const SizedBox(height: 16),

                AddressFormComponents.buildLabeledField(
                  label: l10n.address_region_label,
                  context: context,
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        _selectedGovernorate != null &&
                            (citiesMap[_selectedGovernorate]?.contains(
                                  _selectedCity,
                                ) ??
                                false)
                        ? _selectedCity
                        : null,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: themeColor.textPrimary.withValues(alpha: 0.5),
                    ),
                    decoration: AddressFormComponents.inputDecoration(context)
                        .copyWith(
                          fillColor: _selectedGovernorate == null
                              ? themeColor.cardBackground.withValues(alpha: 0.5)
                              : Colors.white,
                        ),
                    hint: Text(
                      _selectedGovernorate == null
                          ? l10n.address_select_governorate_first
                          : l10n.address_select_city,
                      style: themeText.textBodyPrimary.copyWith(
                        color: themeColor.textPrimary.withValues(alpha: 0.4),
                      ),
                    ),
                    items:
                        (_selectedGovernorate != null
                                ? citiesMap[_selectedGovernorate] ?? []
                                : [])
                            .map<DropdownMenuItem<String>>(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                    onChanged: _selectedGovernorate == null
                        ? null
                        : (val) {
                            setState(() {
                              _selectedCity = val;
                            });
                          },
                    validator: (val) =>
                        InputValidator.validateDropdownSelection(
                          val,
                          l10n: l10n,
                        ),
                  ),
                ),

                if (_selectedCity == l10n.address_city_other)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: AddressFormComponents.buildLabeledField(
                      label: l10n.address_city_other_label,
                      context: context,
                      child: BaseTextFormField(
                        controller: _otherCityController,
                        hint: l10n.address_city_other_hint,
                        radius: 12,
                        validator: (val) =>
                            InputValidator.validateEmpty(val, l10n: l10n),
                      ),
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
                        label: l10n.address_apartment_label,
                        context: context,
                        child: BaseTextFormField(
                          controller: _apartmentController,
                          hint: '03',
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
                  ],
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
                          final city =
                              (_selectedCity == l10n.address_city_other)
                              ? _otherCityController.text
                              : (_selectedCity ?? '');

                          context.read<EditOrderCubit>().updateOrderAddress(
                            orderId: widget.order.id,
                            address: Address(
                              governorate: _selectedGovernorate ?? '',
                              city: city,
                              street: _streetController.text,
                              buildingNumber: _buildingController.text,
                              floorNumber: _floorController.text,
                              apartmentNumber: _apartmentController.text,
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
