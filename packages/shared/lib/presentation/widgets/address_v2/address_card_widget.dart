import 'package:flutter/material.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/theme/tokens/app_design_tokens.dart';

/// Property Type Enum representing supported property categories in Address V2.
enum AddressPropertyType {
  residential,
  office,
  commercial,
  landmark,
}

/// Generic, highly reusable Address Card Widget for Address System V2.
///
/// Designed to be presentation-only, screen-agnostic, and fully compatible
/// across Customer, Staff, and Admin applications.
class AddressCardWidget extends StatelessWidget {
  /// The Address domain entity to display.
  final Address address;

  /// Whether this address card is currently selected.
  final bool isSelected;

  /// Whether this address card is in a disabled state.
  final bool isDisabled;

  /// Optional explicit property type. Defaults to [AddressPropertyType.residential].
  final AddressPropertyType propertyType;

  /// Optional custom title label (e.g. "Home", "Work"). If null, defaults to property type.
  final String? customTitle;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when the "Set as Primary" action is tapped.
  final VoidCallback? onSetPrimary;

  /// Callback when the Edit button is tapped.
  final VoidCallback? onEdit;

  /// Callback when the Delete button is tapped.
  final VoidCallback? onDelete;

  /// Custom trailing widget (e.g. custom action or radio button).
  final Widget? trailing;

  const AddressCardWidget({
    super.key,
    required this.address,
    this.isSelected = false,
    this.isDisabled = false,
    this.propertyType = AddressPropertyType.residential,
    this.customTitle,
    this.onTap,
    this.onSetPrimary,
    this.onEdit,
    this.onDelete,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>();
    final themeText = Theme.of(context).extension<AppTextThemeExtension>();

    final primaryColor = themeColor?.primary ?? const Color(0xFF1E3A8A);
    final isPrimaryAddress = address.isPrimary;

    // Card background color based on state
    Color backgroundColor = Colors.white;
    if (isDisabled) {
      backgroundColor = const Color(0xFFF8FAFC);
    } else if (isSelected) {
      backgroundColor = primaryColor.withValues(alpha: AppDesignTokens.opacity.faint);
    }

    // Border color based on selection state
    BorderSide borderSide = BorderSide(
      color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
      width: isSelected ? 2.0 : 1.0,
    );

    return Semantics(
      button: onTap != null,
      selected: isSelected,
      enabled: !isDisabled,
      label: _buildSemanticsLabel(),
      child: Opacity(
        opacity: isDisabled ? AppDesignTokens.opacity.disabled : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppDesignTokens.radius.borderRadiusLg,
            border: Border.fromBorderSide(borderSide),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: AppDesignTokens.radius.borderRadiusLg,
            child: InkWell(
              onTap: isDisabled ? null : onTap,
              borderRadius: AppDesignTokens.radius.borderRadiusLg,
              child: Padding(
                padding: EdgeInsets.all(AppDesignTokens.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Header Row: Icon + Title + Badges + Trailing/Selection Checkmark
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Property Icon Container
                        _buildPropertyIconContainer(primaryColor),

                        const SizedBox(width: 12),

                        // Title & Badges Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      customTitle ?? _getPropertyTypeName(),
                                      style: themeText?.titleSectionSmall.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: const Color(0xFF1E293B),
                                          ) ??
                                          const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF1E293B),
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isPrimaryAddress) ...[
                                    const SizedBox(width: 8),
                                    _buildPrimaryBadge(),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${address.district}، ${address.city}',
                                style: themeText?.textBodySecondary.copyWith(
                                      color: const Color(0xFF64748B),
                                      fontSize: 12,
                                    ) ??
                                    const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Trailing Widget or Selection Radio/Checkmark
                        if (trailing != null)
                          trailing!
                        else if (isSelected)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),

                    // Detailed Address Line
                    Text(
                      _buildDetailedAddressLine(),
                      style: themeText?.textBodyPrimary.copyWith(
                            color: const Color(0xFF334155),
                            fontSize: 13,
                            height: 1.4,
                          ) ??
                          const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 13,
                            height: 1.4,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Optional Landmark Row
                    if (address.landmark != null && address.landmark!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'بجوار: ${address.landmark}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Action Buttons Row (Set Primary / Edit / Delete)
                    if (!isDisabled &&
                        (onSetPrimary != null || onEdit != null || onDelete != null)) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (!isPrimaryAddress && onSetPrimary != null)
                            InkWell(
                              onTap: onSetPrimary,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 36, minWidth: 48),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_outline_rounded,
                                      size: 16,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'تعيين كرئيسي',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const Spacer(),

                          if (onEdit != null)
                            Semantics(
                              button: true,
                              label: 'تعديل العنوان',
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: IconButton(
                                  onPressed: onEdit,
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                  tooltip: 'تعديل',
                                ),
                              ),
                            ),

                          if (onDelete != null)
                            Semantics(
                              button: true,
                              label: 'حذف العنوان',
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: IconButton(
                                  onPressed: onDelete,
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Color(0xFFEF4444),
                                  ),
                                  tooltip: 'حذف',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AddressPropertyType get _effectivePropertyType {
    if (address.propertyType != null && address.propertyType!.isNotEmpty) {
      switch (address.propertyType!.toLowerCase()) {
        case 'office':
          return AddressPropertyType.office;
        case 'commercial':
          return AddressPropertyType.commercial;
        case 'landmark':
          return AddressPropertyType.landmark;
        case 'residential':
        case 'home':
        default:
          return AddressPropertyType.residential;
      }
    }
    return propertyType;
  }

  Widget _buildPropertyIconContainer(Color primaryColor) {
    IconData iconData;
    switch (_effectivePropertyType) {
      case AddressPropertyType.office:
        iconData = Icons.business_rounded;
        break;
      case AddressPropertyType.commercial:
        iconData = Icons.storefront_rounded;
        break;
      case AddressPropertyType.landmark:
        iconData = Icons.location_city_rounded;
        break;
      case AddressPropertyType.residential:
        iconData = Icons.home_rounded;
        break;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor
            : primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: isSelected ? Colors.white : primaryColor,
        size: 22,
      ),
    );
  }

  Widget _buildPrimaryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 12,
            color: Color(0xFF059669),
          ),
          SizedBox(width: 3),
          Text(
            'رئيسي',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  String _getPropertyTypeName() {
    switch (_effectivePropertyType) {
      case AddressPropertyType.office:
        return 'مكتب';
      case AddressPropertyType.commercial:
        return 'محل تجاري / شركة';
      case AddressPropertyType.landmark:
        return 'موقع عام';
      case AddressPropertyType.residential:
        return 'منزل';
    }
  }

  String _buildDetailedAddressLine() {
    final parts = <String>[];
    parts.add(address.streetOrCompound);
    parts.add('مبنى ${address.buildingIdentifier}');

    if (address.floor != null && address.floor!.trim().isNotEmpty) {
      parts.add('دور ${address.floor}');
    }
    if (address.apartmentOrUnit != null && address.apartmentOrUnit!.trim().isNotEmpty) {
      parts.add('شقة ${address.apartmentOrUnit}');
    }

    return parts.join('، ');
  }

  String _buildSemanticsLabel() {
    final status = isSelected ? 'محدد' : '';
    final primary = address.isPrimary ? 'العنوان الرئيسي' : '';
    return 'عنوان ${address.district}، ${address.streetOrCompound}، مبنى ${address.buildingIdentifier}. $primary $status';
  }
}
