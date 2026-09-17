import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'status_badge.dart';

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

  String _formatTime(DateTime dt, String locale) {
    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    final period = locale == 'ar'
        ? (dt.hour < 12 ? 'صباحاً' : 'مساءً')
        : (dt.hour < 12 ? 'AM' : 'PM');
    return '$hour12:$minuteStr $period';
  }

  String _formatDistrictAndCity(Address address, String locale) {
    final district = address.getDistrictName(locale).trim();
    final city = address.getCityName(locale).trim();

    if (district.isNotEmpty && city.isNotEmpty) {
      if (district.toLowerCase() == city.toLowerCase()) {
        return district;
      }
      return '$district، $city';
    } else if (district.isNotEmpty) {
      return district;
    } else if (city.isNotEmpty) {
      return city;
    }

    final details = address.addressDetails.trim();
    if (details.isNotEmpty) return details;

    return address.getGovernorateName(locale);
  }

  String _formatPaymentText(Booking order, String locale) {
    final isPaid = order.paymentStatus?.toLowerCase() == 'paid';
    final method = order.paymentMethod?.toLowerCase();
    final isOnline = isPaid || method == 'instapay' || method == 'card' || method == 'vodafone_cash';

    final totalFormatted = NumberFormat('#,##0', locale).format(order.price.total);
    final currency = locale == 'ar' ? 'ج.م' : 'EGP';

    if (isOnline) {
      return locale == 'ar' ? '$totalFormatted $currency (مدفوع إلكترونياً)' : '$totalFormatted $currency (Paid Online)';
    } else {
      return locale == 'ar' ? '$totalFormatted $currency (كاش للتحصيل)' : '$totalFormatted $currency (Cash on Delivery)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final themeColor = context.themeColor;
    final dateTime = order.scheduledAt;

    final bool canShowCustomerContact = showSensitiveData &&
        (order.status == OrderStatus.ready ||
            order.status == OrderStatus.onTheWay ||
            order.status == OrderStatus.arrived ||
            order.status == OrderStatus.inProgress);

    final bool isToday = DateUtils.isSameDay(order.scheduledAt, DateTime.now());
    final confirmOpenTime = order.scheduledAt.subtract(const Duration(hours: 2));
    final bool canConfirmNow = isToday &&
        (DateTime.now().isAfter(confirmOpenTime) || DateTime.now().isAtSameMomentAs(confirmOpenTime));

    final serviceName = order.service.name[locale] ?? order.service.name['ar'] ?? '';
    final timeStr = _formatTime(dateTime, locale);
    final locationStr = _formatDistrictAndCity(order.address, locale);
    final paymentStr = _formatPaymentText(order, locale);

    final isPaid = order.paymentStatus?.toLowerCase() == 'paid';
    final isCash = !isPaid && (order.paymentMethod == null || order.paymentMethod?.toLowerCase() == 'cash');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: themeColor.unselectedItem.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. الهيدر (الصف الأول): رقم الطلب يميناً والحالة يساراً
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          size: 15,
                          color: themeColor.secondaryText.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.displayId,
                          style: TextStyle(
                            fontSize: 13,
                            color: themeColor.secondaryText,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. العنوان ونوع الخدمة (الصف الثاني): أيقونة 40x40 مع اسم الخدمة بدون قص
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: themeColor.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeColor.primary.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(7),
                      child: Image.network(
                        order.service.image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.cleaning_services_rounded,
                          color: themeColor.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        serviceName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: themeColor.textPrimary,
                          fontFamily: 'Cairo',
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: themeColor.unselectedItem.withValues(alpha: 0.08),
                  ),
                ),

                // 3. البيانات اللوجستية (تحت العنوان مباشرة مع أيقونات خفيفة متناسقة)
                // الميعاد
                _buildLogisticRow(
                  icon: Icons.access_time_rounded,
                  iconColor: const Color(0xFF0284C7),
                  text: timeStr,
                  themeColor: themeColor,
                ),
                const SizedBox(height: 8),

                // العنوان: المدينة والحي فقط
                _buildLogisticRow(
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFFE11D48),
                  text: locationStr,
                  themeColor: themeColor,
                ),
                const SizedBox(height: 8),

                // المبلغ والتحصيل
                _buildLogisticRow(
                  icon: Icons.monetization_on_rounded,
                  iconColor: isCash ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                  text: paymentStr,
                  themeColor: themeColor,
                  isBoldText: true,
                ),

                // بيانات العميل إذا كانت متاحة (الاسم ورقم الهاتف)
                if (canShowCustomerContact) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: themeColor.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: themeColor.unselectedItem.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: themeColor.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.contact.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: themeColor.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (order.contact.phone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.phone_rounded,
                            size: 13,
                            color: themeColor.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.contact.phone.first,
                            style: TextStyle(
                              fontSize: 12,
                              color: themeColor.secondaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // تنبيهات الحضور للطلبات المقبولة اليوم
                if (order.status == OrderStatus.accepted) ...[
                  if (canConfirmNow)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "يتاح تأكيد حضور اليوم الآن ✅",
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_clock_rounded,
                            size: 14,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "يتاح التأكيد الساعة ${_formatTime(confirmOpenTime, locale)} (قبل الموعد بساعتين)",
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                const SizedBox(height: 14),

                // 4. زر الإجراء السريع (Bottom Action CTA)
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          locale == 'ar' ? 'عرض تفاصيل الطلب' : 'View Details',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogisticRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    required ThemeColorExtension themeColor,
    bool isBoldText = false,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isBoldText ? themeColor.textPrimary : themeColor.secondaryText,
              fontWeight: isBoldText ? FontWeight.w700 : FontWeight.w600,
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
