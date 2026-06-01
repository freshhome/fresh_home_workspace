import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'base_text_form_field.dart';
import 'functions/date_time_picker_helper.dart';

class MyTextFormFieldRido extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final double radius;
  final Color? fillColor;
  final Color? errorBorderColor;
  final Color? focusedBorderColor;
  final Color? enabledBorderColor;
  final TextStyle? hintStyle;
  final TextAlign? textAlign;
  final double? width;
  final List<String> options;
  final Function(String)? onSelectOption;
  final Function(String)? onChanged; // تعديل: onChanged تأخذ معلمة String

  const MyTextFormFieldRido({
    super.key,
    required this.hint,
    required this.controller,
    required this.options,
    this.validator,
    this.radius = 8,
    this.fillColor,
    this.enabledBorderColor,
    this.errorBorderColor,
    this.focusedBorderColor,
    this.hintStyle,
    this.textAlign,
    this.width,
    this.onSelectOption,
    this.onChanged, // تعديل هنا
  });

  @override
  Widget build(BuildContext context) {
    final ThemeColorExtension themeColors =
        Theme.of(context).extension<ThemeColorExtension>()!;
    return InkWell(
      onTap: () {
        pickDropdownOption(
          context,
          hint: hint,
          controller: controller,
          options: options,
          onSelectOption: (selectedOption) {
            // استخدام onChanged مع القيمة المحددة
            if (onChanged != null) {
              onChanged!(selectedOption);
            }
            if (onSelectOption != null) {
              onSelectOption!(selectedOption);
            }
          },
        );
      },
      child: BaseTextFormField(
        suffixIcon: Icon(
          Icons.arrow_drop_down_circle_outlined,
          color: themeColors.primary,
          size: 25,
        ),
        hint: hint,
        controller: controller,
        validator: validator,
        radius: radius,
        enabledBorderColor: enabledBorderColor,
        errorBorderColor: errorBorderColor,
        focusedBorderColor: focusedBorderColor,
        hintStyle: hintStyle,
        textAlign: textAlign,
        width: width,
        enabled: false, // لمنع الإدخال اليدوي
      ),
    );
  }
}
