import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/reviews/entities/review_entity.dart';
import '../../domain/use_cases/fetch_technician_reviews_use_case.dart';
import 'technician_reviews_state.dart';

class TechnicianReviewsCubit extends Cubit<TechnicianReviewsState> {
  final FetchTechnicianReviewsUseCase fetchTechnicianReviewsUseCase;

  TechnicianReviewsCubit({
    required this.fetchTechnicianReviewsUseCase,
  }) : super(TechnicianReviewsInitial());

  static const int _pageSize = 20;

  Future<void> fetchReviews({required String technicianId}) async {
    emit(TechnicianReviewsLoading());
    final result = await fetchTechnicianReviewsUseCase(
      technicianId: technicianId,
      limit: _pageSize,
      offset: 0,
    );
    result.fold(
      (failure) => emit(TechnicianReviewsError(message: failure.message)),
      (reviews) => emit(TechnicianReviewsLoaded(
        reviews: reviews,
        hasReachedMax: reviews.length < _pageSize,
      )),
    );
  }

  Future<void> fetchNextPage({required String technicianId}) async {
    final currentState = state;
    if (currentState is! TechnicianReviewsLoaded) return;
    if (currentState.isLoadingMore || currentState.hasReachedMax) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await fetchTechnicianReviewsUseCase(
      technicianId: technicianId,
      limit: _pageSize,
      offset: currentState.reviews.length,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(isLoadingMore: false)),
      (newReviews) {
        emit(currentState.copyWith(
          reviews: List<ReviewEntity>.from(currentState.reviews)..addAll(newReviews),
          isLoadingMore: false,
          hasReachedMax: newReviews.length < _pageSize,
        ));
      },
    );
  }
}
