import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/reviews/entities/review_entity.dart';
import 'package:shared/domain/reviews/repositories/reviews_repository.dart';

class FetchAdminReviewsUseCase {
  final ReviewsRepository repository;

  FetchAdminReviewsUseCase({required this.repository});

  Future<Either<Failure, List<ReviewEntity>>> call({
    String? status,
    int? limit,
    int? offset,
  }) async {
    return await repository.fetchAllReviews(
      status: status,
      limit: limit,
      offset: offset,
    );
  }
}
