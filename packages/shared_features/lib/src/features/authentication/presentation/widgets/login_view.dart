import 'package:flutter/material.dart';

import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/widget/glass_container.dart';
import 'package:shared_features/src/features/authentication/presentation/authentication_presentation.dart';

class LoginView extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final void Function()? onBlueButtonPressed;
  final void Function()? onGrayButtonPressed;
  final void Function()? onGoogleSignInPressed;

  const LoginView({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onBlueButtonPressed,
    required this.onGrayButtonPressed,
    required this.onGoogleSignInPressed,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return buildBody(context);
  }

  Widget buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          children: [
            SizedBox(height: 40),
            BuildHeader(
              subtitle: AppLocalizations.of(context)!.login_intro_message,
            ),
            GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoginFormFields(
                    emailController: emailController,
                    passwordController: passwordController,
                  ),
                  const SizedBox(height: 20),
                  BuildButtonsSection(
                    blueButtonText: l10n.login_title,
                    authAction: l10n.login_signup_button,
                    questionText: l10n.login_dont_have_account,
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
