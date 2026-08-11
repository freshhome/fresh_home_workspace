import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/tokens/app_design_tokens.dart';
import 'package:shared/presentation/widgets/address_v2/address_card_widget.dart';

/// Interactive Property Type Selector Widget for Address System V2 Form.
///
/// Allows the user to select between Residential (Home), Office, Commercial Store,
/// and Landmark property categories.
class PropertyTypeSelector extends StatelessWidget {
  /// The currently selected property type.
  final AddressPropertyType selectedType;

  /// Callback when a property type is selected.
  final ValueChanged<AddressPropertyType> onChanged;

  const PropertyTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>();
    final primaryColor = themeColor?.primary ?? const Color(0xFF1E3A8A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نوع العقار / المكان',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: AppDesignTokens.spacing.sm),
        Row(
          children: AddressPropertyType.values.map((type) {
            final isSelected = type == selectedType;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDesignTokens.spacing.xs),
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: 'اختيار ${_getPropertyTypeLabel(type)}',
                  child: InkWell(
                    onTap: () => onChanged(type),
                    borderRadius: AppDesignTokens.radius.borderRadiusMd,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: AppDesignTokens.spacing.sm + 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : const Color(0xFFF8FAFC),
                        borderRadius: AppDesignTokens.radius.borderRadiusMd,
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPropertyTypeIcon(type),
                            size: 20,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getPropertyTypeLabel(type),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getPropertyTypeIcon(AddressPropertyType type) {
    switch (type) {
      case AddressPropertyType.office:
        return Icons.business_rounded;
      case AddressPropertyType.commercial:
        return Icons.storefront_rounded;
      case AddressPropertyType.landmark:
        return Icons.location_city_rounded;
      case AddressPropertyType.residential:
        return Icons.home_rounded;
    }
  }

  String _getPropertyTypeLabel(AddressPropertyType type) {
    switch (type) {
      case AddressPropertyType.office:
        return 'مكتب';
      case AddressPropertyType.commercial:
        return 'شركة/محل';
      case AddressPropertyType.landmark:
        return 'علامة';
      case AddressPropertyType.residential:
        return 'منزل';
    }
  }
}
