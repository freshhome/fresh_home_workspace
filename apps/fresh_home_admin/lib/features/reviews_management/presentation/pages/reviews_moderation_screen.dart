import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import '../cubit/reviews_moderation_cubit.dart';
import '../cubit/reviews_moderation_state.dart';

class ReviewsModerationScreen extends StatefulWidget {
  const ReviewsModerationScreen({super.key});

  @override
  State<ReviewsModerationScreen> createState() => _ReviewsModerationScreenState();
}

class _ReviewsModerationScreenState extends State<ReviewsModerationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _quarantinedScrollController;
  late ScrollController _publishedScrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _quarantinedScrollController = ScrollController()..addListener(_onQuarantinedScroll);
    _publishedScrollController = ScrollController()..addListener(_onPublishedScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quarantinedScrollController.dispose();
    _publishedScrollController.dispose();
    super.dispose();
  }

  void _onQuarantinedScroll() {
    if (_quarantinedScrollController.position.pixels >= _quarantinedScrollController.position.maxScrollExtent - 200) {
      context.read<ReviewsModerationCubit>().fetchNextPage(isQuarantined: true);
    }
  }

  void _onPublishedScroll() {
    if (_publishedScrollController.position.pixels >= _publishedScrollController.position.maxScrollExtent - 200) {
      context.read<ReviewsModerationCubit>().fetchNextPage(isQuarantined: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: themeColor.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'إدارة ومراجعة التقييمات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3.0,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
            labelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
            ),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rate_review_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('تحتاج مراجعة'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.playlist_add_check_circle_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('المنشورة'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: BlocBuilder<ReviewsModerationCubit, ReviewsModerationState>(
          builder: (context, state) {
            if (state is ReviewsModerationLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              );
            }

            if (state is ReviewsModerationError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'فشل تحميل البيانات',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.read<ReviewsModerationCubit>().loadReviews(),
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                        label: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is ReviewsModerationLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildReviewsList(
                    reviews: state.quarantinedReviews,
                    approvingIds: state.approvingReviewIds,
                    isQuarantinedTab: true,
                    emptyMessage: 'لا توجد تقييمات تحتاج إلى مراجعة حالياً.',
                    scrollController: _quarantinedScrollController,
                    isLoadingMore: state.isLoadingMoreQuarantined,
                    hasReachedMax: state.hasReachedMaxQuarantined,
                  ),
                  _buildReviewsList(
                    reviews: state.publishedReviews,
                    approvingIds: state.approvingReviewIds,
                    isQuarantinedTab: false,
                    emptyMessage: 'لا توجد تقييمات منشورة حتى الآن.',
                    scrollController: _publishedScrollController,
                    isLoadingMore: state.isLoadingMorePublished,
                    hasReachedMax: state.hasReachedMaxPublished,
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildReviewsList({
    required List<ReviewEntity> reviews,
    required List<String> approvingIds,
    required bool isQuarantinedTab,
    required String emptyMessage,
    required ScrollController scrollController,
    required bool isLoadingMore,
    required bool hasReachedMax,
  }) {
    if (reviews.isEmpty && !isLoadingMore) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isQuarantinedTab
                    ? Icons.verified_user_outlined
                    : Icons.rate_review_outlined,
                size: 72,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: hasReachedMax ? reviews.length : reviews.length + 1,
      itemBuilder: (context, index) {
        if (index >= reviews.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final review = reviews[index];
        final isApproving = approvingIds.contains(review.id);
        return _ReviewCard(
          key: ValueKey(review.id),
          review: review,
          isQuarantined: isQuarantinedTab,
          isApproving: isApproving,
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewEntity review;
  final bool isQuarantined;
  final bool isApproving;

  const _ReviewCard({
    super.key,
    required this.review,
    required this.isQuarantined,
    required this.isApproving,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = '${review.createdAt.year}-${review.createdAt.month.toString().padLeft(2, '0')}-${review.createdAt.day.toString().padLeft(2, '0')}';
    final serviceName = review.serviceTitle?['ar'] ?? review.serviceTitle?['en'] ?? 'خدمة غير معروفة';
    final techName = review.technicianFullName.isNotEmpty ? review.technicianFullName : 'فني غير معروف';
    final custName = review.customerFullName.isNotEmpty ? review.customerFullName : 'عميل غير معروف';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEFF1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Service Type Tag & Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  serviceName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ),
              StarRatingWidget(
                initialRating: review.ratingValue.toDouble(),
                isReadOnly: true,
                iconSize: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Feedback Text
          if (review.feedbackText != null && review.feedbackText!.trim().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, color: Color(0xFF94A3B8), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      review.feedbackText!,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const Text(
              'لا توجد تعليقات نصية مرفقة.',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Divider
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Metadata Info: Technician Name & Customer Name
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.engineering_rounded, color: Color(0xFF64748B), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        techName,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        custName,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date & Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تاريخ التقييم: $dateStr',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
              if (isQuarantined)
                ElevatedButton.icon(
                  onPressed: isApproving
                      ? null
                      : () => context.read<ReviewsModerationCubit>().approveReview(review.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: isApproving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 16),
                  label: const Text(
                    'موافقة ونشر',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
