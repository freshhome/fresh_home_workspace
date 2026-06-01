import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';

class SelectableCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final IconData? icon;
  final bool isAddNew;
  final String? addNewText;

  const SelectableCard({
    super.key,
    required this.isSelected,
    required this.onTap,
    this.title = '',
    this.subtitle = '',
    this.icon,
    this.isAddNew = false,
    this.addNewText,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
    const successGreen = Color(0xFF2ECC71);
    final Color activeColor = isAddNew ? themeColor.primary : successGreen;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 170,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? activeColor : themeColor.cardBorder.color,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: isAddNew
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon ?? Icons.add_circle_outline, color: themeColor.primary, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        addNewText ?? '',
                        style: themeText.textBodyPrimary.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: themeText.textBodyPrimary.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: themeText.textCaption.copyWith(fontSize: 11, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          ),
          if (isSelected && !isAddNew)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: successGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}
