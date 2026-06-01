import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/validators/input_validator.dart';
import 'package:shared/presentation/widget/custom_text_form_field/base_text_form_field.dart';
import 'package:shared/presentation/location/egypt_regions.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/booking_flow_state.dart';
import '../widgets/selection_components.dart';

/// Address step for the **customer** booking flow.
/// Renders saved addresses from the customer's profile + a manual form option.
/// In admin mode this page is skipped; the address is entered in [ManualClientPage].
class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController(text: '1');
  final _floorController = TextEditingController(text: '1');
  final _apartmentController = TextEditingController(text: '1');
  final _landmarkController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otherCityController = TextEditingController();

  String? _selectedGovernorate;
  String? _selectedCity;
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
    final state = context.read<BookingFlowCubit>().state;

    if (state.address != null && _selectedAddressIndex == null) {
      _selectedGovernorate = state.address!.governorate.isNotEmpty
          ? state.address!.governorate
          : null;
      _selectedCity = state.address!.city.isNotEmpty
          ? state.address!.city
          : null;
      _streetController.text = state.address!.street;
      _buildingController.text = state.address!.buildingNumber;
      _floorController.text = state.address!.floorNumber ?? '';
      _apartmentController.text = state.address!.apartmentNumber ?? '';
    }
    if (state.contact != null && _selectedPhoneIndex == null) {
      _phoneController.text = state.contact!.phone.firstOrNull ?? '';
    }
  }

  @override
  void dispose() {
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

  void _onChanged() {
    final state = context.read<BookingFlowCubit>().state;
    final l10n = AppLocalizations.of(context)!;
    final city = (_selectedCity == l10n.address_city_other)
        ? _otherCityController.text
        : (_selectedCity ?? '');

    final address = Address(
      governorate: _selectedGovernorate ?? '',
      city: city,
      street: _streetController.text,
      buildingNumber: _buildingController.text,
      floorNumber: _floorController.text,
      apartmentNumber: _apartmentController.text,
    );

    final contactName = state.currentUserProfile != null
        ? '${state.currentUserProfile!.user.firstName} ${state.currentUserProfile!.user.lastName}'
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
    final hasAddresses =
        state.currentUserProfile?.clientProfile?.addresses.isNotEmpty ?? false;
    final phones =
        state.currentUserProfile?.clientProfile?.phoneNumbers
            .map((e) => e.phoneNumber)
            .toList() ??
        [];
    final hasPhones = phones.isNotEmpty;

    if (_selectedAddressIndex == null && hasAddresses) {
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
    if (_selectedPhoneIndex == null && hasPhones) {
      setState(() => _showPhoneError = true);
      return;
    }
    if (_selectedPhoneIndex == -1) {
      if (!(_phoneFormKey.currentState?.validate() ?? false)) return;
    }

    if (_selectedAddressIndex != -1 && _selectedAddressIndex != null) {
      cubit.updateAddress(
        state
            .currentUserProfile!
            .clientProfile!
            .addresses[_selectedAddressIndex!],
      );
    }

    final selectedPhone = _selectedPhoneIndex == -1
        ? _phoneController.text
        : (hasPhones ? phones[_selectedPhoneIndex!] : _phoneController.text);

    cubit.updateContact(
      Contact(
        name: state.currentUserProfile?.user.firstName ?? '',
        phone: [selectedPhone],
      ),
    );

    cubit.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<BookingFlowCubit, BookingFlowState>(
      listenWhen: (prev, curr) =>
          prev.validateAddressTrigger != curr.validateAddressTrigger,
      listener: (context, state) => _validateAndProceed(l10n),
      child: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          final addressesList =
              state.currentUserProfile?.clientProfile?.addresses ?? [];
          final phoneList =
              state.currentUserProfile?.clientProfile?.phoneNumbers ?? [];
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                  fontFamily: 'Cairo',
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
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
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
    final governoratesList = EgyptRegions.getGovernorates(l10n);
    final citiesMap = EgyptRegions.getCitiesMap(l10n);

    return Form(
      key: _addressFormKey,
      child: Column(
        children: [
          _buildLabeledField(
            label: l10n.address_governorate_label,
            child: SelectionField(
              value: _selectedGovernorate,
              hint: l10n.address_governorate_label,
              onTap: () async {
                final result = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => SelectionSheet(
                    title: l10n.address_governorate_label,
                    items: governoratesList,
                    selectedValue: _selectedGovernorate,
                  ),
                );
                if (result != null) {
                  setState(() {
                    _selectedGovernorate = result;
                    _selectedCity = null;
                  });
                  _onChanged();
                }
              },
              validator: (val) =>
                  InputValidator.validateDropdownSelection(val, l10n: l10n),
            ),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: l10n.address_region_label,
            child: SelectionField(
              value: _selectedCity,
              hint: _selectedGovernorate == null
                  ? l10n.address_select_governorate_first
                  : l10n.address_select_city,
              onTap: _selectedGovernorate == null
                  ? () {}
                  : () async {
                      final result = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => SelectionSheet(
                          title: l10n.address_region_label,
                          items: citiesMap[_selectedGovernorate] ?? [],
                          selectedValue: _selectedCity,
                        ),
                      );
                      if (result != null) {
                        setState(() => _selectedCity = result);
                        _onChanged();
                      }
                    },
              validator: (val) =>
                  InputValidator.validateDropdownSelection(val, l10n: l10n),
            ),
          ),
          if (_selectedCity == l10n.address_city_other)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildLabeledField(
                label: l10n.address_city_other_label,
                child: BaseTextFormField(
                  controller: _otherCityController,
                  hint: l10n.address_city_other_hint,
                  radius: 16,
                  fillColor: themeColor.background.withValues(alpha: 0.5),
                  onChanged: (_) => _onChanged(),
                  validator: (val) =>
                      InputValidator.validateEmpty(val, l10n: l10n),
                ),
              ),
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
              validator: (val) => InputValidator.validateEmpty(val, l10n: l10n),
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
        ],
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
    final addressesList =
        state.currentUserProfile?.clientProfile?.addresses ?? [];
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
                    : Colors.white,
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
                            fontFamily: 'Cairo',
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
                                  fontFamily: 'Cairo',
                                  color: isSelected
                                      ? activeColor
                                      : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${addressesList[index].street}, ${l10n.address_building_label} ${addressesList[index].buildingNumber}',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            fontFamily: 'Cairo',
                            color: Colors.black.withValues(alpha: 0.5),
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
    final phones = state.currentUserProfile?.clientProfile?.phoneNumbers ?? [];
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
                    : Colors.white,
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
                            fontFamily: 'Cairo',
                            color: isSelected ? activeColor : Colors.black87,
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
              color: Colors.black.withValues(alpha: 0.6),
              fontFamily: 'Cairo',
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
                color: hasError ? Colors.red : themeColor.secondaryText,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
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
                  ? Colors.red.withValues(alpha: 0.05)
                  : Colors.white,
              errorBorderColor: Colors.red,
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

  void _fillAddressFields(dynamic address) {
    setState(() {
      _selectedGovernorate = address.governorate;
      _selectedCity = address.city;
    });
    _streetController.text = address.street;
    _buildingController.text = address.buildingNumber;
    _floorController.text = address.floorNumber ?? '';
    _apartmentController.text = address.apartmentNumber ?? '';
  }

  void _clearAddressFields() {
    setState(() {
      _selectedGovernorate = null;
      _selectedCity = null;
    });
    _streetController.clear();
    _buildingController.text = '1';
    _floorController.text = '1';
    _apartmentController.text = '1';
    _landmarkController.clear();
  }
}
