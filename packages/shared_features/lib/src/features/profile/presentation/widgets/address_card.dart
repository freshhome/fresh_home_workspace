import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AddressCard({
    super.key,
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeColor = context.themeColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(themeColor.cardBorder),
        boxShadow: [
          themeColor.cardShadow,
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: themeColor.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${address.city}, ${address.governorate}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: themeColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${address.street}, ${l10n.address_building_label} ${address.buildingNumber}",
                  style: TextStyle(
                    fontSize: 14,
                    color: themeColor.secondaryText,
                  ),
                ),
                if ((address.floorNumber != null && address.floorNumber!.isNotEmpty) || (address.apartmentNumber != null && address.apartmentNumber!.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "${l10n.address_floor_label} ${address.floorNumber?.isNotEmpty == true ? address.floorNumber : '-'}, ${l10n.address_apartment_label} ${address.apartmentNumber?.isNotEmpty == true ? address.apartmentNumber : '-'}",
                      style: TextStyle(
                        fontSize: 13,
                        color: themeColor.secondaryText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, color: themeColor.primary, size: 20),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
