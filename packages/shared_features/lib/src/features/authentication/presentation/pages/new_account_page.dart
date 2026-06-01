import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:shared_features/src/features/authentication/presentation/authentication_presentation.dart';

class NewAccountPage extends StatefulWidget {
  const NewAccountPage({super.key});

  @override
  State<NewAccountPage> createState() => _NewAccountPageState();
}

class _NewAccountPageState extends State<NewAccountPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NewAccountView(
      emailController: emailController,
      firstNameController: firstNameController,
      lastNameController: lastNameController,
      passwordController: passwordController,
      formKey: formKey,
      onBlueButtonPressed: onBlueButtonPressed,
      onGrayButtonPressed: onGrayButtonPressed,
      onGoogleSignInPressed: onGoogleSignInPressed,
    );
  }

  void onBlueButtonPressed() {
    if (formKey.currentState!.validate()) {
      context.read<AuthCubit>().signUp(
        password: passwordController.text,
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        email: emailController.text,
      );
    }
  }

  void onGrayButtonPressed() {
    context.read<AuthCubit>().previousPage();
  }

  void onGoogleSignInPressed() {
    context.read<AuthCubit>().signInWithGoogle();
  }
}
