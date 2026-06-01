import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/service/enums/pricing_method.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
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
  final ScrollController _scrollController = ScrollController();
  final Map<int, TextEditingController> _widthControllers = {};
  final Map<int, TextEditingController> _heightControllers = {};
  final Map<int, TextEditingController> _quantityControllers = {};

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
          final themeColor = Theme.of(
            context,
          ).extension<ThemeColorExtension>()!;
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
                    _buildAreaInput(l10n, themeText, themeColor)
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
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: themeText.textBodySecondary.copyWith(
                              color: Colors.red.shade800,
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
                  PriceBreakdownCard(pricing: state.price!, showHeader: true),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Area Input ─────────────────────────────────────────────────────────────

  Widget _buildAreaInput(
    AppLocalizations l10n,
    AppTextThemeExtension themeText,
    ThemeColorExtension themeColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pricing_area_label,
          style: themeText.titleSectionSmall.copyWith(
            color: const Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        _buildInputField(
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
                'الحد الأدنى للمحاسبة هو 100 متر مربع',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Buttons with beautiful premium UI
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
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
                        'حساب من أبعاد الشبابيك',
                        style: themeText.textCaption.copyWith(
                          color: state.useWindowsCalculator
                              ? Colors.white
                              : const Color(0xFF666666),
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
                        'إدخال إجمالي الأمتار',
                        style: themeText.textCaption.copyWith(
                          color: !state.useWindowsCalculator
                              ? Colors.white
                              : const Color(0xFF666666),
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
          _buildDirectLinearMetersInput(themeText, themeColor),
      ],
    );
  }

  Widget _buildDirectLinearMetersInput(
    AppTextThemeExtension themeText,
    ThemeColorExtension themeColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إجمالي الأمتار الطولية',
          style: themeText.textBodyPrimary.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: _totalLinearController,
          unit: 'متر طولي',
          onChanged: (val) {
            if (val.isEmpty) {
              context.read<BookingFlowCubit>().updateTotalLinearMeters(null);
            } else {
              context
                  .read<BookingFlowCubit>()
                  .updateTotalLinearMeters(double.tryParse(val));
            }
          },
          themeText: themeText,
          themeColor: themeColor,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: themeColor.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'أدخل عدد الأمتار الكلية لجميع الشبابيك التي تريد إزالة الاستيكر منها.',
                style: themeText.textCaption.copyWith(
                  color: themeColor.primary.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مقاسات الشبابيك',
          style: themeText.titleSectionSmall.copyWith(
            color: const Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'أدخل مقاسات كل شباك والعدد المطلوب بدقة.',
          style: themeText.textCaption.copyWith(color: const Color(0xFF999999)),
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.windows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final window = state.windows[index];
            return _buildWindowItem(index, window, themeText, themeColor);
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
                  'إضافة شباك آخر',
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
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'شباك رقم ${index + 1}',
                style: themeText.textBodySecondary.copyWith(
                  fontWeight: FontWeight.bold,
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
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SideToggleButton(
                    label: 'وجه واحد (داخلي)',
                    isSelected: !window.isBothSides,
                    onTap: () => context.read<BookingFlowCubit>().updateWindow(
                      index,
                      window.copyWith(isBothSides: false),
                    ),
                    themeText: themeText,
                    themeColor: themeColor,
                  ),
                ),
                Expanded(
                  child: _SideToggleButton(
                    label: 'وجهين (د+خ)',
                    isSelected: window.isBothSides,
                    onTap: () => context.read<BookingFlowCubit>().updateWindow(
                      index,
                      window.copyWith(isBothSides: true),
                    ),
                    themeText: themeText,
                    themeColor: themeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'العرض (م)',
                      style: themeText.textCaption.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    BaseTextFormField(
                      controller: _widthControllers[index],
                      keyboardType: TextInputType.number,
                      onChanged: (val) =>
                          context.read<BookingFlowCubit>().updateWindow(
                            index,
                            window.copyWith(width: double.tryParse(val) ?? 0),
                          ),
                      textAlign: TextAlign.center,
                      hint: "0",
                      radius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الطول (م)',
                      style: themeText.textCaption.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    BaseTextFormField(
                      controller: _heightControllers[index],
                      keyboardType: TextInputType.number,
                      onChanged: (val) =>
                          context.read<BookingFlowCubit>().updateWindow(
                            index,
                            window.copyWith(height: double.tryParse(val) ?? 0),
                          ),
                      textAlign: TextAlign.center,
                      hint: "0",
                      radius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'العدد',
                      style: themeText.textCaption.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    BaseTextFormField(
                      controller: _quantityControllers[index],
                      keyboardType: TextInputType.number,
                      onChanged: (val) =>
                          context.read<BookingFlowCubit>().updateWindow(
                            index,
                            window.copyWith(quantity: int.tryParse(val) ?? 1),
                          ),
                      textAlign: TextAlign.center,
                      hint: "1",
                      radius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Fixed Price Message ────────────────────────────────────────────────────

  Widget _buildFixedPriceMessage(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
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
              'هذه الخدمة بسعر ثابت، اضغط على زر "احسب السعر" لإظهار التفاصيل والانتقال للخطوة التالية.',
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
}

// ── Side Toggle Button ─────────────────────────────────────────────────────

class _SideToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppTextThemeExtension themeText;
  final ThemeColorExtension themeColor;

  const _SideToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.themeText,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: themeText.textCaption.copyWith(
              color: isSelected ? themeColor.primary : const Color(0xFF999999),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
