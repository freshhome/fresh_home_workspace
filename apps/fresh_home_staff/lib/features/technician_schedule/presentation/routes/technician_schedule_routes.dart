import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubit/smart_schedule_cubit.dart';
import '../pages/smart_schedule_page.dart';

class TechnicianScheduleRoutes {
  static const String smartSchedule = 'smart_schedule';

  static List<GoRoute> get routes => [
        GoRoute(
          path: '/smart-schedule',
          name: smartSchedule,
          builder: (context, state) => BlocProvider(
            create: (_) {
              final techId = GetIt.instance<SupabaseClient>().auth.currentUser?.id ?? '';
              return GetIt.instance<SmartScheduleCubit>()..loadSchedule(techId);
            },
            child: const SmartSchedulePage(),
          ),
        ),
      ];
}
