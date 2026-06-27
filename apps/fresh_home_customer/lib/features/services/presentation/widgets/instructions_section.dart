import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';

class InstructionsSection extends StatelessWidget {
  final Map<String, String>? instructions;

  const InstructionsSection({
    super.key,
    required this.instructions,
  });

  @override
  Widget build(BuildContext context) {
    if (instructions == null) return const SizedBox.shrink();

    final langCode = Localizations.localeOf(context).languageCode;
    final text = instructions![langCode]?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_turned_in_rounded,
                  size: 18,
                  color: Colors.amber.shade800,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                langCode == 'ar' ? 'تعليمات وإرشادات الخدمة' : 'Service Instructions',
                style: themeText.titleSectionSmall.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: themeText.textBodyPrimary.copyWith(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
