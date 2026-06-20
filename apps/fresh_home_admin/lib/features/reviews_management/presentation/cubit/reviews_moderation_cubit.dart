import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/approve_review_use_case.dart';
import '../../domain/use_cases/fetch_admin_reviews_use_case.dart';
import 'reviews_moderation_state.dart';
import 'package:shared/domain/reviews/entities/review_entity.dart';

class ReviewsModerationCubit extends Cubit<ReviewsModerationState> {
  final FetchAdminReviewsUseCase fetchAdminReviewsUseCase;
  final ApproveReviewUseCase approveReviewUseCase;
  static const int _pageSize = 20;

  ReviewsModerationCubit({
    required this.fetchAdminReviewsUseCase,
    required this.approveReviewUseCase,
  }) : super(ReviewsModerationInitial());

  Future<void> loadReviews() async {
    emit(ReviewsModerationLoading());

    try {
      final results = await Future.wait([
        fetchAdminReviewsUseCase(status: 'quarantined', limit: _pageSize, offset: 0),
        fetchAdminReviewsUseCase(status: 'published', limit: _pageSize, offset: 0),
      ]);

      final quarantinedResult = results[0];
      final publishedResult = results[1];

      quarantinedResult.fold(
        (failure) => emit(ReviewsModerationError(errorMessage: failure.message)),
        (quarantinedList) {
          publishedResult.fold(
            (failure) => emit(ReviewsModerationError(errorMessage: failure.message)),
            (publishedList) {
              emit(ReviewsModerationLoaded(
                quarantinedReviews: List<ReviewEntity>.from(quarantinedList),
                publishedReviews: List<ReviewEntity>.from(publishedList),
                hasReachedMaxQuarantined: quarantinedList.length < _pageSize,
                hasReachedMaxPublished: publishedList.length < _pageSize,
              ));
            },
          );
        },
      );
    } catch (e) {
      emit(ReviewsModerationError(errorMessage: e.toString()));
    }
  }

  Future<void> fetchNextPage({required bool isQuarantined}) async {
    final currentState = state;
    if (currentState is! ReviewsModerationLoaded) return;

    if (isQuarantined) {
      if (currentState.isLoadingMoreQuarantined || currentState.hasReachedMaxQuarantined) return;
      emit(currentState.copyWith(isLoadingMoreQuarantined: true));

      final result = await fetchAdminReviewsUseCase(
        status: 'quarantined',
        limit: _pageSize,
        offset: currentState.quarantinedReviews.length,
      );

      result.fold(
        (failure) => emit(currentState.copyWith(isLoadingMoreQuarantined: false)),
        (newReviews) {
          emit(currentState.copyWith(
            quarantinedReviews: List<ReviewEntity>.from(currentState.quarantinedReviews)..addAll(newReviews),
            isLoadingMoreQuarantined: false,
            hasReachedMaxQuarantined: newReviews.length < _pageSize,
          ));
        },
      );
    } else {
      if (currentState.isLoadingMorePublished || currentState.hasReachedMaxPublished) return;
      emit(currentState.copyWith(isLoadingMorePublished: true));

      final result = await fetchAdminReviewsUseCase(
        status: 'published',
        limit: _pageSize,
        offset: currentState.publishedReviews.length,
      );

      result.fold(
        (failure) => emit(currentState.copyWith(isLoadingMorePublished: false)),
        (newReviews) {
          emit(currentState.copyWith(
            publishedReviews: List<ReviewEntity>.from(currentState.publishedReviews)..addAll(newReviews),
            isLoadingMorePublished: false,
            hasReachedMaxPublished: newReviews.length < _pageSize,
          ));
        },
      );
    }
  }

  Future<void> approveReview(String reviewId) async {
    final currentState = state;
    if (currentState is! ReviewsModerationLoaded) return;

    // Add to approving list
    final updatedApproving = List<String>.from(currentState.approvingReviewIds)..add(reviewId);
    emit(currentState.copyWith(approvingReviewIds: updatedApproving));

    final result = await approveReviewUseCase(reviewId: reviewId);

    result.fold(
      (failure) {
        // Remove from approving list on failure
        final failedApproving = List<String>.from(state is ReviewsModerationLoaded
            ? (state as ReviewsModerationLoaded).approvingReviewIds
            : currentState.approvingReviewIds)
          ..remove(reviewId);

        if (state is ReviewsModerationLoaded) {
          emit((state as ReviewsModerationLoaded).copyWith(approvingReviewIds: failedApproving));
        }
      },
      (_) {
        // Success: move review from quarantined to published locally
        if (state is! ReviewsModerationLoaded) return;
        final currentLoadedState = state as ReviewsModerationLoaded;

        final reviewToApproveIndex = currentLoadedState.quarantinedReviews.indexWhere((r) => r.id == reviewId);
        if (reviewToApproveIndex == -1) return;

        final reviewToApprove = currentLoadedState.quarantinedReviews[reviewToApproveIndex];

        // Create updated list of quarantined
        final updatedQuarantined = List<ReviewEntity>.from(currentLoadedState.quarantinedReviews)
          ..removeAt(reviewToApproveIndex);

        // Create a copy of review with published status
        final publishedReview = ReviewEntity(
          id: reviewToApprove.id,
          bookingId: reviewToApprove.bookingId,
          customerId: reviewToApprove.customerId,
          technicianId: reviewToApprove.technicianId,
          serviceId: reviewToApprove.serviceId,
          ratingValue: reviewToApprove.ratingValue,
          feedbackText: reviewToApprove.feedbackText,
          status: 'published',
          createdAt: reviewToApprove.createdAt,
          serviceTitle: reviewToApprove.serviceTitle,
          serviceImage: reviewToApprove.serviceImage,
          technicianFirstName: reviewToApprove.technicianFirstName,
          technicianLastName: reviewToApprove.technicianLastName,
          technicianAvatarUrl: reviewToApprove.technicianAvatarUrl,
          customerFirstName: reviewToApprove.customerFirstName,
          customerLastName: reviewToApprove.customerLastName,
          customerAvatarUrl: reviewToApprove.customerAvatarUrl,
        );

        // Add to published and sort
        final updatedPublished = List<ReviewEntity>.from(currentLoadedState.publishedReviews)
          ..add(publishedReview);
        updatedPublished.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Remove from approving list
        final finalApproving = List<String>.from(currentLoadedState.approvingReviewIds)..remove(reviewId);

        emit(ReviewsModerationLoaded(
          quarantinedReviews: updatedQuarantined,
          publishedReviews: updatedPublished,
          approvingReviewIds: finalApproving,
          isLoadingMoreQuarantined: currentLoadedState.isLoadingMoreQuarantined,
          isLoadingMorePublished: currentLoadedState.isLoadingMorePublished,
          hasReachedMaxQuarantined: currentLoadedState.hasReachedMaxQuarantined,
          hasReachedMaxPublished: currentLoadedState.hasReachedMaxPublished,
        ));
      },
    );
  }
}
