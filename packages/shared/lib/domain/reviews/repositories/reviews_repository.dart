import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../entities/review_entity.dart';

abstract class ReviewsRepository {
  Future<Either<Failure, String>> submitReview({
    required String bookingId,
    required int ratingValue,
    String? feedbackText,
  });

  Future<Either<Failure, bool>> isBookingReviewed({
    required String bookingId,
  });

  Future<Either<Failure, List<ReviewEntity>>> fetchServiceReviews({
    required String serviceId,
    int? limit,
    int? offset,
  });

  Future<Either<Failure, List<ReviewEntity>>> fetchTechnicianReviews({
    required String technicianId,
    int? limit,
    int? offset,
  });

  Future<Either<Failure, List<ReviewEntity>>> fetchAllReviews({
    String? status,
    int? limit,
    int? offset,
  });

  Future<Either<Failure, void>> approveReview({
    required String reviewId,
  });
}


