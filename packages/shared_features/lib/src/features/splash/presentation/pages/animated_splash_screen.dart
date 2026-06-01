import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:shared/core/constants/app_assets.dart';
import 'package:shared_features/src/features/splash/presentation/cubit/splash_cubit.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  bool _startAnimation = false;
  bool _navigationTriggered = false; // علشان نضمن مايتنقلش مرتين
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();

    _startTime = DateTime.now();
    context.read<SplashCubit>().getCurrentUser();

    // نبدأ الأنيميشن بعد ثانيتين
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _startAnimation = true);
    });
  }

  void _navigateAfterDelay(VoidCallback navigate) async {
    final elapsed = DateTime.now().difference(_startTime!).inSeconds;
    final remaining = 5 - elapsed; // الفرق المتبقي للوصول لـ 5 ثواني
    if (remaining > 0) {
      await Future.delayed(Duration(seconds: remaining));
    }
    if (mounted && !_navigationTriggered) {
      _navigationTriggered = true;
      navigate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is SplashErrorState) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text((state.failure.message))));
        } else if (state is SplashUserLoggedInState) {
          _navigateAfterDelay(
            () => context.go(AppRoutes.home),
          );
        } else if (state is SplashUserPendingApprovalState) {
          _navigateAfterDelay(
            () => context.go(AppRoutes.pendingApproval),
          );
        } else if (state is SplashOnboardingState) {
          _navigateAfterDelay(
            () => context.go(AppRoutes.onboarding),
          );
        } else if (state is SplashUserNotLoggedInState) {
          _navigateAfterDelay(
            () => context.go(AppRoutes.login),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE9F7FE),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(AppAssets.splashAnimationLogo, height: 150),

              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0.0,
                  end: _startAnimation ? 1.0 : 0.0,
                ),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [value, value],
                        colors: const [Colors.white, Colors.transparent],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: SvgPicture.asset(
                      AppAssets.splashTextLogo,
                      width: 100,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
