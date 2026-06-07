import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/dynamic_field.dart';
import 'package:shared/domain/service/entities/sub_entities/service_price.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/widget/custom_text_form_field/base_text_form_field.dart';

class DynamicFormRenderer extends StatelessWidget {
  final List<DynamicFieldEntity> fields;
  final Map<String, dynamic> values;
  final List<PriceOptionEntity> options;
  final List<String> selectedOptions;
  final Function(String key, dynamic value) onFieldChanged;
  final Function(String optionKey) onOptionToggled;

  const DynamicFormRenderer({
    super.key,
    required this.fields,
    required this.values,
    required this.options,
    required this.selectedOptions,
    required this.onFieldChanged,
    required this.onOptionToggled,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
    final locale = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...fields.map((field) {
          final dynamic val = values[field.id];
          final String label = field.label[locale] ?? field.label['ar'] ?? field.id;

          Widget fieldWidget;
          if (field.displayType == 'card_stepper' && field.type == DynamicFieldType.number) {
            fieldWidget = DynamicCardStepper(
              field: field,
              label: label,
              value: val != null ? (val as num).toDouble() : 0.0,
              onChanged: (double newVal) => onFieldChanged(field.id, newVal == 0.0 ? null : newVal),
              themeColor: themeColor,
              themeText: themeText,
              locale: locale,
            );
          } else if (field.displayType == 'card_toggle' && field.type == DynamicFieldType.toggle) {
            fieldWidget = DynamicCardToggle(
              field: field,
              label: label,
              value: val == true,
              onChanged: (bool newVal) => onFieldChanged(field.id, newVal),
              themeColor: themeColor,
              themeText: themeText,
              locale: locale,
            );
          } else {
            switch (field.type) {
              case DynamicFieldType.number:
                fieldWidget = DynamicNumberField(
                  field: field,
                  label: label,
                  value: val != null ? (val as num).toDouble() : null,
                  onChanged: (double? newVal) => onFieldChanged(field.id, newVal),
                  themeColor: themeColor,
                  themeText: themeText,
                );
                break;
              case DynamicFieldType.toggle:
                fieldWidget = DynamicToggleField(
                  field: field,
                  label: label,
                  value: val == true,
                  onChanged: (bool newVal) => onFieldChanged(field.id, newVal),
                  themeColor: themeColor,
                  themeText: themeText,
                );
                break;
              case DynamicFieldType.dropdown:
                fieldWidget = DynamicDropdownField(
                  field: field,
                  label: label,
                  value: val?.toString(),
                  onChanged: (String? newVal) => onFieldChanged(field.id, newVal),
                  themeColor: themeColor,
                  themeText: themeText,
                );
                break;
              case DynamicFieldType.optionsGroup:
                fieldWidget = const SizedBox.shrink();
                break;
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: fieldWidget,
          );
        }),
        if (options.isNotEmpty) ...[
          const SizedBox(height: 8),
          DynamicOptionsGroup(
            options: options,
            selectedOptions: selectedOptions,
            onOptionToggled: onOptionToggled,
            themeColor: themeColor,
            themeText: themeText,
            locale: locale,
          ),
        ]
      ],
    );
  }
}

// ── 1. Dynamic Number Field ──────────────────────────────────────────────────

class DynamicNumberField extends StatefulWidget {
  final DynamicFieldEntity field;
  final String label;
  final double? value;
  final ValueChanged<double?> onChanged;
  final ThemeColorExtension themeColor;
  final AppTextThemeExtension themeText;

  const DynamicNumberField({
    super.key,
    required this.field,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.themeColor,
    required this.themeText,
  });

  @override
  State<DynamicNumberField> createState() => _DynamicNumberFieldState();
}

