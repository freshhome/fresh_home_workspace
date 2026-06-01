import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../pages/user_list_screen.dart';
import '../pages/user_detail_screen.dart';
import '../cubit/user_management_cubit.dart';
import '../cubit/user_detail_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/data/user/models/remote/user_remote_model.dart';

class UserManagementRoutes {
  static final List<GoRoute> routes = [
    GoRoute(
      path: AppRoutes.adminUserManagement,
      name: AppRoutes.adminUserManagement,
      builder: (context, state) => BlocProvider(
        create: (context) => GetIt.instance<UserManagementCubit>(),
        child: const UserListScreen(),
      ),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final user = state.extra as UserRemoteModel;
            return BlocProvider(
              create: (context) => GetIt.instance<UserDetailCubit>(),
              child: UserDetailScreen(user: user),
            );
          },
        ),
      ],
    ),
  ];
}
