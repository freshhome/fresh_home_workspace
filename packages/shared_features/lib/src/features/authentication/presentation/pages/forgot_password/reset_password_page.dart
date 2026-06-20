import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/presentation/dialogs/dialog_helper.dart';
import 'package:shared/presentation/extensions/failure_extension.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/widget/animated_background/animated_background.dart';
import 'package:shared/presentation/widget/custom_text_form_field/base_text_form_field.dart';
import 'package:shared/presentation/widget/glass_container.dart';
import 'package:shared/presentation/widget/my_custom_button.dart';
import 'package:shared_features/src/features/authentication/presentation/authentication_presentation.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeColor = context.themeColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: themeColor.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          l10n.auth_reset_password_title,
          style: TextStyle(
            color: themeColor.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: themeColor.background,
          ),
          const AnimatedBackground(),

          BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is UpdatePasswordSuccess) {
                DialogHelper.showSuccess(
                  context,
                  message: l10n.auth_reset_password_success,
                  onOkPress: () {
                    context.go('/login');
                  },
                );
              } else if (state is AuthErrorState) {
                DialogHelper.showError(
                  context,
                  message: state.failure.message.tr(context),
                );
              }
            },
            builder: (context, state) {
              return SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      BuildHeader(
                        subtitle: l10n.auth_reset_password_subtitle,
                      ),
                      const SizedBox(height: 20),
                      GlassContainer(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.login_password_label,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: themeColor.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              BaseTextFormField(
                                controller: passwordController,
                                obscureText: _obscurePassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.validation_password_required;
                                  }
                                  if (value.length < 6) {
                                    return l10n.validation_password_min_length;
                                  }
                                  return null;
                                },
                                hint: l10n.login_password_label,
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: themeColor.secondaryText,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: themeColor.secondaryText,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                fillColor: themeColor.cardBackground,
                                radius: 16,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                l10n.validation_retype_password,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: themeColor.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              BaseTextFormField(
                                controller: confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.validation_confirm_password_required;
                                  }
                                  if (value != passwordController.text) {
                                    return l10n.validation_passwords_match;
                                  }
                                  return null;
                                },
                                hint: l10n.validation_retype_password,
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: themeColor.secondaryText,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: themeColor.secondaryText,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                fillColor: themeColor.cardBackground,
                                radius: 16,
                              ),
                              const SizedBox(height: 30),
                              MyCustomButton(
                                text: l10n.auth_save_new_password,
                                isLoading: state is AuthLoadingState,
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthCubit>().updatePassword(
                                      newPassword: passwordController.text.trim(),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
