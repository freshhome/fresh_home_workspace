import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/reviews/entities/review_entity.dart';
import 'package:shared/domain/reviews/repositories/reviews_repository.dart';

class FetchServiceReviewsUseCase {
  final ReviewsRepository repository;

  FetchServiceReviewsUseCase(this.repository);

  Future<Either<Failure, List<ReviewEntity>>> call({
    required String serviceId,
    int? limit,
    int? offset,
  }) {
    return repository.fetchServiceReviews(
      serviceId: serviceId,
      limit: limit,
      offset: offset,
    );
  }
}
