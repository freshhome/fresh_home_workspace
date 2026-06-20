import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import 'package:shared_features/shared_features.dart';
import '../cubit/technician_reviews_cubit.dart';
import '../cubit/technician_reviews_state.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final profileState = context.read<ProfileCubit>().state;
        if (profileState is ProfileLoaded) {
          final reviewsCubit = context.read<TechnicianReviewsCubit>();
          if (reviewsCubit.state is! TechnicianReviewsLoaded &&
              reviewsCubit.state is! TechnicianReviewsLoading) {
            reviewsCubit.fetchReviews(
              technicianId: profileState.profile.uid,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final profileState = context.read<ProfileCubit>().state;
      if (profileState is ProfileLoaded) {
        context.read<TechnicianReviewsCubit>().fetchNextPage(
              technicianId: profileState.profile.uid,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColor = context.themeColor;

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        backgroundColor: themeColor.primary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.reviews_title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, profileState) {
          if (profileState is ProfileLoaded) {
            final reviewsCubit = context.read<TechnicianReviewsCubit>();
            if (reviewsCubit.state is! TechnicianReviewsLoaded &&
                reviewsCubit.state is! TechnicianReviewsLoading) {
              reviewsCubit.fetchReviews(
                technicianId: profileState.profile.uid,
              );
            }
          }
        },
        builder: (context, profileState) {
          if (profileState is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profileState is ProfileError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  profileState.failure.message,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          double overallRating = 5.0;
          int completedJobs = 0;

          if (profileState is ProfileLoaded) {
            final profile = profileState.profile;
            if (profile is TechnicianProfile) {
              overallRating = profile.rating;
              completedJobs = profile.completedJobs;
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (profileState is ProfileLoaded) {
                await context.read<TechnicianReviewsCubit>().fetchReviews(
                      technicianId: profileState.profile.uid,
                    );
              }
            },
            color: themeColor.primary,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: themeColor.cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [themeColor.cardShadow],
                      border: Border.all(
                        color: themeColor.primary.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          overallRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: themeColor.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StarRatingWidget(
                          initialRating: overallRating,
                          isReadOnly: true,
                          iconSize: 28,
                          filledColor: Colors.amber,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.reviews_overall_rating,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: themeColor.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.reviews_summary_desc(completedJobs.toString()),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: themeColor.secondaryText.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Reviews List Title
                  Text(
                    l10n.reviews_latest_feedback,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reviews List Block
                  BlocBuilder<TechnicianReviewsCubit, TechnicianReviewsState>(
                    builder: (context, reviewState) {
                      if (reviewState is TechnicianReviewsLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (reviewState is TechnicianReviewsError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              l10n.reviews_load_error(reviewState.message),
                              style: const TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        );
                      } else if (reviewState is TechnicianReviewsLoaded) {
                        final reviews = reviewState.reviews;

                        if (reviews.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(
                                  Icons.rate_review_outlined,
                                  size: 48,
                                  color: themeColor.secondaryText.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.reviews_no_reviews,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: themeColor.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: reviews.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final review = reviews[index];
                                final dateText =
                                    review.createdAt.toLocal().toString().substring(0, 10);

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: themeColor.cardBackground,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: themeColor.cardBorder.color,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.01),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: themeColor.primary
                                                    .withValues(alpha: 0.1),
                                                child: Icon(
                                                  Icons.person_rounded,
                                                  size: 16,
                                                  color: themeColor.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                l10n.reviews_previous_customer,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: themeColor.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            dateText,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: themeColor.secondaryText,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      StarRatingWidget(
                                        initialRating: review.ratingValue.toDouble(),
                                        isReadOnly: true,
                                        iconSize: 16,
                                        filledColor: Colors.amber,
                                      ),
                                      if (review.feedbackText != null &&
                                          review.feedbackText!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          review.feedbackText!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: themeColor.secondaryText,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                            if (!reviewState.hasReachedMax)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