class _DynamicNumberFieldState extends State<DynamicNumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null ? widget.value!.toStringAsFixed(0) : '',
    );
  }

  @override
  void didUpdateWidget(covariant DynamicNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != double.tryParse(_controller.text)) {
      _controller.text = widget.value != null ? widget.value!.toStringAsFixed(0) : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: widget.themeText.titleSectionSmall.copyWith(
            color: widget.themeColor.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: widget.themeColor.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.fromBorderSide(widget.themeColor.cardBorder),
            boxShadow: [widget.themeColor.cardShadow],
          ),
          child: BaseTextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            onChanged: (val) {
              if (val.isEmpty) {
                widget.onChanged(null);
              } else {
                widget.onChanged(double.tryParse(val));
              }
            },
            hint: '0.0',
            suffixText: widget.field.unit,
            fillColor: Colors.transparent,
          ),
        ),
        if (widget.field.min != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: widget.themeColor.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'الحد الأدنى المطلوب: ${widget.field.min!.toStringAsFixed(0)} ${widget.field.unit ?? ''}',
                  style: widget.themeText.textCaption.copyWith(
                    color: widget.themeColor.primary.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── 2. Dynamic Toggle Field ──────────────────────────────────────────────────

class DynamicToggleField extends StatelessWidget {
  final DynamicFieldEntity field;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ThemeColorExtension themeColor;
  final AppTextThemeExtension themeText;

  const DynamicToggleField({
    super.key,
    required this.field,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.themeColor,
    required this.themeText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: value ? themeColor.primary.withValues(alpha: 0.03) : themeColor.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: value ? themeColor.primary : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [themeColor.cardShadow],
          ),
          child: Row(
            children: [
              Icon(
                value ? Icons.check_box : Icons.check_box_outline_blank,
                color: value ? themeColor.primary : Colors.grey.shade400,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: themeText.textBodyPrimary.copyWith(
                    fontWeight: value ? FontWeight.bold : FontWeight.normal,
                    color: themeColor.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 3. Dynamic Dropdown Field ────────────────────────────────────────────────

class DynamicDropdownField extends StatelessWidget {
  final DynamicFieldEntity field;
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final ThemeColorExtension themeColor;
  final AppTextThemeExtension themeText;

  const DynamicDropdownField({
    super.key,
    required this.field,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.themeColor,
    required this.themeText,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final options = field.options ?? [];
    final bool isValidValue = options.any((opt) => opt.id == value);
    final String? effectiveVal = isValidValue ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: themeText.titleSectionSmall.copyWith(
            color: themeColor.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: ValueKey(effectiveVal),
          value: effectiveVal,
          isExpanded: true,
          onChanged: onChanged,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: themeColor.primary,
            size: 22,
          ),
          dropdownColor: themeColor.cardBackground,
          style: themeText.textBodyPrimary.copyWith(
            color: themeColor.textPrimary,
            fontFamily: 'Cairo',
            fontSize: 14,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: Icon(
              Icons.list_alt_rounded,
              color: themeColor.primary.withValues(alpha: 0.6),
              size: 20,
            ),
            hintText: locale == 'ar' ? 'اختر قيمة...' : 'Select value...',
            hintStyle: themeText.textCaption.copyWith(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: themeColor.unselectedItem.withValues(alpha: 0.4),
            ),
            fillColor: themeColor.cardBackground,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: themeColor.unselectedItem.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: themeColor.unselectedItem.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: themeColor.primary,
                width: 1.5,
              ),
            ),
          ),
          items: options.map((opt) {
            return DropdownMenuItem<String>(
              value: opt.id,
              child: Text(
                opt.label[locale] ?? opt.label['ar'] ?? opt.id,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeColor.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── 4. Dynamic Options Group ─────────────────────────────────────────────────

class DynamicOptionsGroup extends StatelessWidget {
  final List<PriceOptionEntity> options;
  final List<String> selectedOptions;
  final Function(String optionKey) onOptionToggled;
  final ThemeColorExtension themeColor;
  final AppTextThemeExtension themeText;
  final String locale;

  const DynamicOptionsGroup({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.onOptionToggled,
    required this.themeColor,
    required this.themeText,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale == 'ar' ? 'خيارات إضافية' : 'Extra Features',
          style: themeText.titleSectionSmall.copyWith(
            color: themeColor.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ...options.map((option) {
          final String key = option.key ?? '';
          final isSelected = selectedOptions.contains(key);

          // Dynamic label from backend or fallback to key
          String optionLabel = option.label?[locale] ?? option.label?['ar'] ?? key;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onOptionToggled(key),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? themeColor.primary.withValues(alpha: 0.03) : themeColor.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? themeColor.primary : Colors.grey.shade200,
                    width: 1.5,
                  ),
                  boxShadow: [themeColor.cardShadow],
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isSelected ? themeColor.primary : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        optionLabel,
                        style: themeText.textBodyPrimary.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: themeColor.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── 5. Helper Icon Builder ───────────────────────────────────────────────────

Widget _buildIcon(String? iconKey, Color color) {
  if (iconKey == null || iconKey.isEmpty) {
    return Icon(Icons.build_circle_outlined, color: color, size: 28);
  }
  if (iconKey.startsWith('http://') || iconKey.startsWith('https://')) {
    if (iconKey.endsWith('.svg')) {
      return SvgPicture.network(
        iconKey,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        width: 28,
        height: 28,
        placeholderBuilder: (_) => Icon(Icons.broken_image_outlined, color: color, size: 28),
      );
    } else {
      return Image.network(
        iconKey,
        color: color,
        width: 28,
        height: 28,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_outlined, color: color, size: 28),
      );
    }
  }
  
  switch (iconKey.toLowerCase()) {
    case 'sofa':
    case 'sofa_clean':
      return Icon(Icons.chair_rounded, color: color, size: 28);
    case 'armchair':
    case 'armchair_clean':
      return Icon(Icons.chair_alt_rounded, color: color, size: 28);
    case 'chair':
    case 'chair_clean':
    case 'dining_chair':
      return Icon(Icons.single_bed_rounded, color: color, size: 28);
    case 'electric':
    case 'bolt':
    case 'electric_bolt':
    case 'short_circuit':
      return Icon(Icons.bolt_rounded, color: color, size: 28);
    case 'install_chandelier':
    case 'chandelier':
      return Icon(Icons.light_rounded, color: color, size: 28);
    case 'plumbing':
    case 'water':
    case 'tap':
      return Icon(Icons.water_drop_rounded, color: color, size: 28);
    case 'carpentry':
    case 'wood':
    case 'hammer':
      return Icon(Icons.handyman_rounded, color: color, size: 28);
    default:
      return Icon(Icons.build_circle_outlined, color: color, size: 28);
  }
}

// ── 6. Dynamic Card Stepper Widget ───────────────────────────────────────────

class DynamicCardStepper extends StatelessWidget {
  final DynamicFieldEntity field;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ThemeColorExtension themeColor;
  final AppTextThemeExtension themeText;
  final String locale;

  const DynamicCardStepper({
    super.key,
    required this.field,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.themeColor,
    required this.themeText,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value > 0;
    final String? description =
        field.description?[locale] ?? field.description?['ar'];

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasValue
              ? themeColor.primary.withValues(alpha: 0.03)
              : themeColor.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.fromBorderSide(
            hasValue ? themeColor.highlightedcardBorder : themeColor.cardBorder,
          ),
          boxShadow: [themeColor.cardShadow],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon section
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasValue
                    ? themeColor.primary.withValues(alpha: 0.1)
                    : themeColor.unselectedItem.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _buildIcon(field.icon, hasValue ? themeColor.primary : themeColor.secondaryText),
            ),
            const SizedBox(width: 16),
            // Middle text section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: themeText.textBodyPrimary.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: themeColor.textPrimary,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: themeText.textCaption.copyWith(
                        color: themeColor.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (field.priceModifier != null && field.priceModifier! > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        locale == 'ar'
                            ? '${field.priceModifier!.toStringAsFixed(0)} ج.م / ${field.unit ?? "وحدة"}'
                            : '${field.priceModifier!.toStringAsFixed(0)} EGP / ${field.unit ?? "unit"}',
                        style: themeText.textCaption.copyWith(
                          color: themeColor.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Stepper buttons section
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: themeColor.nestedCardBackground,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: themeColor.unselectedItem.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus Button
                      IconButton(
                        onPressed: () {
                          final minVal = field.min?.toDouble() ?? 0.0;
                          if (value > minVal) {
                            onChanged(value - 1);
                          }
                        },
                        icon: const Icon(Icons.remove, size: 16),
                        color: value > (field.min?.toDouble() ?? 0.0)
                            ? themeColor.primary
                            : themeColor.secondaryText.withValues(alpha: 0.4),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      // Value Text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          value.toStringAsFixed(0),
                          style: themeText.textBodyPrimary.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: themeColor.textPrimary,
                          ),
                        ),
                      ),
                      // Plus Button
                      IconButton(
                        onPressed: () {
                          onChanged(value + 1);
                        },
                        icon: const Icon(Icons.add, size: 16),
                        color: themeColor.primary,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 7. Dynamic Card Toggle Widget ────────────────────────────────────────────

class DynamicCardToggle extends StatelessWidget {
  final DynamicFieldEntity field;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ThemeColorExtension themeColor;
  final AppTextThemeExtension themeText;
  final String locale;

  const DynamicCardToggle({
    super.key,
    required this.field,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.themeColor,
    required this.themeText,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final String? description =
        field.description?[locale] ?? field.description?['ar'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: value
                ? themeColor.primary.withValues(alpha: 0.03)
                : themeColor.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.fromBorderSide(
              value ? themeColor.highlightedcardBorder : themeColor.cardBorder,
            ),
            boxShadow: [themeColor.cardShadow],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon section
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: value
                      ? themeColor.primary.withValues(alpha: 0.1)
                      : themeColor.unselectedItem.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _buildIcon(field.icon, value ? themeColor.primary : themeColor.secondaryText),
              ),
              const SizedBox(width: 16),
              // Text and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: themeText.textBodyPrimary.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: themeColor.textPrimary,
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: themeText.textCaption.copyWith(
                          color: themeColor.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (field.priceModifier != null && field.priceModifier! > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColor.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          locale == 'ar'
                              ? '+ ${field.priceModifier!.toStringAsFixed(0)} ج.م'
                              : '+ ${field.priceModifier!.toStringAsFixed(0)} EGP',
                          style: themeText.textCaption.copyWith(
                            color: themeColor.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Selection indicator
              Icon(
                value ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                color: value ? themeColor.primary : themeColor.secondaryText.withValues(alpha: 0.4),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
