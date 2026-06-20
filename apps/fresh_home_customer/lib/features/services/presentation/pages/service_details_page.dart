import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fresh_home_customer/features/services/presentation/cubit/services_cubit.dart';
import 'package:fresh_home_customer/features/services/presentation/cubit/services_state.dart';
import 'package:fresh_home_customer/features/services/presentation/cubit/service_reviews_cubit.dart';
import 'package:fresh_home_customer/features/services/presentation/cubit/service_reviews_state.dart';
import 'package:fresh_home_customer/features/services/presentation/widgets/details_options_section.dart';
import 'package:fresh_home_customer/features/services/presentation/widgets/inclusion_exclusion_section.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/shared.dart';
import 'package:shared_features/shared_features.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';


class ServiceDetailsPage extends StatefulWidget {
  final String serviceId;
  final String subServiceId;

  const ServiceDetailsPage({
    super.key,
    required this.serviceId,
    required this.subServiceId,
  });

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  void _checkIfFavorite() {
    try {
      final box = Hive.box(HiveBoxNames.settingsBox);
      final List<dynamic> favorites = box.get('favorites', defaultValue: <dynamic>[]);
      setState(() {
        isFavorite = favorites.contains(widget.subServiceId);
      });
    } catch (e) {
      debugPrint('Error checking favorite: $e');
    }
  }

