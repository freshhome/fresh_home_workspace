import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';

class AddressFormComponents {
  static Widget buildLabeledField({
    Key? key,
    required String label,
    required BuildContext context,
    required Widget child,
  }) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
    
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Text(
            label,
            style: themeText.textCaption.copyWith(
              fontWeight: FontWeight.bold,
              color: themeColor.textPrimary.withValues(alpha: 0.7),
            ),
          ),
        ),
        child,
      ],
    );
  }

  static InputDecoration inputDecoration(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeColor.cardBorder.color),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeColor.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  static Widget buildSectionTitle(String title, BuildContext context) {
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
    return Text(
      title,
      style: themeText.titleSectionMedium.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
