import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/use_cases/submit_review_use_case.dart';
import '../../domain/use_cases/check_booking_reviewed_use_case.dart';

part 'submit_review_state.dart';

class SubmitReviewCubit extends Cubit<SubmitReviewState> {
  final SubmitReviewUseCase submitReviewUseCase;
  final CheckBookingReviewedUseCase checkBookingReviewedUseCase;

  SubmitReviewCubit({
    required this.submitReviewUseCase,
    required this.checkBookingReviewedUseCase,
  }) : super(SubmitReviewInitial());

  Future<void> checkIfReviewed({required String bookingId}) async {
    emit(CheckReviewStatusLoading());
    final result = await checkBookingReviewedUseCase(bookingId: bookingId);
    result.fold(
      (failure) => emit(CheckReviewStatusFailure(message: failure.message)),
      (isReviewed) => emit(CheckReviewStatusSuccess(isReviewed: isReviewed)),
    );
  }

  Future<void> submitReview({
    required String bookingId,
    required int ratingValue,
    String? feedbackText,
  }) async {
    emit(SubmitReviewLoading());
    final result = await submitReviewUseCase(
      bookingId: bookingId,
      ratingValue: ratingValue,
      feedbackText: feedbackText,
    );
    result.fold(
      (failure) => emit(SubmitReviewFailure(message: failure.message)),
      (reviewId) => emit(SubmitReviewSuccess(reviewId: reviewId)),
    );
  }
}
