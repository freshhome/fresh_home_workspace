import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/reviews/entities/review_entity.dart';
import 'package:shared/domain/reviews/repositories/reviews_repository.dart';

class FetchTechnicianReviewsUseCase {
  final ReviewsRepository repository;

  FetchTechnicianReviewsUseCase(this.repository);

  Future<Either<Failure, List<ReviewEntity>>> call({
    required String technicianId,
    int? limit,
    int? offset,
  }) {
    return repository.fetchTechnicianReviews(
      technicianId: technicianId,
      limit: limit,
      offset: offset,
    );
  }
}
