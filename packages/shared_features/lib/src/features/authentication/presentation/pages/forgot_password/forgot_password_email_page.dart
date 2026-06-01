import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:shared/presentation/dialogs/dialog_helper.dart';
import 'package:shared/presentation/extensions/failure_extension.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/validators/input_validator.dart';
import 'package:shared/presentation/widget/animated_background/animated_background.dart';
import 'package:shared/presentation/widget/custom_text_form_field/base_text_form_field.dart';
import 'package:shared/presentation/widget/glass_container.dart';
import 'package:shared/presentation/widget/my_custom_button.dart';
import 'package:shared_features/src/features/authentication/presentation/authentication_presentation.dart';

class ForgotPasswordEmailPage extends StatefulWidget {
  const ForgotPasswordEmailPage({super.key});

  @override
  State<ForgotPasswordEmailPage> createState() =>
      _ForgotPasswordEmailPageState();
}

class _ForgotPasswordEmailPageState extends State<ForgotPasswordEmailPage> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          l10n.forgot_password,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Subtle Gradient Background (matching AuthScreen)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE0F2F1), Colors.white, Color(0xFFE3F2FD)],
              ),
            ),
          ),
          const AnimatedBackground(),

          BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is ResetPasswordSuccess) {
                DialogHelper.showSuccess(
                  context,
                  message: l10n.password_reset_sent_success,
                  onOkPress: () => Navigator.of(context).pop(),
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
                      BuildHeader(subtitle: l10n.forgot_password_subtitle),
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
                                l10n.login_email_label,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              BaseTextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: InputValidator.validateEmail,
                                hint: l10n.login_email_label,
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF6B7280),
                                ),
                                fillColor: Colors.white,
                                radius: 16,
                              ),
                              const SizedBox(height: 30),
                              MyCustomButton(
                                text: l10n.send_reset_link,
                                isLoading: state is AuthLoadingState,
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthCubit>().resetPassword(
                                      email: emailController.text.trim(),
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
