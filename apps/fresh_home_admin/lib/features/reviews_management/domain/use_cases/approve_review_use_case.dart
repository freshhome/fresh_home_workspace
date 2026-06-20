import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/reviews/repositories/reviews_repository.dart';

class ApproveReviewUseCase {
  final ReviewsRepository repository;

  ApproveReviewUseCase({required this.repository});

  Future<Either<Failure, void>> call({required String reviewId}) async {
    return await repository.approveReview(reviewId: reviewId);
  }
}
