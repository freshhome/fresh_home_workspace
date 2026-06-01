import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';

class BaseTextFormField extends StatefulWidget {
  /// ✅ النص التوضيحي الذي يظهر داخل حقل الإدخال عندما يكون فارغاً
  final String hint;
  
  /// ✅ تحديد ما إذا كان حقل الإدخال سيحصل على التركيز تلقائياً عند فتح الشاشة
  final bool autofocus;
  
  /// ✅ نوع لوحة المفاتيح التي ستظهر عند الكتابة (نص، أرقام، بريد إلكتروني، إلخ)
  final TextInputType keyboardType;
  
  /// ✅ تفعيل أو تعطيل حقل الإدخال (إذا كان معطل لن يستطيع المستخدم الكتابة فيه)
  final bool enabled;
  
  /// ✅ تنسيق النص التوضيحي (الخط، الحجم، اللون، إلخ)
  final TextStyle? hintStyle;
  
  /// ✅ مقدار انحناء زوايا حقل الإدخال بالبكسل
  final double radius;
  
  /// ✅ دالة التحقق من صحة المدخلات (مثل التحقق من البريد الإلكتروني أو كلمة المرور)
  final FormFieldValidator<String>? validator;
  
  /// ✅ دالة يتم استدعاؤها عند تغيير النص في حقل الإدخال
  final Function(String)? onChanged;
  
  /// ✅ متحكم النص للتحكم في قيمة حقل الإدخال من خارج الويدجت
  final TextEditingController? controller;
  
  /// ✅ إخفاء النص المكتوب (يستخدم لحقول كلمات المرور)
  final bool obscureText;
  
  /// ✅ لون حدود حقل الإدخال عند وجود خطأ في التحقق
  final Color? errorBorderColor;
  
  /// ✅ لون حدود حقل الإدخال عندما يكون نشطاً (عند الكتابة فيه)
  final Color? focusedBorderColor;
  
  /// ✅ لون حدود حقل الإدخال في الحالة العادية (غير نشط وبدون أخطاء)
  final Color? enabledBorderColor;

  /// ✅ أيقونة أو ويدجت يظهر في نهاية حقل الإدخال (مثل أيقونة إظهار/إخفاء كلمة المرور)
  final Widget? suffixIcon;
  
  /// ✅ ويدجت مخصص يظهر في نهاية حقل الإدخال بعد النص المكتوب
  final Widget? suffix;
  
  /// ✅ أيقونة أو ويدجت يظهر في بداية حقل الإدخال (مثل أيقونة البريد الإلكتروني)
  final Widget? prefixIcon;
  
  /// ✅ محاذاة النص داخل حقل الإدخال (يمين، يسار، وسط)
  final TextAlign? textAlign;
  
  /// ✅ عرض حقل الإدخال بالبكسل (إذا لم يتم تحديده سيأخذ العرض الكامل المتاح)
  final double? width;
  
  /// ✅ عدد الأسطر المسموح بها في حقل الإدخال (1 لسطر واحد، أكثر من 1 لحقل متعدد الأسطر)
  final int? maxLines;
  
  /// ✅ لون الخلفية الداخلية لحقل الإدخال (اللون اللي بيملي الحقل من جوه الحدود)
  final Color? fillColor;

  /// ✅ القيمة الابتدائية لحقل الإدخال
  final String? initialValue;

  /// ✅ جعل حقل الإدخال للقراءة فقط
  final bool readOnly;

  /// ✅ متحكم التركيز
  final FocusNode? focusNode;

  /// ✅ نص يظهر في نهاية حقل الإدخال (مثل العملة أو الوحدة)
  final String? suffixText;

  const BaseTextFormField({
    super.key,
    required this.hint,
    this.autofocus = false,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.readOnly = false,
    this.hintStyle,
    this.radius = 8,
    this.validator,
    this.onChanged,
    this.controller,
    this.obscureText = false,
    this.enabledBorderColor,
    this.suffixIcon,
    this.suffix,
    this.prefixIcon,
    this.errorBorderColor,
    this.focusedBorderColor,
    this.textAlign,
    this.width,
    this.maxLines = 1,
    this.fillColor,
    this.initialValue,
    this.focusNode,
    this.suffixText,
  });

  @override
  State<BaseTextFormField> createState() => _BaseTextFormFieldState();
}

class _BaseTextFormFieldState extends State<BaseTextFormField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(BaseTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      // ✅ تحريك المؤشر إلى نهاية النص عند الحصول على التركيز
      if (widget.controller != null && widget.controller!.text.isNotEmpty) {
        widget.controller!.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller!.text.length),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themetext = Theme.of(context).extension<AppTextThemeExtension>()!;
    return SizedBox(
      width: widget.width ?? double.infinity,
      child: TextFormField(
        onTap: () {
          // ✅ التأكد من وضع المؤشر في النهاية حتى عند الضغط اليدوي
          if (widget.controller != null && widget.controller!.text.isNotEmpty) {
            widget.controller!.selection = TextSelection.fromPosition(
              TextPosition(offset: widget.controller!.text.length),
            );
          }
        },
        onChanged: widget.onChanged,
        textAlign: widget.textAlign ?? TextAlign.start,
        controller: widget.controller,
        focusNode: _focusNode,
        initialValue: widget.initialValue,
        obscureText: widget.obscureText,
        validator: widget.validator,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          filled: true,
          fillColor: widget.fillColor ?? Colors.transparent,
          suffixIcon: widget.suffixIcon,
          suffix: widget.suffix,
          suffixText: widget.suffixText,
          suffixStyle: themetext.textBodyPrimary.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14),
          prefixIcon: widget.prefixIcon,
          hintText: widget.hint,
          hintStyle: widget.hintStyle ?? themetext.textBodyPrimary,
          enabledBorder: widget.enabledBorderColor != null 
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.radius),
                  borderSide: BorderSide(color: widget.enabledBorderColor!),
                )
              : null,
          focusedBorder: widget.focusedBorderColor != null
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.radius),
                  borderSide: BorderSide(color: widget.focusedBorderColor!, width: 2),
                )
              : null,
          errorBorder: widget.errorBorderColor != null
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.radius),
                  borderSide: BorderSide(color: widget.errorBorderColor!),
                )
              : null,
          focusedErrorBorder: widget.errorBorderColor != null
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.radius),
                  borderSide: BorderSide(color: widget.errorBorderColor!, width: 2),
                )
              : null,
          border: widget.fillColor == Colors.transparent && widget.enabledBorderColor == null 
              ? InputBorder.none 
              : OutlineInputBorder(borderRadius: BorderRadius.circular(widget.radius)),
        ),
      ),
    );
  }
}
