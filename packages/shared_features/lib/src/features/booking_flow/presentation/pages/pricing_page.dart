import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/service/enums/pricing_method.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/service/entities/sub_entities/service_price.dart';
import 'package:shared/presentation/presentation.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/booking_flow_state.dart';
import '../widgets/dynamic_form_widgets.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _totalLinearController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<int, TextEditingController> _widthControllers = {};
  final Map<int, TextEditingController> _heightControllers = {};
  final Map<int, TextEditingController> _quantityControllers = {};
  bool _isCouponFieldExpanded = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<BookingFlowCubit>();
    if (cubit.state.area != null) {
      _areaController.text = cubit.state.area!.toStringAsFixed(0);
    }
    if (cubit.state.totalLinearMeters != null) {
      _totalLinearController.text =
          cubit.state.totalLinearMeters!.toStringAsFixed(1).replaceAll('.0', '');
    }
    final coupon = cubit.state.dynamicInputs['coupon_code'] as String?;
    if (coupon != null) {
      _couponController.text = coupon;
      _isCouponFieldExpanded = true;
    }
    for (int i = 0; i < cubit.state.windows.length; i++) {
      _initWindowControllers(i, cubit.state.windows[i]);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pricingType = cubit.state.servicePrice?.type;
      if (pricingType == PricingMethod.fixed ||
          pricingType == PricingMethod.perIssue) {
        cubit.calculatePrice();
      }
    });
    if (cubit.state.servicePrice?.type == PricingMethod.perLinearMeter &&
        cubit.state.windows.isEmpty) {
      cubit.addWindow();
    }
  }

  void _initWindowControllers(int index, WindowDimension window) {
    _widthControllers[index] ??= TextEditingController(
      text: window.width == 0 ? '' : window.width.toString(),
    );
    _heightControllers[index] ??= TextEditingController(
      text: window.height == 0 ? '' : window.height.toString(),
    );
    _quantityControllers[index] ??= TextEditingController(
      text: window.quantity.toString(),
    );
  }

  @override
  void dispose() {
    _areaController.dispose();
    _totalLinearController.dispose();
    _couponController.dispose();
    _scrollController.dispose();
    for (var c in _widthControllers.values) {
      c.dispose();
    }
    for (var c in _heightControllers.values) {
      c.dispose();
    }
    for (var c in _quantityControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BookingFlowCubit, BookingFlowState>(
          listenWhen: (prev, curr) => prev.windows.length != curr.windows.length,
          listener: (context, state) {
            for (int i = 0; i < state.windows.length; i++) {
              _initWindowControllers(i, state.windows[i]);
            }
          },
        ),
        BlocListener<BookingFlowCubit, BookingFlowState>(
          listenWhen: (prev, curr) =>
              (prev.isPriceCalculated != curr.isPriceCalculated && curr.isPriceCalculated) ||
              (prev.errorMessage != curr.errorMessage && curr.errorMessage != null),
          listener: (context, state) {
            if (state.errorMessage != null) {
              debugPrint('🚨 Pricing Calculation Error: ${state.errorMessage}');
            }
            if (state.isPriceCalculated && state.price != null) {
              debugPrint('💵 Pricing Calculated: Base=${state.price!.basePrice}, Total=${state.price!.total}, Metadata=${state.price!.metadata}');
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                );
              }
            });
          },
        ),
      ],
      child: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          final themeColor = context.themeColor;
          final themeText = Theme.of(
            context,
          ).extension<AppTextThemeExtension>()!;
          final l10n = AppLocalizations.of(context)!;
          final priceEntity = state.servicePrice;
          final pricingType = priceEntity?.type;
          final isAreaRequired = pricingType == PricingMethod.perSquareMeter;
          final isLinearRequired = pricingType == PricingMethod.perLinearMeter;

          final computedFieldIds = state.computedFields?.map((cf) => cf.id).toSet() ?? {};
          final filteredFields = priceEntity?.fields
                  .where((f) => !computedFieldIds.contains(f.id))
                  .toList() ??
              const [];

          final isDynamic =
              priceEntity != null && filteredFields.isNotEmpty;

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServiceHeader(state.service, priceEntity, themeText, themeColor),
                const SizedBox(height: 12),
                if (isDynamic)
                  DynamicFormRenderer(
                    fields: filteredFields,
                    values: state.dynamicInputs,
                    options: priceEntity.options,
                    selectedOptions: state.selectedOptions,
                    onFieldChanged: (key, val) => context
                        .read<BookingFlowCubit>()
                        .updateDynamicInput(key, val),
                    onOptionToggled: (optKey) =>
                         context.read<BookingFlowCubit>().toggleOption(optKey),
                  )
                else ...[
                  if (isAreaRequired)
                    _buildAreaInput(l10n, themeText, themeColor, state)
                  else if (isLinearRequired)
                    _buildLinearPricingSection(state, themeText, themeColor)
                  else
                    _buildFixedPriceMessage(themeColor, themeText),
                ],
                const SizedBox(height: 24),
                if (state.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeColor.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeColor.error.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: themeColor.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: themeText.textBodySecondary.copyWith(
                              color: themeColor.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (state.isPriceCalculated && state.price != null) ...[
                  if (state.hasActiveCoupons || (state.dynamicInputs['coupon_code'] != null && state.dynamicInputs['coupon_code'].toString().isNotEmpty)) ...[
                    _buildCouponInput(themeText, themeColor, state),
                    const SizedBox(height: 24),
                  ],
                  PriceBreakdownCard(pricing: state.price!, showHeader: true),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Service Header ─────────────────────────────────────────────────────────

  Widget _buildServiceHeader(
    BookedService? service,
    PriceEntity? priceEntity,
    AppTextThemeExtension themeText,
    ThemeColorExtension themeColor,
  ) {
    if (service == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    
    String pricingMethodText = l10n.pricing_method_custom;
    IconData pricingIcon = Icons.payments_outlined;
    if (priceEntity != null) {
      switch (priceEntity.type) {
        case PricingMethod.fixed:
          pricingMethodText = l10n.pricing_method_fixed;
          pricingIcon = Icons.bookmark_added_rounded;
          break;
        case PricingMethod.perSquareMeter:
          pricingMethodText = l10n.pricing_method_square_meter;
          pricingIcon = Icons.square_foot_rounded;
          break;
        case PricingMethod.perLinearMeter:
          pricingMethodText = l10n.pricing_method_linear_meter;
          pricingIcon = Icons.linear_scale_rounded;
          break;
        case PricingMethod.perIssue:
          pricingMethodText = l10n.pricing_method_issue;
          pricingIcon = Icons.report_problem_rounded;
          break;
        case PricingMethod.unknown:
          pricingMethodText = l10n.pricing_method_custom;
          pricingIcon = Icons.payments_outlined;
          break;
        case PricingMethod.inspection:
          pricingMethodText = l10n.pricing_method_custom;
          pricingIcon = Icons.payments_outlined;
          break;
      }
    }

    final localeName = service.name[Localizations.localeOf(context).languageCode] ??
        service.name['ar'] ??
        service.name['en'] ??
        '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColor.primary.withValues(alpha: 0.1),
            themeColor.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeColor.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              pricingIcon,
              color: themeColor.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localeName,
                  style: themeText.textBodyPrimary.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: themeColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pricingMethodText,
                  style: themeText.textCaption.copyWith(
                    color: themeColor.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Area Input ─────────────────────────────────────────────────────────────

  Widget _buildAreaInput(
    AppLocalizations l10n,
    AppTextThemeExtension themeText,
    ThemeColorExtension themeColor,
    BookingFlowState state,
  ) {
    final currentArea = state.area ?? 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.pricing_area_label,
              style: themeText.titleSectionSmall.copyWith(
                color: themeColor.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: themeColor.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${currentArea.toStringAsFixed(0)} ${l10n.pricing_area_unit}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: themeColor.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Interactive Stepper Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.fromBorderSide(themeColor.cardBorder),
            boxShadow: [themeColor.cardShadow],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    onPressed: currentArea > 50
                        ? () {
                            final newVal = (currentArea - 10).clamp(50, 1000).toDouble();
                            _areaController.text = newVal.toStringAsFixed(0);
                            context.read<BookingFlowCubit>().updateArea(newVal);
                          }
                        : null,
                    icon: const Icon(Icons.remove, size: 20),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        currentArea.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: themeColor.textPrimary,
                        ),
                      ),
                      Text(
                        l10n.pricing_area_unit,
                        style: TextStyle(
                          fontSize: 12,
                          color: themeColor.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      final newVal = (currentArea + 10).clamp(50, 1000).toDouble();
                      _areaController.text = newVal.toStringAsFixed(0);
                      context.read<BookingFlowCubit>().updateArea(newVal);
                    },
                    icon: const Icon(Icons.add, size: 20),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Slider(
                value: currentArea.clamp(50, 500).toDouble(),
                min: 50,
                max: 500,
                divisions: 45,
                activeColor: themeColor.primary,
                inactiveColor: themeColor.primary.withValues(alpha: 0.15),
                onChanged: (val) {
                  setState(() {
                    _areaController.text = val.toStringAsFixed(0);
                  });
                  context.read<BookingFlowCubit>().updateArea(val.roundToDouble());
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Preset Chips
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [100, 150, 200, 250, 300, 400].map((preset) {
              final isSelected = currentArea.round() == preset;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text('$preset ${l10n.pricing_unit_meter_short}²'),
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? themeColor.onPrimary : themeColor.secondaryText,
                  ),
                  selected: isSelected,
                  selectedColor: themeColor.primary,
                  backgroundColor: themeColor.nestedCardBackground,
                  onSelected: (selected) {
                    if (selected) {
                      _areaController.text = preset.toString();
                      context.read<BookingFlowCubit>().updateArea(preset.toDouble());
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          title: Text(
            l10n.pricing_manual_area_override,
            style: themeText.textCaption.copyWith(color: themeColor.secondaryText, fontSize: 12),
          ),
          childrenPadding: EdgeInsets.zero,
          tilePadding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildInputField(
                controller: _areaController,
                unit: l10n.pricing_area_unit,
                onChanged: (val) {
                  if (val.isEmpty) {
                    context.read<BookingFlowCubit>().updateArea(null);
                  } else {
                    context.read<BookingFlowCubit>().updateArea(double.tryParse(val));
                  }
                },
                themeText: themeText,
                themeColor: themeColor,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: themeColor.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.pricing_min_billing_notice,
                style: themeText.textCaption.copyWith(
                  color: themeColor.primary.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Linear Pricing Section ──────────────────────────────────────────────────

  Widget _buildLinearPricingSection(
    BookingFlowState state,
    AppTextThemeExtension themeText,
    ThemeColorExtension themeColor,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Buttons with beautiful premium UI
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: themeColor.nestedCardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context
                      .read<BookingFlowCubit>()
                      .updateUseWindowsCalculator(true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: state.useWindowsCalculator
                          ? themeColor.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        l10n.pricing_calc_from_windows,
                        style: themeText.textCaption.copyWith(
                          color: state.useWindowsCalculator
                              ? themeColor.onPrimary
                              : themeColor.secondaryText,
                          fontWeight: state.useWindowsCalculator
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => context
                      .read<BookingFlowCubit>()
                      .updateUseWindowsCalculator(false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !state.useWindowsCalculator
                          ? themeColor.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        l10n.pricing_direct_linear_meters,
                        style: themeText.textCaption.copyWith(
                          color: !state.useWindowsCalculator
                              ? themeColor.onPrimary
                              : themeColor.secondaryText,
                          fontWeight: !state.useWindowsCalculator
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (state.useWindowsCalculator)
          _buildWindowsList(state, themeText, themeColor)
        else
          _buildDirectLinearMetersInput(l10n, themeText, themeColor, state),
      ],
    );
  }

  Widget _buildDirectLinearMetersInput(
    AppLocalizations l10n,
    AppTextThemeExtension themeText,
    ThemeColorExtension themeColor,
    BookingFlowState state,
  ) {
    final currentLinear = state.totalLinearMeters ?? 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.pricing_linear_meters_title,
              style: themeText.titleSectionSmall.copyWith(
                color: themeColor.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: themeColor.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${currentLinear.toStringAsFixed(1).replaceAll('.0', '')} ${l10n.pricing_unit_meter_short}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: themeColor.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Interactive Stepper Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.fromBorderSide(themeColor.cardBorder),
            boxShadow: [themeColor.cardShadow],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    onPressed: currentLinear > 1
                        ? () {
                            final newVal = (currentLinear - 1).clamp(1, 100).toDouble();
                            _totalLinearController.text = newVal.toStringAsFixed(0);
                            context.read<BookingFlowCubit>().updateTotalLinearMeters(newVal);
                          }
                        : null,
                    icon: const Icon(Icons.remove, size: 20),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        currentLinear.toStringAsFixed(1).replaceAll('.0', ''),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: themeColor.textPrimary,
                        ),
                      ),
                      Text(
                        l10n.pricing_unit_meter,
                        style: TextStyle(
                          fontSize: 12,
                          color: themeColor.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      final newVal = (currentLinear + 1).clamp(1, 100).toDouble();
                      _totalLinearController.text = newVal.toStringAsFixed(0);
                      context.read<BookingFlowCubit>().updateTotalLinearMeters(newVal);
                    },
                    icon: const Icon(Icons.add, size: 20),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Slider(
                value: currentLinear.clamp(1, 50).toDouble(),
                min: 1,
                max: 50,
                divisions: 49,
                activeColor: themeColor.primary,
                inactiveColor: themeColor.primary.withValues(alpha: 0.15),
                onChanged: (val) {
                  setState(() {
                    _totalLinearController.text = val.toStringAsFixed(0);
                  });
                  context.read<BookingFlowCubit>().updateTotalLinearMeters(val.roundToDouble());
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Preset Chips
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [5, 10, 15, 20, 25, 30, 40].map((preset) {
              final isSelected = currentLinear.round() == preset;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text('$preset ${l10n.pricing_unit_meter_short}'),
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? themeColor.onPrimary : themeColor.secondaryText,
                  ),
                  selected: isSelected,
                  selectedColor: themeColor.primary,
                  backgroundColor: themeColor.nestedCardBackground,
                  onSelected: (selected) {
                    if (selected) {
                      _totalLinearController.text = preset.toString();
                      context.read<BookingFlowCubit>().updateTotalLinearMeters(preset.toDouble());
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          title: Text(
            l10n.pricing_manual_linear_override,
            style: themeText.textCaption.copyWith(color: themeColor.secondaryText, fontSize: 12),
          ),
          childrenPadding: EdgeInsets.zero,
          tilePadding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildInputField(
                controller: _totalLinearController,
                unit: l10n.pricing_unit_meter,
                onChanged: (val) {
                  if (val.isEmpty) {
                    context.read<BookingFlowCubit>().updateTotalLinearMeters(null);
                  } else {
                    context.read<BookingFlowCubit>().updateTotalLinearMeters(double.tryParse(val));
                  }
                },
                themeText: themeText,
                themeColor: themeColor,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: themeColor.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.pricing_linear_meters_desc,
                  style: themeText.textCaption.copyWith(
                    color: themeColor.primary.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Windows List ───────────────────────────────────────────────────────────

  Widget _buildWindowsList(
    BookingFlowState state,
    AppTextThemeExtension themeText,
    ThemeColorExtension themeColor,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pricing_windows_dimensions_title,
          style: themeText.titleSectionSmall.copyWith(
            color: themeColor.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.pricing_windows_dimensions_desc,
          style: themeText.textCaption.copyWith(color: themeColor.secondaryText),
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.windows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final window = state.windows[index];
            return _buildWindowItem(index, window, themeText, themeColor, l10n);
          },
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => context.read<BookingFlowCubit>().addWindow(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: themeColor.primary, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: themeColor.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.pricing_add_window_button,
                  style: themeText.textBodyPrimary.copyWith(
                    color: themeColor.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWindowItem(
    int index,
    WindowDimension window,
    AppTextThemeExtension themeText,
    ThemeColorExtension themeColor,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(themeColor.cardBorder),
        boxShadow: [themeColor.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.pricing_window_title((index + 1).toString()),
                style: themeText.textBodySecondary.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeColor.textPrimary,
                ),
              ),
              if (index > 0)
                IconButton(
                  onPressed: () {
                    context.read<BookingFlowCubit>().removeWindow(index);
                    _widthControllers.remove(index)?.dispose();
                    _heightControllers.remove(index)?.dispose();
                    _quantityControllers.remove(index)?.dispose();
                  },
                  icon: Icon(
                    Icons.delete_outline,
                    color: themeColor.error,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildWindowSideSlidingToggle(
            window: window,
            onChanged: (isBoth) => context.read<BookingFlowCubit>().updateWindow(
                  index,
                  window.copyWith(isBothSides: isBoth),
                ),
            themeColor: themeColor,
            themeText: themeText,
            l10n: l10n,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildWindowDimensionStepper(
                  label: l10n.pricing_window_width_label,
                  value: window.width,
                  onChanged: (w) => context.read<BookingFlowCubit>().updateWindow(
                        index,
                        window.copyWith(width: w),
                      ),
                  themeColor: themeColor,
                  themeText: themeText,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWindowDimensionStepper(
                  label: l10n.pricing_window_height_label,
                  value: window.height,
                  onChanged: (h) => context.read<BookingFlowCubit>().updateWindow(
                        index,
                        window.copyWith(height: h),
                      ),
                  themeColor: themeColor,
                  themeText: themeText,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWindowQuantityStepper(
                  label: l10n.pricing_window_count_label,
                  value: window.quantity,
                  onChanged: (q) => context.read<BookingFlowCubit>().updateWindow(
                        index,
                        window.copyWith(quantity: q),
                      ),
                  themeColor: themeColor,
                  themeText: themeText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Custom Steppers ────────────────────────────────────────────────────────

  Widget _buildWindowDimensionStepper({
    required String label,
    required double value,
    required Function(double) onChanged,
    required ThemeColorExtension themeColor,
    required AppTextThemeExtension themeText,
    required AppLocalizations l10n,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: themeText.textCaption.copyWith(fontSize: 12, color: themeColor.secondaryText),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: themeColor.nestedCardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: value > 0.1
                    ? () => onChanged(double.parse((value - 0.1).toStringAsFixed(1)))
                    : null,
                icon: const Icon(Icons.remove, size: 16),
                color: themeColor.primary,
                disabledColor: themeColor.unselectedItem.withValues(alpha: 0.3),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${value.toStringAsFixed(1)}${l10n.pricing_unit_meter_short}',
                    style: themeText.textBodyPrimary.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: value < 10.0
                    ? () => onChanged(double.parse((value + 0.1).toStringAsFixed(1)))
                    : null,
                icon: const Icon(Icons.add, size: 16),
                color: themeColor.primary,
                disabledColor: themeColor.unselectedItem.withValues(alpha: 0.3),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWindowQuantityStepper({
    required String label,
    required int value,
    required Function(int) onChanged,
    required ThemeColorExtension themeColor,
    required AppTextThemeExtension themeText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: themeText.textCaption.copyWith(fontSize: 12, color: themeColor.secondaryText),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: themeColor.nestedCardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove, size: 16),
                color: themeColor.primary,
                disabledColor: themeColor.unselectedItem.withValues(alpha: 0.3),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$value',
                    style: themeText.textBodyPrimary.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: value < 50 ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add, size: 16),
                color: themeColor.primary,
                disabledColor: themeColor.unselectedItem.withValues(alpha: 0.3),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWindowSideSlidingToggle({
    required WindowDimension window,
    required Function(bool) onChanged,
    required ThemeColorExtension themeColor,
    required AppTextThemeExtension themeText,
    required AppLocalizations l10n,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: themeColor.nestedCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: window.isBothSides
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Container(
                  width: width,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: themeColor.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.primary.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(false),
                      child: Center(
                        child: Text(
                          l10n.pricing_window_single_side,
                          style: themeText.textCaption.copyWith(
                            color: !window.isBothSides ? Colors.white : themeColor.secondaryText,
                            fontWeight: !window.isBothSides ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(true),
                      child: Center(
                        child: Text(
                          l10n.pricing_window_both_sides,
                          style: themeText.textCaption.copyWith(
                            color: window.isBothSides ? Colors.white : themeColor.secondaryText,
                            fontWeight: window.isBothSides ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Fixed Price Message ────────────────────────────────────────────────────

  Widget _buildFixedPriceMessage(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: themeColor.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.pricing_fixed_price_desc,
              style: themeText.textBodySecondary.copyWith(
                color: themeColor.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Field ────────────────────────────────────────────────────────────

  Widget _buildInputField({
    required TextEditingController controller,
    required String unit,
    required Function(String) onChanged,
    required AppTextThemeExtension themeText,
    required ThemeColorExtension themeColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(themeColor.cardBorder),
        boxShadow: [themeColor.cardShadow],
      ),
      child: BaseTextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        hint: '0.0',
        suffixText: unit,
        fillColor: Colors.transparent,
      ),
    );
  }

  Widget _buildSubtleCouponTrigger(
    AppTextThemeExtension themeText,
    ThemeColorExtension themeColor,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCouponFieldExpanded = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: themeColor.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeColor.primary.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 18,
              color: themeColor.primary,
            ),
            const SizedBox(width: 10),
            Text(
              l10n.pricing_coupon_trigger_text,
              style: themeText.textCaption.copyWith(
                color: themeColor.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: themeColor.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponInput(
    AppTextThemeExtension themeText,
    ThemeColorExtension themeColor,
    BookingFlowState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<BookingFlowCubit>();
    final hasCoupon = cubit.state.dynamicInputs['coupon_code'] != null &&
        cubit.state.dynamicInputs['coupon_code'].toString().isNotEmpty;

    // If there is no active coupon, and the user hasn't expanded it, show trigger
    if (!_isCouponFieldExpanded && !hasCoupon) {
      return _buildSubtleCouponTrigger(themeText, themeColor);
    }

    return Container(
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(themeColor.cardBorder),
        boxShadow: [themeColor.cardShadow],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_offer_outlined, color: themeColor.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l10n.pricing_coupon_label,
                              style: themeText.textBodySecondary.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: themeColor.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (!hasCoupon)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                _isCouponFieldExpanded = false;
                              });
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: BaseTextFormField(
                            controller: _couponController,
                            hint: l10n.pricing_coupon_hint,
                            radius: 12,
                            enabled: !hasCoupon,
                            prefixIcon: const Icon(Icons.confirmation_number_outlined),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              if (hasCoupon) {
                                // Clear coupon
                                _couponController.clear();
                                cubit.updateDynamicInput('coupon_code', null);
                                cubit.calculatePrice();
                              } else {
                                // Apply coupon
                                final code = _couponController.text.trim().toUpperCase();
                                if (code.isNotEmpty) {
                                  cubit.updateDynamicInput('coupon_code', code);
                                  cubit.calculatePrice();
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasCoupon ? themeColor.error.withValues(alpha: 0.1) : themeColor.primary,
                              foregroundColor: hasCoupon ? themeColor.error : themeColor.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              hasCoupon ? l10n.pricing_coupon_cancel : l10n.pricing_coupon_apply,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasCoupon) ...[
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter: DashedLinePainter(color: themeColor.unselectedItem.withValues(alpha: 0.2)),
                    ),
                    Positioned(
                      left: -8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: themeColor.background,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: themeColor.background,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: themeColor.pricingDiscount, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.pricing_coupon_success_message,
                        style: themeText.textCaption.copyWith(
                          color: themeColor.pricingDiscount,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                const SizedBox(height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dashed Line Painter ──────────────────────────────────────────────────────

class DashedLinePainter extends CustomPainter {
  final Color color;
  const DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    const double dashWidth = 5;
    const double dashSpace = 4;
    double startX = 14;
    while (startX < size.width - 14) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
