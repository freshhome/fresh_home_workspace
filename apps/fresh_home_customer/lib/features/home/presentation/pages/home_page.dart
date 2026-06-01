import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/domain/service/entities/main_service_entity.dart';
import 'package:shared/domain/service/entities/service_entity.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/widget/my_custom_button.dart';
import 'package:shared/presentation/widget/custom_slider.dart';

import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

/// الصفحة الرئيسية للتطبيق
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().getHomeData();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).extension<AppTextThemeExtension>()!;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.app_title)),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HomeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.failure.message, style: textTheme.textError),
                  const SizedBox(height: 16),
                  MyCustomButton(
                    text: AppLocalizations.of(context)!.general_retry,
                    onPressed: () => context.read<HomeCubit>().getHomeData(),
                  ),
                ],
              ),
            );
          }

          if (state is HomeDataLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().getHomeData(),
              color: Theme.of(
                context,
              ).extension<ThemeColorExtension>()!.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: CustomSlider(
                        images: state.homeData.sliders
                            .map((e) => e.image)
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(
                      title: AppLocalizations.of(context)!.home_our_services,
                    ),
                    _MainServices2(services: state.homeData.services),
                    _SectionTitle(
                      title: AppLocalizations.of(
                        context,
                      )!.home_popular_services,
                    ),
                    _PopularServices2(services: state.homeData.popularServices),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

//!================ قسم خدماتنا

class _MainServices2 extends StatelessWidget {
  final List<MainServiceEntity> services;
  const _MainServices2({required this.services});

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    return SizedBox(
      height: 125, // Increased height for better proportions
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 4,
        ), // Aligned with page margins
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none, // Allows shadows to breathe
        itemCount: services.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final serve = services[index];
          return _ServiceCard2(
            title: serve.title[currentLocale] ?? '',
            imageUrl: serve.image ?? '',
            onTap: () {
              context.pushNamed(
                AppRoutes.services,
                queryParameters: {
                  'serveid': serve.id,
                  'updatedAt': "${serve.updatedAt}",
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ! ================= بطاقة خدمة مطورة
class _ServiceCard2 extends StatefulWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const _ServiceCard2({
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  State<_ServiceCard2> createState() => _ServiceCard2State();
}

class _ServiceCard2State extends State<_ServiceCard2>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) => setState(() => _scale = 0.94);
  void _onTapUp(TapUpDetails details) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          width: 95,
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [themeColor.cardShadow],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container with creative touch
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: themeColor.serviceIconBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: themeColor.primary.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Hero(
                  tag: 'service_icon_${widget.title}',
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.cleaning_services_rounded,
                      size: 28,
                      color: themeColor.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                    color: themeColor.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// !=========================== خدمات شائعة

class _PopularServices2 extends StatelessWidget {
  final List<ServiceEntity> services;
  const _PopularServices2({required this.services});

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isArabic = currentLocale == 'ar';
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final textTheme = Theme.of(context).extension<AppTextThemeExtension>()!;

    if (services.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            isArabic ? 'لا توجد خدمات شائعة حالياً.' : 'No popular services available.',
            style: textTheme.textCaption,
          ),
        ),
      );
    }

    return SizedBox(
      height: 185,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: services.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final service = services[index];
          final hasPrice = service.price != null;
          final priceStr = hasPrice
              ? '${service.price!.value.toInt()} ريال'
              : (isArabic ? 'حسب الطلب' : 'On Demand');

          return GestureDetector(
            onTap: () {
              context.pushNamed(
                AppRoutes.serviceDetails,
                queryParameters: {
                  'serviceId': service.parentId ?? '',
                  'subServiceId': service.id,
                },
              );
            },
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: themeColor.cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [themeColor.cardShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image / Graphic block
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: themeColor.serviceIconBackground,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      border: Border.all(
                        color: themeColor.primary.withValues(alpha: 0.03),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: service.image != null && service.image!.isNotEmpty
                        ? Image.network(
                            service.image!,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => Icon(
                              Icons.cleaning_services_rounded,
                              size: 32,
                              color: themeColor.primary.withValues(alpha: 0.5),
                            ),
                          )
                        : Icon(
                            Icons.cleaning_services_rounded,
                            size: 32,
                            color: themeColor.primary.withValues(alpha: 0.5),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title[currentLocale] ?? '',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: themeColor.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasPrice
                              ? '${isArabic ? 'تبدأ من' : 'Starts from'} $priceStr'
                              : priceStr,
                          style: textTheme.textCaption.copyWith(
                            fontSize: 11,
                            color: themeColor.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// !================ عنوان في العنوان لكل قسم
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).extension<AppTextThemeExtension>()!;
    final themeColor = context.themeColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSectionLarge.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: themeColor.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const Spacer(),
          // زر عرض الكل المطور
          GestureDetector(
            onTap: () {},
            child: Text(
              AppLocalizations.of(context)!.home_view_all,
              style: TextStyle(
                color: themeColor.primary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
