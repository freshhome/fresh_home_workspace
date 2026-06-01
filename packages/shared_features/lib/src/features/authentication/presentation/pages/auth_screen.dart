import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:shared/core/constants/app_routes.dart';
import 'package:shared/presentation/dialogs/dialog_helper.dart';
import 'package:shared/presentation/extensions/failure_extension.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/widget/animated_background/animated_background.dart';
import 'package:shared_features/src/features/authentication/presentation/authentication_presentation.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late PageController _pageController;
  @override
  void initState() {
    super.initState();
    _pageController = context.read<AuthCubit>().pageController;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: listener,
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              // Subtle Gradient Background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE0F2F1), // Very light teal
                      Colors.white,
                      Color(0xFFE3F2FD), // Very light blue
                    ],
                  ),
                ),
              ),
              const AnimatedBackground(),
              Column(
                children: [
                  Expanded(
                    child: PageView(
                      physics: NeverScrollableScrollPhysics(),
                      controller: _pageController,

                      children: [LoginPage(), NewAccountPage()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void listener(BuildContext context, AuthState state) {
    final l10n = AppLocalizations.of(context)!;

    /// 1️⃣ Loading
    if (state is AuthLoadingState) {
      DialogHelper.showLoading(context);
      return;
    }

    /// اقفل أي Loading قبل أي Dialog
    DialogHelper.dismissLoading(context);

    /// 2️⃣ Resend verification success
    if (state is ResendVerificationSuccess) {
      DialogHelper.showSuccess(
        context,
        message: 'verification_email_sent'.tr(context),
      );
      return;
    }

    /// 3️⃣ Errors
    if (state is AuthErrorState) {
      print("------------------------------------------------");
      print(state.failure.message);
      print("------------------------------------------------");
      if (state.failure.code == 'email_not_verified') {
        DialogHelper.show(
          context,
          dialogType: DialogType.warning,
          title: 'email_not_verified'.tr(context),
          desc: 'please_verify_email_desc'.tr(context),
          onCancelPress: () {},
          onOkPress: () {
            context.read<AuthCubit>().resendVerificationCode();
          },
        );
        return;
      }

      DialogHelper.showError(
        context,
        message: state.failure.message.tr(context),
      );
      return;
    }

    /// 4️⃣ Success (Login / Google / SignUp)
    if (state is SignInSuccess || state is SignUpSuccess) {
      debugPrint('🎉 [AuthScreen] Success state detected: ${state.runtimeType}');
      bool navigationTriggered = false;

      void triggerNavigation() {
        if (navigationTriggered || !context.mounted) return;
        navigationTriggered = true;

        if (state is SignUpSuccess) {
          debugPrint('📝 [AuthScreen] Redirecting to LoginPage (index 0)');
          context.read<AuthCubit>().goToPage(0);
        } else {
          debugPrint('🏠 [AuthScreen] Redirecting to HOME');
          // إغلاق أي حوار مفتوح (سواء التحميل أو حوار النجاح) بشكل آمن لتفادي تعليق الشاشة
          Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
          context.go(AppRoutes.home);
        }
      }

      DialogHelper.showSuccess(
        context,
        message: state is SignUpSuccess
            ? l10n.signup_success_message
            : l10n.login_success_message,
        onOkPress: triggerNavigation,
        onDismiss: (_) => triggerNavigation(),
      );

      /// Auto navigation بعد ثانيتين
      Future.delayed(const Duration(seconds: 2), () {
        if (!navigationTriggered && context.mounted) {
          debugPrint('⏱️ [AuthScreen] Auto-redirecting after delay');
          triggerNavigation();
        }
      });
    }

    /// 5️⃣ Pending Role Approval
    if (state is AuthPendingRoleState) {
      debugPrint('⏳ [AuthScreen] Pending Role state detected - Redirecting to PendingApprovalPage');
      context.go(AppRoutes.pendingApproval);
    }
  }
}
