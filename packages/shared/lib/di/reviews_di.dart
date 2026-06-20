import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/data/reviews/datasources/reviews_remote_datasource.dart';
import 'package:shared/data/reviews/repositories/reviews_repository_impl.dart';
import 'package:shared/domain/reviews/repositories/reviews_repository.dart';

void setupReviewsDI(GetIt getIt) {
  // Remote Data Source
  getIt.registerLazySingleton<ReviewsRemoteDataSource>(
    () => ReviewsRemoteDataSourceImpl(supabase: getIt<SupabaseClient>()),
  );

  // Repository
  getIt.registerLazySingleton<ReviewsRepository>(
    () => ReviewsRepositoryImpl(remoteDataSource: getIt<ReviewsRemoteDataSource>()),
  );
}
