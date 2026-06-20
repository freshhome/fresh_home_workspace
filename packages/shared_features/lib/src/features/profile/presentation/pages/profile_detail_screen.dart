import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/address_card.dart';

// New: Premium Custom SnackBar
class PremiumSnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    final themeColor = context.themeColor;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(16),
          height: 80,
          decoration: BoxDecoration(
            color: isError ? Colors.red[400] : themeColor.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isError ? Colors.red : themeColor.primary)
                    .withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isError ? l10n.general_error : l10n.general_success,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  late TextEditingController _emailController;
  late TextEditingController _mainPhoneController;
  String _selectedGender = 'unspecified';

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();

    _emailController = TextEditingController();
    _mainPhoneController = TextEditingController();

    context.read<ProfileCubit>().load();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();

    _emailController.dispose();
    _mainPhoneController.dispose();
    super.dispose();
  }

  void _initializeControllers(UserProfile profile) {
    if (_firstNameController.text.isEmpty)
      _firstNameController.text = profile.firstName;
    if (_lastNameController.text.isEmpty)
      _lastNameController.text = profile.lastName;

    if (_emailController.text.isEmpty)
      _emailController.text = profile.email;
    _selectedGender = profile.gender;

    final currentPhones = profile.phoneNumbers;
    final primaryPhone = currentPhones.isNotEmpty
        ? currentPhones
              .firstWhere((p) => p.isPrimary, orElse: () => currentPhones.first)
              .phoneNumber
        : '';
    if (_mainPhoneController.text.isEmpty && primaryPhone.isNotEmpty) {
      _mainPhoneController.text = primaryPhone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeColor = context.themeColor;

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        title: Text(
          l10n.profile_title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeColor.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: themeColor.textPrimary,
            size: 20,
          ),
          onPressed: () => context.go(GetIt.I<NavigationConfig>().initialPath),
        ),
        backgroundColor: themeColor.cardBackground,
        elevation: 0,
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            _initializeControllers(state.profile);
            if (ModalRoute.of(context)?.isCurrent == true) {
              // PremiumSnackBar.show(context, l10n.general_success, isError: false);
            }
          } else if (state is ProfileError) {
            print("===================");
            print('ProfileCubit ProfileError: ${state.failure.message}');
            print("===================");
            PremiumSnackBar.show(context, state.failure.message);
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return Center(
              child: CircularProgressIndicator(color: themeColor.primary),
            );
          }

          if (state is ProfileLoaded) {
            return _buildProfileContent(state.profile, state);
          } else if (state is ProfileError) {
            final profile = state.profile;
            if (profile != null) {
              return _buildProfileContent(profile, state);
            }
            return _buildErrorView(context, state.failure.message);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProfileContent(UserProfile profile, ProfileState state) {
    final l10n = AppLocalizations.of(context)!;
    final themeColor = context.themeColor;
    final additionalPhones = profile.phoneNumbers;
    final addresses = profile is CustomerProfile ? profile.addresses : const <Address>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Section
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: themeColor.primary.withValues(
                    alpha: 0.1,
                  ),
                  backgroundImage: profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 60,
                          color: themeColor.primary,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: themeColor.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // General Info Section
          _buildSectionHeader(l10n.profile_title),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColor.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.fromBorderSide(themeColor.cardBorder),
              ),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _firstNameController,
                    label: l10n.profile_first_name,
                    icon: Icons.person_outline_rounded,
                    validator: (value) =>
                        value!.isEmpty ? l10n.validation_required : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _lastNameController,
                    label: l10n.profile_last_name,
                    icon: Icons.person_outline_rounded,
                    validator: (value) =>
                        value!.isEmpty ? l10n.validation_required : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: l10n.login_email_label,
                    icon: Icons.email_outlined,
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _mainPhoneController,
                    label: l10n.address_phone_label,
                    icon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        InputValidator.validateEgyptianPhone(value, l10n: l10n),
                  ),
                  const SizedBox(height: 16),
                  // Gender Selection
                  StatefulBuilder(
                    builder: (context, setInnerState) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.fromBorderSide(themeColor.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.wc_rounded,
                              color: themeColor.primary.withValues(
                                alpha: 0.7,
                              ),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.profile_gender_label,
                              style: TextStyle(
                                color: themeColor.secondaryText,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            DropdownButton<String>(
                              value: _selectedGender,
                              underline: const SizedBox(),
                              dropdownColor: themeColor.cardBackground,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: themeColor.textPrimary,
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  setInnerState(() => _selectedGender = val);
                                  setState(() {});
                                }
                              },
                              items: [
                                DropdownMenuItem(
                                  value: 'unspecified',
                                  child: Text(
                                    l10n.gender_unspecified,
                                    style: TextStyle(color: themeColor.textPrimary),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'male',
                                  child: Text(
                                    l10n.gender_male,
                                    style: TextStyle(color: themeColor.textPrimary),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'female',
                                  child: Text(
                                    l10n.gender_female,
                                    style: TextStyle(color: themeColor.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<ProfileCubit>().updateProfileInfo(
                    firstName: _firstNameController.text,
                    lastName: _lastNameController.text,
                    phone: _mainPhoneController.text,
                    gender: _selectedGender,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.general_save,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Technician Section
          if (profile is TechnicianProfile) ...[
            _buildTechnicianSection(profile),
            const SizedBox(height: 32),
          ],

          // Phone Numbers Section
          _buildSectionHeader(
            l10n.phone_section_title,
            onAdd: () => _showPhoneDialog(context, additionalPhones),
          ),
          const SizedBox(height: 12),
          if (additionalPhones.isEmpty)
            _buildEmptyState(l10n.profile_saved_phones)
          else
            Column(
              children: additionalPhones
                  .map(
                    (phone) =>
                        _buildPhoneItem(context, phone, additionalPhones),
                  )
                  .toList(),
            ),
          const SizedBox(height: 32),

          // Addresses Section
          _buildSectionHeader(
            l10n.address_section_title,
            onAdd: () => _showAddressBottomSheet(context),
          ),
          const SizedBox(height: 12),
          if (addresses.isEmpty)
            _buildEmptyState(l10n.profile_saved_addresses)
          else
            Column(
              children: addresses.asMap().entries.map((entry) {
                return AddressCard(
                  address: entry.value,
                  onEdit: () => _showAddressBottomSheet(
                    context,
                    address: entry.value,
                    index: entry.key,
                  ),
                  onDelete: () =>
                      context.read<ProfileCubit>().deleteAddress(entry.key),
                );
              }).toList(),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAdd}) {
    final themeColor = context.themeColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: themeColor.textPrimary,
          ),
        ),
        if (onAdd != null)
          TextButton.icon(
            onPressed: onAdd,
            icon: Icon(
              Icons.add_circle_outline_rounded,
              size: 20,
              color: themeColor.primary,
            ),
            label: Text(
              AppLocalizations.of(context)!.general_add,
              style: TextStyle(
                color: themeColor.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    final themeColor = context.themeColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(themeColor.cardBorder),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: themeColor.secondaryText, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildPhoneItem(
    BuildContext context,
    Phone phone,
    List<Phone> currentPhones,
  ) {
    final themeColor = context.themeColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.fromBorderSide(themeColor.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_android_rounded, size: 20, color: themeColor.secondaryText),
          const SizedBox(width: 12),
          Text(
            phone.phoneNumber,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: themeColor.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              final updated = List<Phone>.from(currentPhones)..remove(phone);
              context.read<ProfileCubit>().updatePhones(updated);
            },
            icon: const Icon(
              Icons.remove_circle_outline_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _showPhoneDialog(BuildContext context, List<Phone> currentPhones) {
    final phoneController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final phoneFormKey = GlobalKey<FormState>();
    final themeColor = context.themeColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeColor.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.phone_add_button,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeColor.textPrimary,
          ),
        ),
        content: Form(
          key: phoneFormKey,
          child: BaseTextFormField(
            controller: phoneController,
            hint: '01xxxxxxxxx',
            keyboardType: TextInputType.phone,
            validator: (val) =>
                InputValidator.validateEgyptianPhone(val, l10n: l10n),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.general_cancel,
              style: TextStyle(color: themeColor.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (phoneFormKey.currentState!.validate()) {
                this.context.read<ProfileCubit>().addPhoneNumber(
                  phoneController.text,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              l10n.general_add,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressBottomSheet(
    BuildContext context, {
    Address? address,
    int? index,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final themeColor = context.themeColor;

    // Governorate & City Data
    final governoratesList = [l10n.address_gov_cairo, l10n.address_gov_giza];
    final Map<String, List<String>> citiesMap = {
      l10n.address_gov_cairo: [
        l10n.address_city_zamalek,
        l10n.address_city_garden_city,
        l10n.address_city_maadi,
        l10n.address_city_heliopolis,
        l10n.address_city_fifth_settlement,
        l10n.address_city_new_cairo,
        l10n.address_city_rehab,
        l10n.address_city_madinaty,
        l10n.address_city_nasr_city,
        l10n.address_city_mokattam,
        l10n.address_city_shorouk,
        l10n.address_city_other,
      ],
      l10n.address_gov_giza: [
        l10n.address_city_zayed,
        l10n.address_city_october,
        l10n.address_city_mohandessin,
        l10n.address_city_dokki,
        l10n.address_city_agouza,
        l10n.address_city_hadayek_ahram,
        l10n.address_city_haram,
        l10n.address_city_faisal,
        l10n.address_city_imbaba,
        l10n.address_city_other,
      ],
    };

    // Determine initial values
    String? initialGov = address?.governorate;
    String? initialCity = address?.city;
    bool isCityInList =
        initialGov != null &&
        (citiesMap[initialGov]?.contains(initialCity) ?? false);

    // If city is not in list (manual entry), set it to "Other" for dropdown and put value in otherController
    String? dropdownCity = isCityInList
        ? initialCity
        : (initialGov != null ? l10n.address_city_other : null);
    String otherCityValue = !isCityInList && initialCity != null
        ? initialCity
        : "";

    // Address Controllers
    final streetController = TextEditingController(text: address?.street);
    final buildingController = TextEditingController(
      text: address?.buildingNumber,
    );
    final floorController = TextEditingController(text: address?.floorNumber);
    final apartmentController = TextEditingController(
      text: address?.apartmentNumber,
    );
    final otherCityController = TextEditingController(text: otherCityValue);

    final addressFormKey = GlobalKey<FormState>();

    String? selectedGov = initialGov;
    String? selectedCity = dropdownCity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeColor.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: addressFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: themeColor.secondaryText.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    address == null
                        ? l10n.add_new_address
                        : l10n.address_edit_title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: themeColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Governorate
                  DropdownButtonFormField<String>(
                    dropdownColor: themeColor.cardBackground,
                    initialValue: governoratesList.contains(selectedGov)
                        ? selectedGov
                        : null,
                    decoration: _inputDecoration(l10n.address_governorate),
                    items: governoratesList
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g, style: TextStyle(color: themeColor.textPrimary)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedGov = val;
                        selectedCity = null;
                      });
                    },
                    validator: (val) =>
                        InputValidator.validateDropdownSelection(
                          val,
                          l10n: l10n,
                        ),
                    hint: Text(l10n.address_governorate, style: TextStyle(color: themeColor.secondaryText)),
                  ),
                  const SizedBox(height: 12),

                  // City
                  DropdownButtonFormField<String>(
                    dropdownColor: themeColor.cardBackground,
                    initialValue:
                        (selectedGov != null &&
                            (citiesMap[selectedGov]?.contains(selectedCity) ??
                                false))
                        ? selectedCity
                        : null,
                    decoration: _inputDecoration(
                      selectedGov == null
                          ? l10n.address_select_governorate_first
                          : l10n.address_city,
                    ),
                    items:
                        (selectedGov != null
                                ? citiesMap[selectedGov] ?? []
                                : [])
                            .map<DropdownMenuItem<String>>(
                              (c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(c, style: TextStyle(color: themeColor.textPrimary)),
                              ),
                            )
                            .toList(),
                    onChanged: selectedGov == null
                        ? null
                        : (val) {
                            setModalState(() => selectedCity = val);
                          },
                    validator: (val) =>
                        InputValidator.validateDropdownSelection(
                          val,
                          l10n: l10n,
                        ),
                    hint: Text(l10n.address_city, style: TextStyle(color: themeColor.secondaryText)),
                    disabledHint: Text(l10n.address_select_governorate_first, style: TextStyle(color: themeColor.secondaryText)),
                  ),
                  const SizedBox(height: 12),

                  if (selectedCity == l10n.address_city_other)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BaseTextFormField(
                        controller: otherCityController,
                        hint: l10n.address_city_other_label,
                        validator: (val) =>
                            InputValidator.validateEmpty(val, l10n: l10n),
                      ),
                    ),

                  // Street
                  BaseTextFormField(
                    controller: streetController,
                    hint: l10n.address_street,
                    validator: (val) =>
                        InputValidator.validateEmpty(val, l10n: l10n),
                  ),
                  const SizedBox(height: 12),

                  // Building, Floor, Apartment
                  Row(
                    children: [
                      Expanded(
                        child: BaseTextFormField(
                          controller: buildingController,
                          hint: l10n.address_building_number,
                          keyboardType: TextInputType.number,
                          validator: (val) =>
                              InputValidator.validateAddressNumeric(
                                val,
                                l10n: l10n,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BaseTextFormField(
                          controller: floorController,
                          hint: l10n.address_floor_number,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BaseTextFormField(
                          controller: apartmentController,
                          hint: l10n.address_apartment_number,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (addressFormKey.currentState!.validate()) {
                          final finalCity =
                              selectedCity == l10n.address_city_other
                              ? otherCityController.text
                              : selectedCity!;

                          final newAddress = Address(
                            id: address?.id,
                            governorate: selectedGov!,
                            city: finalCity,
                            street: streetController.text,
                            buildingNumber: buildingController.text,
                            floorNumber: floorController.text,
                            apartmentNumber: apartmentController.text,
                          );

                          if (address == null) {
                            this.context.read<ProfileCubit>().addAddress(
                              newAddress,
                            );
                          } else {
                            this.context.read<ProfileCubit>().updateAddress(
                              index!,
                              newAddress,
                            );
                          }
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        address == null ? l10n.general_add : l10n.general_save,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final themeColor = context.themeColor;
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: themeColor.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: themeColor.secondaryText, fontSize: 13),
        prefixIcon: Icon(
          icon,
          color: themeColor.primary.withValues(alpha: 0.7),
          size: 20,
        ),
        filled: true,
        fillColor: readOnly ? themeColor.nestedCardBackground : themeColor.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColor.cardBorder.color),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColor.cardBorder.color),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: themeColor.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context)!;
    final themeColor = context.themeColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 80, color: Colors.red[300]),
            const SizedBox(height: 24),
            Text(
              l10n.general_error,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeColor.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: themeColor.secondaryText, fontSize: 15),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () => context.read<ProfileCubit>().load(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.general_retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final themeColor = context.themeColor;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: themeColor.secondaryText),
      filled: true,
      fillColor: themeColor.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeColor.cardBorder.color),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeColor.cardBorder.color),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: themeColor.primary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildTechnicianSection(UserProfile profile) {
    if (profile is! TechnicianProfile) return const SizedBox.shrink();
    final tech = profile;
    final l10n = AppLocalizations.of(context)!;
    final themeColor = context.themeColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.tech_profile_title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeColor.textPrimary,
              ),
            ),
            if (tech.isVerified)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      l10n.tech_profile_verified,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTechStatCard(
                title: l10n.tech_profile_rating,
                value: tech.rating.toStringAsFixed(1),
                icon: Icons.star_rounded,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTechStatCard(
                title: l10n.tech_profile_completed_jobs,
                value: tech.completedJobs.toString(),
                icon: Icons.task_alt_rounded,
                color: themeColor.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.fromBorderSide(themeColor.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: themeColor.secondaryText,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.tech_profile_bio,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: themeColor.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tech.bio ?? l10n.tech_profile_bio_empty,
                style: TextStyle(
                  color: tech.bio != null ? themeColor.textPrimary : themeColor.secondaryText,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.tech_profile_skills_capacity,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: themeColor.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildCapacityPoolsSection(profile),
      ],
    );
  }

  Widget _buildCapacityPoolsSection(UserProfile profile) {
    if (profile is! TechnicianProfile) return const SizedBox.shrink();
    final tech = profile;
    final pools = tech.capacityPools;
    final l10n = AppLocalizations.of(context)!;
    final themeColor = context.themeColor;

    if (pools.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: themeColor.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.fromBorderSide(themeColor.cardBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber[600],
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.tech_profile_skills_empty_admin,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: themeColor.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.tech_profile_skills_empty_admin_desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: themeColor.secondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: pools.map((pool) {
        final poolSkills = tech.technicianSkills
            .where((s) => s.capacityPoolId == pool.id && s.isActive)
            .toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.fromBorderSide(themeColor.cardBorder),
            boxShadow: [
              themeColor.cardShadow,
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeColor.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.work_history_rounded,
                      color: themeColor.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pool.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: themeColor.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: themeColor.cardBorder.color),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.tech_profile_daily_capacity,
                    style: TextStyle(
                      fontSize: 13,
                      color: themeColor.secondaryText,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.tech_profile_tasks_per_day(pool.maxDailyCapacity.toString()),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.tech_profile_services_provided,
                style: TextStyle(
                  fontSize: 13,
                  color: themeColor.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              if (poolSkills.isEmpty)
                Text(
                  l10n.tech_profile_skills_empty,
                  style: TextStyle(
                    color: themeColor.secondaryText,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: poolSkills.map((skill) {
                    final subServiceName = tech.subServiceNames[skill.subServiceId] ?? skill.subServiceId;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: themeColor.nestedCardBackground,
                        border: Border.fromBorderSide(themeColor.cardBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: themeColor.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            subServiceName,
                            style: TextStyle(
                              color: themeColor.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTechStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final themeColor = context.themeColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(themeColor.cardBorder),
        boxShadow: [
          themeColor.cardShadow,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: themeColor.textPrimary,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: themeColor.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
