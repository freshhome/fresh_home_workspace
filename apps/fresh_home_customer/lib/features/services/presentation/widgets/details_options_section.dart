import 'package:flutter/material.dart';
import 'package:shared/domain/service/entities/sub_entities/service_details.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';

class DetailsOptionsSection extends StatelessWidget {
  final List<DetailEntity>? details;
  const DetailsOptionsSection({super.key, this.details});

  @override
  Widget build(BuildContext context) {
    if (details == null || details!.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentLocale = Localizations.localeOf(context).languageCode;
    final isArabic = currentLocale == 'ar';
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isArabic ? 'تفاصيل الخدمة' : 'Service Details',
              style: themeText.titleSectionMedium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: themeColor.textPrimary,
              ),
            ),
            TextButton(
               onPressed: () {},
               child: Text(isArabic ? 'عرض المعرض' : 'View Gallery', style: TextStyle(color: themeColor.primary, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...details!.map((detail) {
          final content = isArabic ? detail.ar : detail.en;
          final title = content.title ?? '';
          final points = content.points ?? [];
          final iconUrl = content.icon ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                leading: Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: (iconUrl.startsWith('http'))
                      ? Image.network(
                          iconUrl,
                          errorBuilder: (c, e, s) => Icon(Icons.grid_view_rounded, color: themeColor.primary),
                        )
                      : Icon(Icons.grid_view_rounded, color: themeColor.primary),
                ),
                title: Text(
                  title,
                  style: themeText.titleSectionSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: themeColor.primary, size: 24),
                ),
                children: points.map((point) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle, color: themeColor.secondary, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              point,
                              style: themeText.textBodyPrimary.copyWith(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
              ),
            ),
          );
        }),
      ],
    );
  }
}

