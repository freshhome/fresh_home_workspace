import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:shared_features/shared_features.dart';

class SettingsRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: AppRoutes.settings,
      name: AppRoutes.settings,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => GetIt.instance<ProfileCubit>()),
          BlocProvider(create: (context) => GetIt.instance<SignOutCubit>()),
          BlocProvider(
            create: (context) => GetIt.instance<ThemeCubit>()..loadTheme(),
          ),
          BlocProvider(
            create: (context) =>
                GetIt.instance<LocaleCubit>()..loadSavedLocale(),
          ),
        ],
        child: const SettingsScreen(),
      ),
    ),
  ];
}
