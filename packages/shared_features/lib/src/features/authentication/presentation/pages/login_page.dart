import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_features/src/features/authentication/presentation/authentication_presentation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoginView(
      emailController: emailController,
      passwordController: passwordController,
      formKey: formKey,
      onBlueButtonPressed: onBlueButtonPressed,
      onGrayButtonPressed: onGrayButtonPressed,
      onGoogleSignInPressed: onGoogleSignInPressed,
    );
  }

  void onBlueButtonPressed() {
    if (formKey.currentState!.validate()) {
      context.read<AuthCubit>().signIn(
        email: emailController.text,
        password: passwordController.text,
      );
    }
  }

  void onGrayButtonPressed() {
    context.read<AuthCubit>().nextPage();
  }

  void onGoogleSignInPressed() {
    context.read<AuthCubit>().signInWithGoogle();
  }
}
