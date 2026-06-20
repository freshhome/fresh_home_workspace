part of 'submit_review_cubit.dart';

abstract class SubmitReviewState extends Equatable {
  const SubmitReviewState();

  @override
  List<Object?> get props => [];
}

class SubmitReviewInitial extends SubmitReviewState {}

class SubmitReviewLoading extends SubmitReviewState {}

class SubmitReviewSuccess extends SubmitReviewState {
  final String reviewId;
  const SubmitReviewSuccess({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

class SubmitReviewFailure extends SubmitReviewState {
  final String message;
  const SubmitReviewFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class CheckReviewStatusLoading extends SubmitReviewState {}

class CheckReviewStatusSuccess extends SubmitReviewState {
  final bool isReviewed;
  const CheckReviewStatusSuccess({required this.isReviewed});

  @override
  List<Object?> get props => [isReviewed];
}

class CheckReviewStatusFailure extends SubmitReviewState {
  final String message;
  const CheckReviewStatusFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
