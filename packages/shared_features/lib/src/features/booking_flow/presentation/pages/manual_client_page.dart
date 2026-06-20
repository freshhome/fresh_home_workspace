import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/location/egypt_regions.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/booking_flow_state.dart';

import 'package:shared/presentation/validators/input_validator.dart';

import 'package:shared/presentation/widget/custom_text_form_field/base_text_form_field.dart';
import '../widgets/selection_components.dart';

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
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController();
  final _floorController = TextEditingController();
  final _apartmentController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _governorateFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _streetFocus = FocusNode();
  final _buildingFocus = FocusNode();
  final _floorFocus = FocusNode();
  final _apartmentFocus = FocusNode();

  String? _selectedGovernorate;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    final state = context.read<BookingFlowCubit>().state;
    _nameController.text = state.manualClientName ?? '';
    _phoneController.text = state.manualClientPhone ?? '';
    _selectedGovernorate = state.manualClientGovernorate;
    _selectedCity = state.manualClientCity;
    _streetController.text = state.manualClientStreet ?? '';
    _buildingController.text = state.manualClientBuilding ?? '';
    _floorController.text = state.manualClientFloor ?? '';
    _apartmentController.text = state.manualClientApartment ?? '';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();

    _nameFocus.dispose();
    _phoneFocus.dispose();
    _governorateFocus.dispose();
    _cityFocus.dispose();
    _streetFocus.dispose();
    _buildingFocus.dispose();
    _floorFocus.dispose();
    _apartmentFocus.dispose();
    super.dispose();
  }

  void _syncToState() {
    context.read<BookingFlowCubit>().updateManualClientData(
      name: _nameController.text,
      phone: _phoneController.text,
      governorate: _selectedGovernorate,
      city: _selectedCity,
      street: _streetController.text,
      building: _buildingController.text,
      floor: _floorController.text,
      apartment: _apartmentController.text,
    );
  }

  void _validateAndProceed(AppLocalizations l10n) {
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
      } else if (InputValidator.validateEmpty(_streetController.text) != null) {
        firstErrorFocus = _streetFocus;
      } else if (InputValidator.validateEmpty(_buildingController.text) !=
          null) {
        firstErrorFocus = _buildingFocus;
      } else if (InputValidator.validateEmpty(_floorController.text) != null) {
        firstErrorFocus = _floorFocus;
      } else if (InputValidator.validateEmpty(_apartmentController.text) !=
          null) {
        firstErrorFocus = _apartmentFocus;
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

    final governorates = EgyptRegions.getGovernorates(l10n);
    final citiesMap = EgyptRegions.getCitiesMap(l10n);

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
                  // Row for Governorate & City
                  Row(
                    children: [
                      Expanded(
                        child: _buildLabeledField(
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
                                  items: governorates,
                                  selectedValue: _selectedGovernorate,
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  _selectedGovernorate = result;
                                  _selectedCity = null;
                                });
                                _syncToState();
                              }
                            },
                            validator: (val) =>
                                InputValidator.validateDropdownSelection(val, l10n: l10n),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLabeledField(
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
                                      _syncToState();
                                    }
                                  },
                            validator: (val) =>
                                InputValidator.validateDropdownSelection(val, l10n: l10n),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _buildLabeledField(
                    label: l10n.address_street_label,
                    child: _buildTextFormField(
                      controller: _streetController,
                      focusNode: _streetFocus,
                      icon: Icons.edit_road_rounded,
                      themeColor: themeColor,
                      validator: (val) =>
                          InputValidator.validateEmpty(val, l10n: l10n),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Sub-Details (Building, Floor, Appt)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    decoration: BoxDecoration(
                      color: themeColor.background.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildNumericInputItem(
                            label: l10n.address_building_label,
                            controller: _buildingController,
                            focusNode: _buildingFocus,
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
                            focusNode: _floorFocus,
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
                            focusNode: _apartmentFocus,
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
  }) {
    return BaseTextFormField(
      controller: controller,
      hint: hint,
      focusNode: focusNode,
      keyboardType: keyboardType ?? TextInputType.text,
      validator: validator,
      onChanged: (_) => _syncToState(),
      prefixIcon: Icon(icon, color: themeColor.primary.withValues(alpha: 0.7), size: 22),
      radius: 16,
      fillColor: themeColor.background.withValues(alpha: 0.5),
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
    required FocusNode focusNode,
    required IconData icon,
    required ThemeColorExtension themeColor,
    required AppLocalizations l10n,
  }) {
    return FormField<String>(
      validator: (val) => InputValidator.validateEmpty(controller.text, l10n: l10n),
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
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (val) {
                state.didChange(val);
                _syncToState();
              },
              hint: "00",
              radius: 12,
              fillColor: hasError 
                  ? themeColor.error.withValues(alpha: 0.05) 
                  : themeColor.cardBackground,
              errorBorderColor: themeColor.error,
              enabledBorderColor: themeColor.unselectedItem.withValues(alpha: 0.1),
              focusedBorderColor: themeColor.primary,
            ),
          ],
        );
      },
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
            colors: [themeColor.primary, themeColor.primary.withValues(alpha: 0.8)],
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
            const Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 20),
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
    setState(() {
      _nameController.text = l10n.role_client;
      _phoneController.text = "01012345678";
      _selectedGovernorate = l10n.address_gov_cairo;
      _selectedCity = l10n.address_city_fifth_settlement;
      _streetController.text = "90 Street";
      _buildingController.text = "10";
      _floorController.text = "2";
      _apartmentController.text = "5";
    });
    _syncToState();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.booking_autofill_success),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
