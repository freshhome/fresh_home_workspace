import 'package:flutter/material.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/widget/glass_container.dart';
import 'package:shared_features/src/features/authentication/presentation/authentication_presentation.dart';

class NewAccountView extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Function() onBlueButtonPressed;
  final Function() onGrayButtonPressed;
  final Function()? onGoogleSignInPressed;

  final GlobalKey<FormState> formKey;

  const NewAccountView({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.onBlueButtonPressed,
    required this.onGrayButtonPressed,
    this.onGoogleSignInPressed,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          children: [
            const SizedBox(height: 40),
            BuildHeader(subtitle: l10n.login_signup_button),
            GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NewAccountFormFields(
                    firstNameController: firstNameController,
                    lastNameController: lastNameController,
                    emailController: emailController,
                    passwordController: passwordController,
                  ),
                  const SizedBox(height: 20),
                  BuildButtonsSection(
                    authAction: l10n.login_title,
                    blueButtonText: l10n.login_signup_button,
                    questionText: l10n.login_already_have_account,
                    onBlueButtonPressed: onBlueButtonPressed,
                    onGrayButtonPressed: onGrayButtonPressed,
                    onGoogleSignInPressed: onGoogleSignInPressed,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
