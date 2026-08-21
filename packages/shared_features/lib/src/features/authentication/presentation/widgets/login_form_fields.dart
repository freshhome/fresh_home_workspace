import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/validators/input_validator.dart';
import 'package:shared/presentation/widget/custom_text_form_field/base_text_form_field.dart';


import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class LoginFormFields extends StatefulWidget {
  final TextEditingController? emailController;
  final TextEditingController? passwordController;
  final VoidCallback? onSubmitted;

  const LoginFormFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    this.onSubmitted,
  });

  @override
  State<LoginFormFields> createState() => _LoginFormFieldsState();
}

class _LoginFormFieldsState extends State<LoginFormFields> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).extension<AppTextThemeExtension>()!;
    final l10n = AppLocalizations.of(context)!; 
    final themeColor = context.themeColor;

    return Container(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.login_email_label, style: textTheme.titleSectionSmall),
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
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (v) => InputValidator.validateEmail(v, l10n: l10n),
            hint: l10n.login_email_label,
            hintStyle: TextStyle(
              color: themeColor.secondaryText.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),
          Text(l10n.login_password_label, style: textTheme.titleSectionSmall),
          const SizedBox(height: 5),

          BaseTextFormField(
            controller: widget.passwordController,
            validator: (v) => InputValidator.validatePassword(v, l10n: l10n),
            hint: l10n.login_password_label,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => widget.onSubmitted?.call(),
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
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                context.pushNamed(AppRoutes.forgotPassword);
              },
              child: Text(
                l10n.forgot_password,
                style: textTheme.textBodySecondary.copyWith(
                  color: themeColor.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