  void _toggleFavorite() {
    try {
      final box = Hive.box(HiveBoxNames.settingsBox);
      final List<dynamic> favorites = List.from(box.get('favorites', defaultValue: <dynamic>[]));
      setState(() {
        if (favorites.contains(widget.subServiceId)) {
          favorites.remove(widget.subServiceId);
          isFavorite = false;
        } else {
          favorites.add(widget.subServiceId);
          isFavorite = true;
        }
      });
      box.put('favorites', favorites);
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isArabic = currentLocale == 'ar';
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;

    return BlocBuilder<ServicesCubit, ServicesState>(
      builder: (context, state) {
        if (state is ServiceDetailsLoading) {
          return Scaffold(
            backgroundColor: themeColor.background,
            body: Center(
              child: CircularProgressIndicator(color: themeColor.primary),
            ),
          );
        } else if (state is ServiceDetailsError) {
          return Scaffold(
            backgroundColor: themeColor.background,
            body: Center(
              child: Text(
                state.failure.message,
                style: themeText.textBodyPrimary,
              ),
            ),
          );
        } else if (state is ServiceDetailsSuccess) {
          final service = state.service;
          return Scaffold(
            backgroundColor: themeColor.background,
            appBar: AppBar(
              backgroundColor: themeColor.primary,
              elevation: 0,
              centerTitle: true,
              title: Text(
                service.title[isArabic ? 'ar' : 'en'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  isArabic ? Icons.arrow_forward : Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: isArabic ? 'المفضلة' : 'Favorite',
                ),
              ],
            ),
            floatingActionButton: _buildBookingButton(
              context,
              service,
              isArabic,
              themeColor,
              themeText,
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            body: RefreshIndicator(
              onRefresh: () => context.read<ServicesCubit>().getServiceDetails(
                    subserviceId: widget.subServiceId,
                    mainServiceId: widget.serviceId,
                    forceRemote: true,
                  ),
              color: themeColor.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  children: [
                    // Service Header (Icon, Title, Description)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (service.image != null && service.image!.isNotEmpty) ...[
                            Container(
                              width: 80,
                              height: 80,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: themeColor.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: themeColor.primary.withValues(alpha: 0.1)),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: service.image!,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const ShimmerLoading(
                                  width: 56,
                                  height: 56,
                                  borderRadius: 12,
                                ),
                                errorWidget: (c, e, s) => Icon(
                                  Icons.cleaning_services_rounded,
                                  color: themeColor.primary,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.title[isArabic ? 'ar' : 'en'] ?? '',
                                  style: themeText.titleSectionMedium.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: themeColor.textPrimary,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                if (service.description[isArabic ? 'ar' : 'en'] != null &&
                                    service.description[isArabic ? 'ar' : 'en']!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    service.description[isArabic ? 'ar' : 'en']!,
                                    style: themeText.textCaption.copyWith(
                                      fontSize: 13,
                                      color: themeColor.secondaryText,
                                      height: 1.4,
                                      fontFamily: 'Cairo',
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Base Price Indicator Card
                          _buildStartingPriceCard(service, isArabic, themeColor, themeText),
                          const SizedBox(height: 24),

                          // Service detail tiles (what's included)
                          DetailsOptionsSection(details: service.details),
                          const SizedBox(height: 24),

                          // Exclusions
                          InclusionExclusionSection(notIncluded: service.notIncluded),
                          const SizedBox(height: 24),

                          // Customer Reviews Section
                          const Divider(height: 32, thickness: 1.2),
                          Text(
                            isArabic ? 'آراء العملاء' : 'Customer Reviews',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: themeColor.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          BlocBuilder<ServiceReviewsCubit, ServiceReviewsState>(
                            builder: (context, reviewState) {
                              if (reviewState is ServiceReviewsLoading) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (reviewState is ServiceReviewsError) {
                                return Center(
                                  child: Text(
                                    isArabic ? 'فشل تحميل الآراء' : 'Failed to load reviews',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                );
                              } else if (reviewState is ServiceReviewsLoaded) {
                                final reviews = reviewState.reviews;
                                if (reviews.isEmpty) {
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    alignment: Alignment.center,
                                    child: Text(
                                      isArabic ? 'لا توجد مراجعات لهذه الخدمة بعد.' : 'No reviews for this service yet.',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13,
                                        color: themeColor.secondaryText,
                                      ),
                                    ),
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: List.generate(reviews.length, (index) {
                                        final review = reviews[index];
                                        final dateText = review.createdAt.toLocal().toString().substring(0, 10);
                                        final customerName = review.customerFullName.isNotEmpty
                                            ? review.customerFullName
                                            : (isArabic ? 'عميل فريش هوم' : 'Fresh Home Client');

                                        return Padding(
                                          padding: EdgeInsets.only(bottom: index == reviews.length - 1 ? 0 : 12),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.grey.shade100),
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
                                                          backgroundColor: themeColor.primary.withValues(alpha: 0.1),
                                                          backgroundImage: review.customerAvatarUrl != null && review.customerAvatarUrl!.isNotEmpty
                                                              ? CachedNetworkImageProvider(review.customerAvatarUrl!)
                                                              : null,
                                                          child: review.customerAvatarUrl != null && review.customerAvatarUrl!.isNotEmpty
                                                              ? null
                                                              : Icon(
                                                                  Icons.person_rounded,
                                                                  size: 16,
                                                                  color: themeColor.primary,
                                                                ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          customerName,
                                                          style: TextStyle(
                                                            fontFamily: 'Cairo',
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
                                                        fontFamily: 'Cairo',
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
                                                ),
                                                if (review.feedbackText != null && review.feedbackText!.isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    review.feedbackText!,
                                                    style: TextStyle(
                                                      fontFamily: 'Cairo',
                                                      fontSize: 13,
                                                      color: themeColor.secondaryText,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                    if (!reviewState.hasReachedMax) ...[
                                      const SizedBox(height: 16),
                                      if (reviewState.isLoadingMore)
                                        const Center(child: CircularProgressIndicator())
                                      else
                                        Center(
                                          child: TextButton(
                                            onPressed: () {
                                              context.read<ServiceReviewsCubit>().fetchNextPage(
                                                serviceId: widget.subServiceId,
                                              );
                                            },
                                            child: Text(
                                              isArabic ? 'عرض المزيد من الآراء' : 'Show more reviews',
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: themeColor.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 90),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStartingPriceCard(
    SubServiceEntity service,
    bool isArabic,
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    String label = '';
    String priceText = '${service.price.value.toStringAsFixed(0)} ج.م';

    switch (service.price.type) {
      case PricingMethod.fixed:
        label = isArabic ? 'السعر الأساسي الثابت' : 'Base Fixed Price';
        break;
      case PricingMethod.perSquareMeter:
        label = isArabic ? 'سعر المتر المربع' : 'Price per Sq. Meter';
        priceText = '${service.price.value.toStringAsFixed(0)} ج.م / م²';
        break;
      case PricingMethod.perLinearMeter:
        label = isArabic ? 'سعر المتر الطولي' : 'Price per Linear Meter';
        priceText = '${service.price.value.toStringAsFixed(0)} ج.م / م';
        break;
      case PricingMethod.inspection:
        label = isArabic ? 'رسوم المعاينة الميدانية' : 'On-Site Inspection Fee';
        break;
      default:
        label = isArabic ? 'السعر التقديري' : 'Starting Price';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: themeColor.secondaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isArabic ? 'السعر الأساسي المعتمد للخدمة' : 'Approved Base Price',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: themeColor.secondaryText.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Text(
            priceText,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: themeColor.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(
    BuildContext context,
    SubServiceEntity service,
    bool isArabic,
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: SafeArea(
        child: MyCustomButton(
          text: isArabic ? 'احجز الآن' : 'Book Now',
          leadingIcon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
          onPressed: () {
            final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

            if (userId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isArabic ? 'يرجى تسجيل الدخول أولاً' : 'Please login first',
                  ),
                ),
              );
              context.pushNamed(AppRoutes.login);
              return;
            }

            final bookedService = BookedService(
              id: widget.serviceId,
              subServiceId: widget.subServiceId,
              name: service.title,
              image: service.image ?? '',
            );

            context.pushNamed(
              AppRoutes.bookingFlow,
              extra: BookingFlowConfig(
                mode: BookingFlowMode.customer,
                actorId: userId,
                preSelectedService: bookedService,
                initialServicePrice: service.price,
              ),
            );
          },
          height: 54,
          borderRadius: 27, // Fully pill-shaped borders for a premium floating look
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}
