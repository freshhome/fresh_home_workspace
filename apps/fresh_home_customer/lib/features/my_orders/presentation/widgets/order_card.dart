import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_colors.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:intl/intl.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'status_badge.dart';

class OrderCard extends StatelessWidget {
  final Booking order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    DateTime parseBookingDate() {
      return order.scheduledAt;
    }

    final bookingDateTime = parseBookingDate();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.primaryLight.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            context.pushNamed(
              AppRoutes.orderDetails,
              pathParameters: {'id': order.id},
              extra: order,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ThemeColors.primaryLight.withValues(alpha: 0.12),
                            ThemeColors.primaryLight.withValues(alpha: 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Hero(
                        tag: 'order_icon_${order.id}',
                        child: Image.network(
                          order.service.image,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.cleaning_services_rounded,
                            color: ThemeColors.primaryLight,
                            size: 26,
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
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1C1E),
                                    letterSpacing: -0.5,
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
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${AppLocalizations.of(context)!.order_id_prefix}${order.displayId}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Divider(height: 1, color: Color(0xFFF5F5F7)),
                ),
                Row(
                  children: [
                    _buildMetaItem(
                      icon: Icons.calendar_month_rounded,
                      text: dateFormat.format(bookingDateTime),
                    ),
                    const SizedBox(width: 24),
                    _buildMetaItem(
                      icon: Icons.schedule_rounded,
                      text: timeFormat.format(bookingDateTime),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildMetaItem(
                        icon: Icons.location_on_rounded,
                        text: order.address.city,
                        isFullWidth: true,
                      ),
                    ),
                    Text(
                      '${order.price.total.toStringAsFixed(2)} \$',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: ThemeColors.primaryLight,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String text,
    bool isFullWidth = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
