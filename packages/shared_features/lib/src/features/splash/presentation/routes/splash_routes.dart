import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:shared_features/src/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:shared_features/src/features/splash/presentation/pages/animated_splash_screen.dart';

class SplashRoutes {
  static final List<GoRoute> routes = [
    GoRoute(
      path: AppRoutes.splash,
      name: AppRoutes.splash,
      builder: (context, state) => BlocProvider.value(
        value: GetIt.instance<SplashCubit>(),
        child: const AnimatedSplashScreen(),
      ),
    ),
  ];
}
