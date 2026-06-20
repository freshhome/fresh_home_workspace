import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/reviews/entities/review_entity.dart';
import 'package:shared/domain/reviews/repositories/reviews_repository.dart';
import '../datasources/reviews_remote_datasource.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  final ReviewsRemoteDataSource remoteDataSource;

  ReviewsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> submitReview({
    required String bookingId,
    required int ratingValue,
    String? feedbackText,
  }) async {
    try {
      final reviewId = await remoteDataSource.submitReview(
        bookingId: bookingId,
        ratingValue: ratingValue,
        feedbackText: feedbackText,
      );
      return Right(reviewId);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isBookingReviewed({
    required String bookingId,
  }) async {
    try {
      final exists = await remoteDataSource.isBookingReviewed(bookingId: bookingId);
      return Right(exists);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReviewEntity>>> fetchServiceReviews({
    required String serviceId,
    int? limit,
    int? offset,
  }) async {
    try {
      final models = await remoteDataSource.fetchServiceReviews(
        serviceId: serviceId,
        limit: limit,
        offset: offset,
      );
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReviewEntity>>> fetchTechnicianReviews({
    required String technicianId,
    int? limit,
    int? offset,
  }) async {
    try {
      final models = await remoteDataSource.fetchTechnicianReviews(
        technicianId: technicianId,
        limit: limit,
        offset: offset,
      );
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReviewEntity>>> fetchAllReviews({
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final models = await remoteDataSource.fetchAllReviews(
        status: status,
        limit: limit,
        offset: offset,
      );
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveReview({required String reviewId}) async {
    try {
      await remoteDataSource.approveReview(reviewId: reviewId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}


