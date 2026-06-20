import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:fresh_home_admin/features/whatsapp_settings/presentation/pages/whatsapp_settings_page.dart';
import 'package:fresh_home_admin/features/whatsapp_settings/presentation/cubit/whatsapp_settings_cubit.dart';

class HomeRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: AppRoutes.home,
      redirect: (context, state) => AppRoutes.tabHome,
    ),
    GoRoute(
      path: '/admin/whatsapp-settings',
      name: 'admin_whatsapp_settings',
      builder: (context, state) => BlocProvider(
        create: (context) => GetIt.instance<WhatsAppSettingsCubit>(),
        child: const WhatsAppSettingsPage(),
      ),
    ),
  ];
}
