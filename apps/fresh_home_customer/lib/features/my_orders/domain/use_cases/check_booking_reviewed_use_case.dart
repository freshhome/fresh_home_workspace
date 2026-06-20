import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/reviews/repositories/reviews_repository.dart';

class CheckBookingReviewedUseCase {
  final ReviewsRepository repository;

  CheckBookingReviewedUseCase(this.repository);

  Future<Either<Failure, bool>> call({required String bookingId}) {
    return repository.isBookingReviewed(bookingId: bookingId);
  }
}
