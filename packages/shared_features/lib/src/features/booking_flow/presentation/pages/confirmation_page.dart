import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:shared/presentation/extensions/navigation_extension.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/dialogs/dialog_helper.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/booking_flow_state.dart';

class ConfirmationPage extends StatelessWidget {
  const ConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingFlowCubit, BookingFlowState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        final l10n = AppLocalizations.of(context)!;

        // Handle transition FROM loading
        if (state.status != BookingStatus.loading) {
          DialogHelper.dismissLoading(context);
        }

        // Handle transition TO different statuses
        if (state.status == BookingStatus.loading) {
          DialogHelper.showLoading(context);
        } else if (state.status == BookingStatus.success) {
          DialogHelper.showSuccess(
            context,
            message:
                '${l10n.booking_success_message}\n\n${l10n.booking_id_label}: ${state.generatedBookingId ?? ""}',
            onOkPress: () {
              context.toPath(AppRoutes.home);
            },
            onDismiss: (_) {
              context.toPath(AppRoutes.home);
            },
          );
        } else if (state.status == BookingStatus.failure) {
          print ("++++++++++++++++++++++++++++++++++"); 
          print ("Booking failed: ${state.errorMessage}");
          print ("++++++++++++++++++++++++++++++++++"); 
          DialogHelper.showError(
            context,
            message: _getLocalizedError(state.errorMessage, l10n),
            onOkPress: () => context.read<BookingFlowCubit>().resetStatus(),
            onDismiss: (_) => context.read<BookingFlowCubit>().resetStatus(),
          );
        }
      },
      builder: (context, state) {
        final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
        final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
        final l10n = AppLocalizations.of(context)!;
        final cubit = context.read<BookingFlowCubit>();

        // Resolve displayed address & contact depending on mode
        final isAdmin = cubit.config.requiresManualClientData;
        final address = state.address;
        final scheduledAt = state.scheduledAt;

        final String displayedAddress = isAdmin
            ? [
                state.manualClientCity,
                state.manualClientStreet,
                state.manualClientBuilding != null
                    ? 'عمارة ${state.manualClientBuilding}'
                    : null,
              ].whereType<String>().join(', ')
            : address != null
            ? '${address.governorate}, ${address.city}, ${address.street}, عمارة ${address.buildingNumber}, شقة ${address.apartmentNumber}'
            : l10n.confirmation_no_address;

        final String displayedName = isAdmin
            ? (state.manualClientName ?? '')
            : (state.contact?.name ?? '');

        final String displayedPhone = isAdmin
            ? (state.manualClientPhone ?? '')
            : (state.contact?.phone.firstOrNull ?? '');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.confirmation_review_title,
                style: themeText.titleSectionMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 24),

              // Summary card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: themeColor.primary.withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.confirmation_service_type,
                                  style: themeText.textCaption.copyWith(
                                    color: themeColor.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  state.service?.name[Localizations.localeOf(
                                        context,
                                      ).languageCode] ??
                                      '',
                                  style: themeText.titleSectionSmall.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                l10n.pricing_total_estimated,
                                style: themeText.textCaption.copyWith(
                                  color: themeColor.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${state.price?.total.toStringAsFixed(0)} ${l10n.pricing_currency}',
                                style: themeText.titleSectionSmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Detail rows
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (!isAdmin && state.area != null) ...[
                            _DetailRow(
                              icon: Icons.home_outlined,
                              label: l10n.confirmation_area,
                              value:
                                  '${state.area!.toStringAsFixed(0)} ${l10n.pricing_area_unit}',
                              themeText: themeText,
                              themeColor: themeColor,
                            ),
                            const Divider(height: 32),
                          ],
                          _DetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: l10n.confirmation_delivery_time,
                            value: scheduledAt != null
                                ? DateFormat(
                                    'yyyy-MM-dd @ hh:mm a',
                                  ).format(scheduledAt)
                                : '',
                            themeText: themeText,
                            themeColor: themeColor,
                          ),
                          const Divider(height: 32),
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            label: l10n.address_details_title,
                            value: displayedAddress,
                            themeText: themeText,
                            themeColor: themeColor,
                          ),
                          const Divider(height: 32),
                          _DetailRow(
                            icon: Icons.person_outline,
                            label: l10n.address_full_name_label,
                            value: displayedName,
                            themeText: themeText,
                            themeColor: themeColor,
                          ),
                          const Divider(height: 32),
                          _DetailRow(
                            icon: Icons.phone_outlined,
                            label: l10n.address_phone_label,
                            value: displayedPhone,
                            themeText: themeText,
                            themeColor: themeColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment method
              Text(
                l10n.confirmation_payment_method,
                style: themeText.titleSectionSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeColor.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, color: themeColor.primary),
                    const SizedBox(width: 12),
                    Text(
                      l10n.confirmation_payment_cash,
                      style: themeText.textBodyPrimary.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.check_circle, color: themeColor.primary),
                  ],
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }

  String _getLocalizedError(String? error, AppLocalizations l10n) {
    if (error == null) return l10n.general_something_wrong;
    switch (error) {
      case 'error_pricing_data_unavailable':
        return l10n.error_pricing_data_unavailable;
      case 'error_incomplete_data':
        return l10n.error_incomplete_data;
      case 'error_booking_id_failed':
        return l10n.error_booking_id_failed;
      default:
        return error;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppTextThemeExtension themeText;
  final ThemeColorExtension themeColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.themeText,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeColor.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: themeColor.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: themeText.textCaption.copyWith(
                  color: const Color(0xFF999999),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: themeText.textBodyPrimary.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
