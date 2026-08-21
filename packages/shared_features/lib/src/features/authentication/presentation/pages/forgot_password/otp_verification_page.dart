import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:shared/core/constants/app_routes.dart';
import 'package:shared/presentation/dialogs/dialog_helper.dart';
import 'package:shared/presentation/extensions/failure_extension.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/widget/animated_background/animated_background.dart';
import 'package:shared/presentation/widget/glass_container.dart';
import 'package:shared/presentation/widget/my_custom_button.dart';
import 'package:shared_features/src/features/authentication/presentation/authentication_presentation.dart';

class OtpVerificationPage extends StatefulWidget {
  final String? email;
  const OtpVerificationPage({super.key, this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    setState(() {
      _resendCooldown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      if (digits.length >= 6) {
        _focusNodes[5].unfocus();
        _submitOtp();
      } else {
        _focusNodes[digits.length].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _submitOtp();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _submitOtp() {
    final code = _otpCode.trim();
    if (code.length < 6) {
      DialogHelper.showError(
        context,
        message: 'يرجى إدخال رمز التحقق المكون من 6 أرقام كاملاً',
      );
      return;
    }
    context.read<AuthCubit>().verifyRecoveryOtp(otp: code, email: widget.email);
  }

  void _resendCode() {
    if (_resendCooldown > 0) return;
    if (widget.email != null && widget.email!.isNotEmpty) {
      context.read<AuthCubit>().resetPassword(email: widget.email!);
      _startCooldownTimer();
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final displayEmail = widget.email ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: themeColor.textPrimary),
            onPressed: () => _handleBack(context),
          ),
          title: Text(
            'رمز التحقق',
            style: TextStyle(
              color: themeColor.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(color: themeColor.background),
            const AnimatedBackground(),
            BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is OtpVerificationSuccess) {
                  // Navigate to Reset Password Screen
                  context.go(AppRoutes.resetPassword);
                } else if (state is AuthErrorState) {
                  DialogHelper.showError(
                    context,
                    message: state.failure.message.tr(context),
                  );
                } else if (state is ResetPasswordSuccess) {
                  DialogHelper.showSuccess(
                    context,
                    message: 'تم إعادة إرسال رمز التحقق إلى بريدك بنجاح',
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoadingState;

                return SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const BuildHeader(
                          subtitle:
                              'أدخل رمز التحقق المكون من 6 أرقام المكون بالبريد',
                        ),
                        if (displayEmail.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'تم إرسال الرمز إلى: $displayEmail',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: themeColor.secondaryText),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        GlassContainer(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'أدخل رمز OTP',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: themeColor.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Row(
                                  children: List.generate(6, (index) {
                                    return Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        height: 52,
                                        child: TextField(
                                          controller: _controllers[index],
                                          focusNode: _focusNodes[index],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          maxLength: 1,
                                          enabled: !isLoading,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: themeColor.textPrimary,
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: InputDecoration(
                                            counterText: '',
                                            contentPadding: EdgeInsets.zero,
                                            fillColor:
                                                themeColor.cardBackground,
                                            filled: true,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color:
                                                    themeColor.cardBorder.color,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: themeColor.primary,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          onChanged: (val) =>
                                              _onDigitChanged(index, val),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 30),
                              MyCustomButton(
                                text: 'تأكيد الرمز',
                                isLoading: isLoading,
                                onPressed: _submitOtp,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'لم يصلك الرمز؟ ',
                                    style: TextStyle(
                                      color: themeColor.secondaryText,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _resendCooldown == 0
                                        ? _resendCode
                                        : null,
                                    child: Text(
                                      _resendCooldown > 0
                                          ? 'إعادة الإرسال خلال ($_resendCooldown ثانية)'
                                          : 'إعادة إرسال الرمز',
                                      style: TextStyle(
                                        color: _resendCooldown == 0
                                            ? themeColor.primary
                                            : themeColor.secondaryText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
      ),
    );
  }
}
