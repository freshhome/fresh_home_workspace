import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class DaySummaryCard extends StatelessWidget {
  final DateTime date;
  final int orderCount;
  final double totalAmount;
  final VoidCallback onTap;
  final bool isExpanded;

  const DaySummaryCard({
    super.key,
    required this.date,
    required this.orderCount,
    required this.totalAmount,
    required this.onTap,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final locale = Localizations.localeOf(context).languageCode;

    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isTomorrow = DateUtils.isSameDay(date, DateTime.now().add(const Duration(days: 1)));
    final isGradientCard = isToday || isTomorrow;

    // Formatting date label in pure Arabic / selected locale
    String dateLabel;
    final dayMonthStr = DateFormat('d MMMM', locale).format(date);
    if (isToday) {
      dateLabel = locale == 'ar' ? 'اليوم، $dayMonthStr' : 'Today, $dayMonthStr';
    } else if (isTomorrow) {
      dateLabel = locale == 'ar' ? 'غداً، $dayMonthStr' : 'Tomorrow, $dayMonthStr';
    } else {
      dateLabel = DateFormat('EEEE، d MMMM', locale).format(date);
    }

    final currencySymbol = locale == 'ar' ? 'ج.م' : 'EGP';
    final totalFormatted = NumberFormat('#,##0', locale).format(totalAmount);
    final countStr = locale == 'ar'
        ? '$orderCount ${orderCount > 2 && orderCount < 11 ? 'طلبات' : 'طلب'}'
        : '$orderCount ${orderCount == 1 ? 'order' : 'orders'}';

    BoxDecoration cardDecoration;
    if (isToday) {
      cardDecoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D327D), Color(0xFF22A5FC)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D327D).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (isTomorrow) {
      cardDecoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF22C55E)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15803D).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else {
      cardDecoration = BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isExpanded ? themeColor.primary : themeColor.unselectedItem.withValues(alpha: 0.15),
          width: 1.2,
        ),
      );
    }

    final Color contentColor = isGradientCard ? Colors.white : themeColor.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Right side (in RTL): Calendar Icon
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isGradientCard
                        ? Colors.white.withValues(alpha: 0.2)
                        : themeColor.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: isGradientCard ? Colors.white : themeColor.primary,
                  ),
                ),
                const SizedBox(width: 8),

                // Date Text - takes remaining space and fits completely without cut-off
                Expanded(
                  child: Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: contentColor,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ),
                const SizedBox(width: 8),

                // Left side (in RTL): Compact summary pill & chevron
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isGradientCard
                        ? Colors.white.withValues(alpha: 0.2)
                        : themeColor.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isGradientCard
                          ? Colors.white.withValues(alpha: 0.35)
                          : themeColor.unselectedItem.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '$countStr • $totalFormatted $currencySymbol',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: contentColor,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Expand/Collapse Chevron
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: contentColor,
                    size: 20,
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
