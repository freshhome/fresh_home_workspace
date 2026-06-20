import 'package:equatable/equatable.dart';
import 'package:shared/domain/reviews/entities/review_entity.dart';

abstract class ReviewsModerationState extends Equatable {
  const ReviewsModerationState();

  @override
  List<Object?> get props => [];
}

class ReviewsModerationInitial extends ReviewsModerationState {}

class ReviewsModerationLoading extends ReviewsModerationState {}

class ReviewsModerationLoaded extends ReviewsModerationState {
  final List<ReviewEntity> quarantinedReviews;
  final List<ReviewEntity> publishedReviews;
  final List<String> approvingReviewIds;
  final bool isLoadingMoreQuarantined;
  final bool isLoadingMorePublished;
  final bool hasReachedMaxQuarantined;
  final bool hasReachedMaxPublished;

  const ReviewsModerationLoaded({
    required this.quarantinedReviews,
    required this.publishedReviews,
    this.approvingReviewIds = const [],
    this.isLoadingMoreQuarantined = false,
    this.isLoadingMorePublished = false,
    this.hasReachedMaxQuarantined = false,
    this.hasReachedMaxPublished = false,
  });

  ReviewsModerationLoaded copyWith({
    List<ReviewEntity>? quarantinedReviews,
    List<ReviewEntity>? publishedReviews,
    List<String>? approvingReviewIds,
    bool? isLoadingMoreQuarantined,
    bool? isLoadingMorePublished,
    bool? hasReachedMaxQuarantined,
    bool? hasReachedMaxPublished,
  }) {
    return ReviewsModerationLoaded(
      quarantinedReviews: quarantinedReviews ?? this.quarantinedReviews,
      publishedReviews: publishedReviews ?? this.publishedReviews,
      approvingReviewIds: approvingReviewIds ?? this.approvingReviewIds,
      isLoadingMoreQuarantined: isLoadingMoreQuarantined ?? this.isLoadingMoreQuarantined,
      isLoadingMorePublished: isLoadingMorePublished ?? this.isLoadingMorePublished,
      hasReachedMaxQuarantined: hasReachedMaxQuarantined ?? this.hasReachedMaxQuarantined,
      hasReachedMaxPublished: hasReachedMaxPublished ?? this.hasReachedMaxPublished,
    );
  }

  @override
  List<Object?> get props => [
        quarantinedReviews,
        publishedReviews,
        approvingReviewIds,
        isLoadingMoreQuarantined,
        isLoadingMorePublished,
        hasReachedMaxQuarantined,
        hasReachedMaxPublished,
      ];
}

class ReviewsModerationError extends ReviewsModerationState {
  final String errorMessage;

  const ReviewsModerationError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
