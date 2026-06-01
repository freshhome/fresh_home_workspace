import 'package:flutter/material.dart';
import 'base_text_form_field.dart';
import 'functions/date_time_picker_helper.dart'; // استيراد الملف الجديد

class MyTextFormFieldDate extends StatelessWidget {
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

  const MyTextFormFieldDate({
    super.key,
    required this.hint,
    required this.controller,
    this.validator,
    this.radius = 8,
    this.fillColor,
    this.enabledBorderColor,
    this.errorBorderColor,
    this.focusedBorderColor,
    this.hintStyle,
    this.textAlign,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => pickDate(context,
          controller: controller), // استخدام الفانكشن من الملف الجديد
      child: BaseTextFormField(
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
