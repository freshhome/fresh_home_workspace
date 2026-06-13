import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/service/enums/pricing_method.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/widget/my_custom_button.dart';
import 'package:shared_features/src/features/booking_flow/domain/booking_flow_config.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/booking_flow_state.dart';
import '../widgets/booking_progress.dart';
import 'pricing_page.dart';
import 'schedule_page.dart';
import 'address_page.dart';
import 'manual_client_page.dart';
import 'confirmation_page.dart';
import 'service_selection_page.dart';

/// Unified booking flow page for both customer and admin modes.
///
/// Customer flow (4 steps):
///   Pricing → Schedule → Address → Confirmation
///
/// Admin flow (5 steps):
///   Service Selection → Pricing → Schedule → Manual Client Data → Confirmation
class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Widget> _buildPages(BookingFlowConfig config) {
    if (config.requiresServiceSelection) {
      // Admin flow
      return const [
        ServiceSelectionPage(),
        PricingPage(),
        SchedulePage(),
        ManualClientPage(),
        ConfirmationPage(),
      ];
    }
    // Customer flow
    return const [
      PricingPage(),
      SchedulePage(),
      AddressPage(),
      ConfirmationPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingFlowCubit>();
    final config = cubit.config;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<BookingFlowCubit, BookingFlowState>(
      listenWhen: (prev, curr) =>
          prev.currentStepIndex != curr.currentStepIndex,
      listener: (context, state) {
        _pageController.animateToPage(
          state.currentStepIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.booking_appbar_title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              final state = context.read<BookingFlowCubit>().state;
              if (state.currentStepIndex > 0) {
                context.read<BookingFlowCubit>().previousStep();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(110),
            child: BlocBuilder<BookingFlowCubit, BookingFlowState>(
              builder: (context, state) => BookingProgress(
                currentStep: state.currentStepIndex,
                totalSteps: config.totalSteps,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: _buildPages(config),
              ),
            ),
            _buildBottomBar(context, l10n, config),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    AppLocalizations l10n,
    BookingFlowConfig config,
  ) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;

    return BlocBuilder<BookingFlowCubit, BookingFlowState>(
      builder: (context, state) {
        final step = state.currentStepIndex;
        final totalSteps = config.totalSteps;
        final isFirstStep = step == 0;
        final isLastStep = step == totalSteps - 1;

        // ── Determine pricing step index ──
        final pricingStepIndex =
            config.requiresServiceSelection ? 1 : 0;
        final isPricingStep = step == pricingStepIndex;

        // ── Determine address/client step index ──
        final clientStepIndex = config.requiresManualClientData ? 3 : 2;
        final isClientStep = step == clientStepIndex;

        // ── Button logic ──────────────────────────────────────────────
        final String nextButtonText;
        final Widget? nextButtonIcon;
        final VoidCallback? nextOnPressed;

        if (isPricingStep) {
          if (!state.isPriceCalculated) {
            // Show "Calculate" button
            nextButtonText = l10n.booking_calculate_button;
            nextButtonIcon = null;

            bool allRequiredFieldsFilled = true;
            if (state.servicePrice != null) {
              for (final field in state.servicePrice!.fields) {
                if (field.required) {
                  final val = state.dynamicInputs[field.id];
                  if (val == null || (val is String && val.trim().isEmpty)) {
                    allRequiredFieldsFilled = false;
                    break;
                  }
                }
              }
            }

            bool canCalculate = false;
            if (allRequiredFieldsFilled) {
              final pricingType = state.servicePrice?.type;
              if (pricingType == PricingMethod.perSquareMeter) {
                canCalculate = state.area != null && state.area! > 0;
              } else if (pricingType == PricingMethod.perLinearMeter) {
                if (state.useWindowsCalculator) {
                  canCalculate = state.windows.isNotEmpty &&
                      state.windows.every((w) => w.width > 0 && w.height > 0 && w.quantity > 0);
                } else {
                  canCalculate = state.totalLinearMeters != null && state.totalLinearMeters! > 0;
                }
              } else {
                canCalculate = true;
              }
            }

            nextOnPressed = canCalculate
                ? () {
                    FocusScope.of(context).unfocus();
                    context.read<BookingFlowCubit>().calculatePrice();
                  }
                : null;
          } else {
            // Price calculated → show Next
            nextButtonText = l10n.general_next;
            nextButtonIcon =
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white);
            nextOnPressed = () {
              FocusScope.of(context).unfocus();
              context.read<BookingFlowCubit>().nextStep();
            };
          }
        } else if (isLastStep) {
          // Confirmation step
          nextButtonText = l10n.booking_confirm_button;
          nextButtonIcon = null;
          nextOnPressed = () {
            FocusScope.of(context).unfocus();
            context.read<BookingFlowCubit>().submitBooking();
          };
        } else if (isClientStep && config.requiresManualClientData) {
          // Admin: manual client data step — validate inside ManualClientPage
          nextButtonText = l10n.general_next;
          nextButtonIcon =
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white);
          nextOnPressed = () {
            FocusScope.of(context).unfocus();
            context.read<BookingFlowCubit>().requestManualClientValidation();
          };
        } else if (isClientStep && !config.requiresManualClientData) {
          // Customer: address step — trigger validation inside AddressPage
          nextButtonText = l10n.general_next;
          nextButtonIcon =
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white);
          nextOnPressed = () {
            FocusScope.of(context).unfocus();
            context.read<BookingFlowCubit>().requestAddressValidation();
          };
        } else {
          // Service selection or schedule step
          nextButtonText = l10n.general_next;
          nextButtonIcon =
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white);
          final canProceed = state.service != null || step != 0;
          nextOnPressed = canProceed
              ? () {
                  FocusScope.of(context).unfocus();
                  context.read<BookingFlowCubit>().nextStep();
                }
              : null;
        }

        final bool isSubmitting = state.status == BookingStatus.loading;

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            boxShadow: [themeColor.cardShadow],
            border: Border(top: themeColor.cardBorder),
          ),
          child: Row(
            children: [
              if (!isFirstStep)
                Expanded(
                  child: MyCustomButton(
                    text: l10n.general_back,
                    leadingIcon: Icon(Icons.arrow_back_ios,
                        size: 16, color: themeColor.primary),
                    onPressed: isSubmitting
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            context.read<BookingFlowCubit>().previousStep();
                          },
                    isOutlined: true,
                    borderColor: themeColor.primary,
                  ),
                ),
              if (!isFirstStep) const SizedBox(width: 12),
              Expanded(
                flex: isFirstStep ? 1 : 2,
                child: MyCustomButton(
                  text: nextButtonText,
                  trailingIcon: nextButtonIcon,
                  isLoading: isSubmitting,
                  gradient: isLastStep
                      ? const LinearGradient(
                          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  onPressed: isSubmitting ? null : nextOnPressed,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
