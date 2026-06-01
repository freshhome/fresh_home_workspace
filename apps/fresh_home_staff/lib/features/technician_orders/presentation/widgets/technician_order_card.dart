import 'package:flutter/material.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'status_badge.dart';
import 'package:intl/intl.dart';

class TechnicianOrderCard extends StatelessWidget {
  final Booking order;
  final VoidCallback onTap;
  final bool showSensitiveData;

  const TechnicianOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.showSensitiveData = false,
  });

  DateTime _getDateTime() {
    return order.scheduledAt;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final themeColor = context.themeColor;
    final dateTime = _getDateTime();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [themeColor.cardShadow],
        border: Border.all(
          color: themeColor.unselectedItem.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: themeColor.serviceIconBackground,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Hero(
                      tag: 'order_icon_${order.id}',
                      child: Image.network(
                        order.service.image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.cleaning_services_rounded,
                          color: themeColor.primary,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.service.name[Localizations.localeOf(
                                      context,
                                    ).languageCode] ??
                                    '',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: themeColor.textPrimary,
                                  letterSpacing: -0.5,
                                  fontFamily: 'Cairo',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(status: order.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: themeColor.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#${order.displayId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: themeColor.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildMetaItem(
                    icon: Icons.calendar_today_rounded,
                    text: dateFormat.format(dateTime),
                    themeColor: themeColor,
                  ),
                  const SizedBox(width: 24),
                  _buildMetaItem(
                    icon: Icons.access_time_rounded,
                    text: timeFormat.format(dateTime),
                    themeColor: themeColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetaItem(
                          icon: Icons.location_on_rounded,
                          text:
                              (order.status == OrderStatus.ready ||
                                  order.status == OrderStatus.onTheWay ||
                                  order.status == OrderStatus.arrived ||
                                  order.status == OrderStatus.inProgress)
                              ? "${order.address.street}, ${order.address.buildingNumber}, ${order.address.city}"
                              : order.address.city,
                          isFullWidth: true,
                          themeColor: themeColor,
                        ),
                        if (order.status == OrderStatus.ready ||
                            order.status == OrderStatus.onTheWay ||
                            order.status == OrderStatus.arrived ||
                            order.status == OrderStatus.inProgress) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 14,
                                  color: themeColor.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    order.contact.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: themeColor.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Cairo',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (order.contact.phone.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone_iphone_rounded,
                                    size: 14,
                                    color: themeColor.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    order.contact.phone.first,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: themeColor.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${order.price.total.toStringAsFixed(0)} ج.م',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: themeColor.primary,
                      letterSpacing: -0.5,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String text,
    required ThemeColorExtension themeColor,
    bool isFullWidth = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: themeColor.unselectedItem.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: themeColor.secondaryText),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: themeColor.secondaryText,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
