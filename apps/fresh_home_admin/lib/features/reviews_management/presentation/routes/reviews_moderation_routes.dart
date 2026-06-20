import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../cubit/reviews_moderation_cubit.dart';
import '../pages/reviews_moderation_screen.dart';

class ReviewsModerationRoutes {
  static const String adminReviews = 'admin_reviews';

  static List<GoRoute> get routes => [
        GoRoute(
          path: '/admin-reviews',
          name: adminReviews,
          builder: (context, state) => BlocProvider(
            create: (_) => GetIt.instance<ReviewsModerationCubit>()..loadReviews(),
            child: const ReviewsModerationScreen(),
          ),
        ),
      ];
}
