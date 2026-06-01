import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class MyCustomButton extends StatelessWidget {
  final String text;
  final void Function()? onPressed;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Gradient? gradient;
  final double borderRadius;
  final TextStyle? textStyle;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isOutlined;
  final Color? borderColor;
  final bool isLoading;

  const MyCustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 56,
    this.backgroundColor,
    this.gradient,
    this.borderRadius = 16,
    this.textStyle,
    this.leadingIcon,
    this.trailingIcon,
    this.isOutlined = false,
    this.borderColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    
    // Default Gradient from Theme
    final defaultGradient = themeColor.buttonGradient;

    return Opacity(
      opacity: isDisabled ? 0.6 : 1.0,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : (backgroundColor ?? (gradient == null && !isOutlined ? const Color(0xFF0085FF) : null)),
          gradient: isOutlined ? null : (gradient ?? (backgroundColor == null ? defaultGradient : null)),
          borderRadius: BorderRadius.circular(borderRadius),
          border: isOutlined ? Border.all(color: borderColor ?? const Color(0xFF0D327D), width: 2) : null,
          boxShadow: isDisabled || isOutlined
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF0D327D).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: EdgeInsets.zero,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leadingIcon != null) ...[
                      leadingIcon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: textStyle ??
                          TextStyle(
                            color: isOutlined ? (borderColor ?? const Color(0xFF0D327D)) : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      trailingIcon!,
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
