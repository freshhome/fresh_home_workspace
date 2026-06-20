import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/reviews/entities/review_entity.dart';
import '../../domain/use_cases/fetch_service_reviews_use_case.dart';
import 'service_reviews_state.dart';

class ServiceReviewsCubit extends Cubit<ServiceReviewsState> {
  final FetchServiceReviewsUseCase fetchServiceReviewsUseCase;

  ServiceReviewsCubit({
    required this.fetchServiceReviewsUseCase,
  }) : super(ServiceReviewsInitial());

  static const int _pageSize = 20;

  Future<void> fetchReviews({required String serviceId}) async {
    emit(ServiceReviewsLoading());
    final result = await fetchServiceReviewsUseCase(
      serviceId: serviceId,
      limit: _pageSize,
      offset: 0,
    );
    result.fold(
      (failure) => emit(ServiceReviewsError(message: failure.message)),
      (reviews) => emit(ServiceReviewsLoaded(
        reviews: reviews,
        hasReachedMax: reviews.length < _pageSize,
      )),
    );
  }

  Future<void> fetchNextPage({required String serviceId}) async {
    final currentState = state;
    if (currentState is! ServiceReviewsLoaded) return;
    if (currentState.isLoadingMore || currentState.hasReachedMax) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await fetchServiceReviewsUseCase(
      serviceId: serviceId,
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
