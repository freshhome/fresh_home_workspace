import 'package:flutter/material.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/validators/input_validator.dart';
import 'package:shared/presentation/widget/custom_text_form_field/base_text_form_field.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class NewAccountFormFields extends StatefulWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const NewAccountFormFields({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
  });

  @override
  State<NewAccountFormFields> createState() => _NewAccountFormFieldsState();
}

class _NewAccountFormFieldsState extends State<NewAccountFormFields> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textStyle = Theme.of(context).extension<AppTextThemeExtension>()!;
    final themeColor = context.themeColor;

    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${l10n.profile_first_name} & ${l10n.profile_last_name}",
            style: textStyle.titleSectionSmall,
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: BaseTextFormField(
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.person_outline,
                      color: themeColor.secondaryText,
                      size: 24,
                    ),
                  ),
                  fillColor: themeColor.cardBackground,
                  radius: 16,
                  controller: widget.firstNameController,
                  validator: InputValidator.validateEmpty,
                  hint: l10n.profile_first_name,
                  hintStyle: TextStyle(
                    color: themeColor.secondaryText.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BaseTextFormField(
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.person_outline,
                      color: themeColor.secondaryText,
                      size: 24,
                    ),
                  ),
                  fillColor: themeColor.cardBackground,
                  radius: 16,
                  controller: widget.lastNameController,
                  validator: InputValidator.validateEmpty,
                  hint: l10n.profile_last_name,
                  hintStyle: TextStyle(
                    color: themeColor.secondaryText.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(l10n.login_email_label, style: textStyle.titleSectionSmall),
          const SizedBox(height: 5),
          BaseTextFormField(
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.email_outlined,
                color: themeColor.secondaryText,
                size: 24,
              ),
            ),
            fillColor: themeColor.cardBackground,
            radius: 16,
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            validator: InputValidator.validateEmail,
            hint: l10n.login_email_label,
            hintStyle: TextStyle(
              color: themeColor.secondaryText.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),
          Text(l10n.login_password_label, style: textStyle.titleSectionSmall),
          const SizedBox(height: 5),
          BaseTextFormField(
            controller: widget.passwordController,
            validator: InputValidator.validateEmpty,
            hint: l10n.login_password_label,
            obscureText: _obscurePassword,
            fillColor: themeColor.cardBackground,
            radius: 16,
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.lock_outline,
                color: themeColor.secondaryText,
                size: 24,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: themeColor.secondaryText,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            hintStyle: TextStyle(
              color: themeColor.secondaryText.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
