import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/core/constants/app_routes.dart';
import '../profile_presentation.dart';

class ProfileRoutes {
  static final List<GoRoute> routes = [
    GoRoute(
      path: AppRoutes.profile,
      name: AppRoutes.profile,
      builder: (context, state) => BlocProvider.value(
        value: GetIt.instance<ProfileCubit>(),
        child: const ProfileDetailScreen(),
      ),
    ),
  ];
}
