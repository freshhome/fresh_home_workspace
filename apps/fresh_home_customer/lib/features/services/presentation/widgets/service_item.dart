import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared/domain/service/entities/base_service_entity.dart';
import 'package:shared/domain/service/enums/service_status.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';

class ServiceItem extends StatelessWidget {
  final BaseServiceEntity service;
  final VoidCallback onTap;

  const ServiceItem({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          themeColor.cardShadow,
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon/Image Container
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.serviceIconBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
                  ),
                  child: service.image != null && service.image!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: service.image!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const ShimmerLoading(
                            width: 50,
                            height: 50,
                            borderRadius: 12,
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.cleaning_services_rounded,
                            size: 32,
                            color: themeColor.primary,
                          ),
                        )
                      : Icon(
                          Icons.cleaning_services_rounded,
                          size: 32,
                          color: themeColor.primary,
                        ),
                ),
                const SizedBox(width: 20),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              service.title[langCode] ?? '',
                              style: themeText.titleSectionSmall.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: themeColor.textPrimary,
                              ),
                            ),
                          ),
                          if (service.status == ServiceStatus.paused) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Text(
                                langCode == 'ar' ? 'متوقف مؤقتاً' : 'Paused',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7A4F01),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        service.description[langCode] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: themeText.textCaption.copyWith(
                           color: themeColor.secondaryText, // using unselectedItem as secondary text proxy if needed
                           fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: themeColor.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
