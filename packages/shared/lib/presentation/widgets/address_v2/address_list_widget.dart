import 'package:flutter/material.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/widgets/address_v2/address_card_widget.dart';

/// Presentation States for [AddressListWidget].
enum AddressListState {
  loading,
  empty,
  error,
  success,
}

/// Generic, highly reusable Address List Widget for Address System V2.
///
/// Handles displaying a collection of user addresses, providing callbacks
/// for selection, setting primary address, editing, deleting, and adding a new address.
class AddressListWidget extends StatelessWidget {

  /// List of addresses to display when state is [AddressListState.success].
  final List<Address> addresses;

  /// Current visual state of the list widget.
  final AddressListState state;

  /// Currently selected address ID (if in selection mode).
  final String? selectedAddressId;

  /// Error message to display when state is [AddressListState.error].
  final String? errorMessage;

  /// Callback when an address card is selected/tapped.
  final ValueChanged<Address>? onSelectAddress;

  /// Callback when the "Set as Primary" action is triggered for an address.
  final ValueChanged<Address>? onSetPrimaryAddress;

  /// Callback when the Edit action is triggered for an address.
  final ValueChanged<Address>? onEditAddress;

  /// Callback when the Delete action is triggered for an address.
  final ValueChanged<Address>? onDeleteAddress;

  /// Callback when the "Add New Address" button is tapped.
  final VoidCallback? onAddAddress;

  /// Callback when the Retry button is tapped in error state.
  final VoidCallback? onRetry;

  /// Optional padding around the scroll view.
  final EdgeInsetsGeometry padding;

  /// Whether to render inside a scrollable view or a shrink-wrapped column.
  final bool shrinkWrap;

  /// Physics for the scroll view when [shrinkWrap] is false.
  final ScrollPhysics? physics;

  const AddressListWidget({
    super.key,
    required this.addresses,
    this.state = AddressListState.success,
    this.selectedAddressId,
    this.errorMessage,
    this.onSelectAddress,
    this.onSetPrimaryAddress,
    this.onEditAddress,
    this.onDeleteAddress,
    this.onAddAddress,
    this.onRetry,
    this.padding = const EdgeInsets.all(16.0),
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case AddressListState.loading:
        return _buildLoadingState(context);
      case AddressListState.error:
        return _buildErrorState(context);
      case AddressListState.empty:
        return _buildEmptyState(context);
      case AddressListState.success:
        if (addresses.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildSuccessList(context);
    }
  }

  Widget _buildSuccessList(BuildContext context) {
    Widget listContent = ListView.separated(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics()),
      itemCount: addresses.length + (onAddAddress != null ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == addresses.length) {
          return _buildAddNewAddressButton(context);
        }

        final address = addresses[index];
        final isSelected = selectedAddressId != null && selectedAddressId == address.id;

        return AddressCardWidget(
          key: ValueKey(address.id),
          address: address,
          isSelected: isSelected,
          onTap: onSelectAddress != null ? () => onSelectAddress!(address) : null,
          onSetPrimary: onSetPrimaryAddress != null ? () => onSetPrimaryAddress!(address) : null,
          onEdit: onEditAddress != null ? () => onEditAddress!(address) : null,
          onDelete: onDeleteAddress != null ? () => onDeleteAddress!(address) : null,
        );
      },
    );

    return listContent;
  }

  Widget _buildAddNewAddressButton(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>();
    final primaryColor = themeColor?.primary ?? const Color(0xFF1E3A8A);

    return Semantics(
      button: true,
      label: 'إضافة عنوان جديد',
      child: OutlinedButton.icon(
        onPressed: onAddAddress,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: primaryColor,
          minimumSize: const Size(double.infinity, 52),
        ),
        icon: const Icon(Icons.add_location_alt_rounded, size: 20),
        label: const Text(
          'إضافة عنوان جديد',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return ListView.separated(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildSkeletonCard(context),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final themeText = Theme.of(context).extension<AppTextThemeExtension>();

    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد عناوين محفوظة',
              style: themeText?.titleSectionSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ) ??
                  const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'قم بإضافة عنوانك الأول لسهولة وسرعة طلب الخدمات المنزلية.',
              textAlign: TextAlign.center,
              style: themeText?.textBodySecondary.copyWith(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                  ) ??
                  const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
            ),
            if (onAddAddress != null) ...[
              const SizedBox(height: 24),
              _buildAddNewAddressButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final themeText = Theme.of(context).extension<AppTextThemeExtension>();

    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'حدث خطأ أثناء تحميل العناوين',
              textAlign: TextAlign.center,
              style: themeText?.textBodyPrimary.copyWith(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                  ) ??
                  const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
