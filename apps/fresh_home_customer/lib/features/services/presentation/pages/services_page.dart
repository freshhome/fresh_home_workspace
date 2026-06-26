import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:fresh_home_customer/features/services/presentation/cubit/services_cubit.dart';
import 'package:fresh_home_customer/features/services/presentation/cubit/services_state.dart';
import 'package:fresh_home_customer/features/services/presentation/widgets/service_item.dart';
import 'package:shared/domain/service/entities/sub_service_entity.dart';

class ServicesPage extends StatelessWidget {
  final String serveid;

  const ServicesPage({
    super.key,
    required this.serveid,
  });

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final isArabic = langCode == 'ar';
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;

    return Scaffold(
      backgroundColor: themeColor.background,
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: BlocBuilder<ServicesCubit, ServicesState>(
          builder: (context, state) {
            final services = state is ServicesListSuccess ? state.services : <SubServiceEntity>[];

            return RefreshIndicator(
              onRefresh: () => context.read<ServicesCubit>().getServices(serveid),
              color: themeColor.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(context, themeColor, themeText, isArabic),
                  ),
                  if (state is ServicesListLoading)
                    SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: themeColor.primary)),
                    )
                  else if (state is ServicesListError)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          state.failure.message,
                          style: themeText.textBodyPrimary,
                        ),
                      ),
                    )
                  else if (state is ServicesListSuccess) ...[
                    if (services.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Text(
                            isArabic ? 'لا توجد خدمات حالياً.' : 'No services available.',
                            style: themeText.textBodyPrimary,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final service = services[index];
                              return ServiceItem(
                                service: service,
                                onTap: () {
                                  if (service.isBookable) {
                                    context.pushNamed(
                                      AppRoutes.serviceDetails,
                                      queryParameters: {
                                        'serviceId': serveid,
                                        'subServiceId': service.id,
                                      },
                                    );
                                  } else {
                                    context.pushNamed(
                                      AppRoutes.services,
                                      queryParameters: {
                                        'serveid': service.id,
                                      },
                                    );
                                  }
                                },
                              );
                            },
                            childCount: services.length,
                          ),
                        ),
                      ),
                  ] else
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, 
    ThemeColorExtension themeColor, 
    AppTextThemeExtension themeText,
    bool isArabic,
  ) {
    return ClipPath(
      clipper: HeaderClipper(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: themeColor.primary,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeColor.buttonBackground.withValues(alpha: 0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 70, 24, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          isArabic ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isArabic ? 'خدماتنا' : 'Our Services',
                    style: themeText.titleSectionLarge.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic ? 'اختار الخدمة اللي محتاجها وسيب الباقي علينا' : 'Choose the service you need and leave the rest to us',
                    style: themeText.textCaption.copyWith(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
