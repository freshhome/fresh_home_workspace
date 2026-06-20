import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/reviews/repositories/reviews_repository.dart';

class SubmitReviewUseCase {
  final ReviewsRepository repository;

  SubmitReviewUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String bookingId,
    required int ratingValue,
    String? feedbackText,
  }) {
    return repository.submitReview(
      bookingId: bookingId,
      ratingValue: ratingValue,
      feedbackText: feedbackText,
    );
  }
}
