import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_features/shared_features.dart';
import '../pages/my_reviews_screen.dart';
import '../cubit/technician_reviews_cubit.dart';

class TechnicianReviewsRoutes {
  static const String technicianReviews = 'technician_reviews';

  static final List<RouteBase> routes = [
    GoRoute(
      path: '/technician-reviews',
      name: technicianReviews,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider<TechnicianReviewsCubit>(
            create: (context) => GetIt.instance<TechnicianReviewsCubit>(),
          ),
          BlocProvider<ProfileCubit>.value(
            value: GetIt.instance<ProfileCubit>()..load(),
          ),
        ],
        child: const MyReviewsScreen(),
      ),
    ),
  ];
}
