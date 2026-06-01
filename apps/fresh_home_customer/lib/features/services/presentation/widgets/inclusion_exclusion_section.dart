import 'package:flutter/material.dart';

import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/domain/service/entities/sub_entities/service_details.dart';

class InclusionExclusionSection extends StatelessWidget {
  final NotIncludedEntity? notIncluded;
  const InclusionExclusionSection({super.key, this.notIncluded});

  @override
  Widget build(BuildContext context) {
    if (notIncluded == null) return const SizedBox.shrink();

    final currentLocale = Localizations.localeOf(context).languageCode;
    final isArabic = currentLocale == 'ar';
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
    
    final content = isArabic ? notIncluded?.ar : notIncluded?.en;
    if (content == null || content.points == null || content.points!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Very light slate
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
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
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: (content.icon != null && content.icon!.startsWith('http'))
                ? Image.network(
                    content.icon!,
                    errorBuilder: (c, e, s) => const Icon(Icons.info_outline_rounded, color: Colors.redAccent),
                  )
                : const Icon(Icons.info_outline_rounded, color: Colors.redAccent),
          ),
          title: Text(
            content.title ?? (isArabic ? 'ما لا تشمله الخدمة' : 'Not Included'),
            style: themeText.titleSectionSmall.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Colors.redAccent.shade700,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.redAccent, size: 24),
          ),
          children: content.points!.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        point,
                        style: themeText.textBodyPrimary.copyWith(
                          fontSize: 14,
                          color: Colors.black54,
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
  }
}

