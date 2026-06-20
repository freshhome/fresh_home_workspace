import 'package:equatable/equatable.dart';
import 'package:shared/domain/reviews/entities/review_entity.dart';

sealed class ServiceReviewsState extends Equatable {
  const ServiceReviewsState();

  @override
  List<Object?> get props => [];
}

final class ServiceReviewsInitial extends ServiceReviewsState {}

final class ServiceReviewsLoading extends ServiceReviewsState {}

final class ServiceReviewsLoaded extends ServiceReviewsState {
  final List<ReviewEntity> reviews;
  final bool isLoadingMore;
  final bool hasReachedMax;

  const ServiceReviewsLoaded({
    required this.reviews,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
  });

  ServiceReviewsLoaded copyWith({
    List<ReviewEntity>? reviews,
    bool? isLoadingMore,
    bool? hasReachedMax,
  }) {
    return ServiceReviewsLoaded(
      reviews: reviews ?? this.reviews,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [reviews, isLoadingMore, hasReachedMax];
}

final class ServiceReviewsError extends ServiceReviewsState {
  final String message;
  const ServiceReviewsError({required this.message});

  @override
  List<Object?> get props => [message];
}
