import 'package:equatable/equatable.dart';
import 'package:shared/domain/reviews/entities/review_entity.dart';

sealed class TechnicianReviewsState extends Equatable {
  const TechnicianReviewsState();

  @override
  List<Object?> get props => [];
}

final class TechnicianReviewsInitial extends TechnicianReviewsState {}

final class TechnicianReviewsLoading extends TechnicianReviewsState {}

final class TechnicianReviewsLoaded extends TechnicianReviewsState {
  final List<ReviewEntity> reviews;
  final bool isLoadingMore;
  final bool hasReachedMax;

  const TechnicianReviewsLoaded({
    required this.reviews,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
  });

  TechnicianReviewsLoaded copyWith({
    List<ReviewEntity>? reviews,
    bool? isLoadingMore,
    bool? hasReachedMax,
  }) {
    return TechnicianReviewsLoaded(
      reviews: reviews ?? this.reviews,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [reviews, isLoadingMore, hasReachedMax];
}

final class TechnicianReviewsError extends TechnicianReviewsState {
  final String message;
  const TechnicianReviewsError({required this.message});

  @override
  List<Object?> get props => [message];
}
