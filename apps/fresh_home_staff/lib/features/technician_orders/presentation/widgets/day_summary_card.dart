import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isTomorrow = DateUtils.isSameDay(date, DateTime.now().add(const Duration(days: 1)));
    final isGradientCard = isToday || isTomorrow;
    
    // Formatting
    String dateStr;
    if (isToday) {
      dateStr = l10n.technician_orders_tab_today;
    } else if (isTomorrow) {
      dateStr = locale == 'ar' ? 'بكرة' : 'Tomorrow';
    } else {
      dateStr = DateFormat('EEEE', locale).format(date);
    }
    
    final dayNumber = DateFormat('d', locale).format(date);
    final monthName = DateFormat('MMMM', locale).format(date);
    
    final totalStr = NumberFormat.currency(symbol: locale == 'ar' ? 'ج.م' : 'EGP', decimalDigits: 0, locale: locale).format(totalAmount);

    BoxDecoration cardDecoration;
    if (isToday) {
      cardDecoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D327D), Color(0xFF22A5FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D327D).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: isExpanded ? Border.all(color: Colors.white, width: 2) : null,
      );
    } else if (isTomorrow) {
      cardDecoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2ECC71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: isExpanded ? Border.all(color: Colors.white, width: 2) : null,
      );
    } else {
      cardDecoration = BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isExpanded ? themeColor.primary : themeColor.unselectedItem.withValues(alpha: 0.15),
          width: 1.5,
        ),
      );
    }

    final Color contentColor = isGradientCard ? Colors.white : themeColor.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Date Section
                _buildDateBox(
                  isGradientCard ? Colors.white : themeColor.primary,
                  dayNumber,
                  monthName,
                  isInverse: isGradientCard,
                ),
                const SizedBox(width: 16),
                
                // Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: contentColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildBadge(context, "$orderCount ${l10n.nav_my_orders}", Icons.list_alt_rounded, isGradientCard),
                          _buildBadge(context, totalStr, Icons.monetization_on_outlined, isGradientCard),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: isGradientCard ? Colors.white : themeColor.unselectedItem,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateBox(
    Color color,
    String day,
    String month, {
    bool isInverse = false,
  }) {
    return Container(
      width: 65,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isInverse
            ? Colors.white.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isInverse
              ? Colors.white.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          Text(
            month,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, IconData icon, bool isInverse) {
    final themeColor = context.themeColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isInverse ? Colors.white.withValues(alpha: 0.2) : themeColor.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isInverse ? Colors.white.withValues(alpha: 0.4) : themeColor.unselectedItem.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isInverse ? Colors.white : themeColor.unselectedItem),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isInverse ? Colors.white : themeColor.secondaryText,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
