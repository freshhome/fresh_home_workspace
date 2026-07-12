import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/dynamic_field.dart';
import 'package:shared_features/shared_features.dart';
import '../cubit/admin_booking_details_cubit.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fresh_home_admin/features/user_management/domain/repositories/user_management_repository.dart';
import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:shared/data/booking/datasources/availability_remote_datasource.dart';
import 'package:get_it/get_it.dart';

class AdminBookingDetailsScreen extends StatefulWidget {
  final Booking? booking;
  final String? bookingId;

  const AdminBookingDetailsScreen({super.key, this.booking, this.bookingId});

  @override
  State<AdminBookingDetailsScreen> createState() =>
      _AdminBookingDetailsScreenState();
}

class _AdminBookingDetailsScreenState extends State<AdminBookingDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBookingDetailsCubit>().loadData(
      booking: widget.booking,
      bookingId: widget.bookingId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBookingDetailsCubit, AdminBookingDetailsState>(
      buildWhen: (previous, current) {
        if (previous is AdminBookingDetailsLoaded ||
            previous is AdminBookingDetailsSuccess ||
            previous is AdminBookingDetailsError) {
          return current is AdminBookingDetailsLoaded;
        }
        return true;
      },
      builder: (context, state) {
        if (state is AdminBookingDetailsLoading ||
            state is AdminBookingDetailsInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        Booking? displayBooking;
        UserProfile? displayCustomer;
        UserProfile? displayTechnician;

        if (state is AdminBookingDetailsLoaded) {
          displayBooking = state.booking;
          displayCustomer = state.customer;
          displayTechnician = state.technician;
        } else if (state is AdminBookingDetailsSuccess) {
          displayBooking = state.booking;
          displayCustomer = state.customer;
          displayTechnician = state.technician;
        } else if (state is AdminBookingDetailsError) {
          displayBooking = state.booking;
          displayCustomer = state.customer;
          displayTechnician = state.technician;
        }

        if (displayBooking != null) {
          return _AdminBookingDetailsContent(
            booking: displayBooking,
            customer: displayCustomer,
            technician: displayTechnician,
          );
        }

        if (state is AdminBookingDetailsError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(state.message)),
          );
        }
        return const Scaffold(body: Center(child: Text('Unknown State')));
      },
    );
  }
}

class _AdminBookingDetailsContent extends StatelessWidget {
  final Booking booking;
  final UserProfile? customer;
  final UserProfile? technician;

  const _AdminBookingDetailsContent({
    required this.booking,
    this.customer,
    this.technician,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'تفاصيل الطلب #${booking.displayId}',
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<AdminBookingDetailsCubit, AdminBookingDetailsState>(
        listener: (context, state) {
          if (state is AdminBookingDetailsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
            if (state.message.contains('الواتساب')) {
              _showCopyMessageDialog(context, isAutomatic: true);
            } else {
              Navigator.pop(context);
            }
          }
          if (state is AdminBookingDetailsError) {
            _showErrorDialog(context, state.message);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!booking.isWhatsappConfirmed) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB), // Amber 50
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFDE68A),
                      ), // Amber 200
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B), // Amber 500
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'حجز معلق - بانتظار التأكيد عبر واتساب ⚠️',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: Color(0xFF78350F), // Amber 900
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'لم يتم تأكيد هذا الحجز من العميل عبر الواتساب بعد.',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: Color(0xFF92400E), // Amber 800
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context
                                .read<AdminBookingDetailsCubit>()
                                .confirmWhatsappBooking(bookingId: booking.id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF10B981,
                            ), // Emerald 500
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            'تأكيد حجز العميل وتنشيط الطلب',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (booking.isCritical) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEF4444)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFEF4444),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'حالة طوارئ - تأخير في التنفيذ',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking.criticalReason ??
                                    'يوجد تأخير غير محدد في هذا الطلب، يرجى المتابعة فوراً.',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _buildSectionHeader(
                  'معلومات الخدمة',
                  Icons.cleaning_services_rounded,
                ),
                _buildServiceCard(),
                const SizedBox(height: 32),
                _buildSectionHeader('معلومات العميل', Icons.person_pin_rounded),
                _buildCustomerCard(context, customer),
                const SizedBox(height: 32),
                _buildSectionHeader('الفني المسؤول', Icons.engineering_rounded),
                _buildTechnicianCard(technician),
                const SizedBox(height: 32),
                _buildSectionHeader('مسار تنفيذ الطلب', Icons.history_rounded),
                _buildTimeline(),
                const SizedBox(height: 120),
              ],
            ),
          );
        },
      ),
      bottomSheet: _buildBottomActions(context),
    );
  }

  void _showCopyMessageDialog(
    BuildContext context, {
    bool isAutomatic = false,
  }) {
    final String customerName = booking.contact.name.isNotEmpty
        ? booking.contact.name
        : (customer?.fullName ?? 'عميل فريش هوم');
    String customerPhone = booking.contact.phone.isNotEmpty
        ? booking.contact.phone.first
        : '';
    if (customer != null &&
        !customer!.isAdmin &&
        customer!.phoneNumbers.isNotEmpty) {
      customerPhone = customer!.phoneNumbers.first.phoneNumber;
    }
    final String orderNumber = booking.readableId ?? booking.displayId;
    final String serviceName =
        booking.service.name['ar'] ??
        booking.service.name['en'] ??
        'خدمة منزلية';
    final String bookingDate = DateFormat(
      'yyyy-MM-dd',
    ).format(booking.scheduledAt);
    final String bookingTime = booking.startTimeSlot.length >= 5
        ? booking.startTimeSlot.substring(0, 5)
        : booking.startTimeSlot;
    final String trackingUrl =
        'https://freshhome-egypt.com/orders?bookingId=${booking.id}';

    final String messageText =
        'مرحباً $customerName 👋\n\n'
        'تم تأكيد حجزكم بنجاح لدى فريش هوم ✅\n\n'
        '📋 رقم الطلب: $orderNumber\n'
        '🏠 الخدمة: $serviceName\n'
        '📅 موعد الزيارة: $bookingDate\n'
        '⏰ الوقت: $bookingTime\n\n'
        'يمكنكم متابعة حالة الطلب والاطلاع على آخر التحديثات من خلال الرابط التالي:\n\n'
        '🔗 $trackingUrl\n\n'
        'شكراً لاختياركم فريش هوم، ونسعد بخدمتكم دائماً.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.copy_rounded,
                        color: Color(0xFF059669),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'رسالة تأكيد الحجز للعميل',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'تم تأكيد حجز العميل وتنشيط الطلب بنجاح. يمكنك نسخ الرسالة التالية لإرسالها للعميل عبر واتساب:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF475569),
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      messageText,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        height: 1.6,
                        color: Color(0xFF334155),
                      ),
                      textDirection: ui.TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: customerPhone.isNotEmpty
                      ? () async {
                          String cleanPhone = customerPhone.replaceAll(
                            RegExp(r'[\+\s\-]'),
                            '',
                          );
                          if (cleanPhone.startsWith('0') &&
                              cleanPhone.startsWith('01')) {
                            cleanPhone = '20${cleanPhone.substring(1)}';
                          }
                          final String whatsappUrl =
                              'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(messageText)}';
                          final Uri url = Uri.parse(whatsappUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text(
                    'إرسال مباشرة عبر الواتساب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext); // Close dialog
                          if (isAutomatic) {
                            Navigator.pop(context); // Go back to orders list
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'إغلاق',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: messageText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'تم نسخ الرسالة إلى الحافظة بنجاح ✅',
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.content_copy_rounded, size: 16),
                        label: const Text(
                          'نسخ الرسالة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'خطأ في العملية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF475569),
                  ),
                  textDirection: ui.TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'موافق',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    try {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint('Error launching dialer: $e');
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard() {
    return _InfoCard(
      child: Column(
        children: [
          _InfoRow(
            label: 'الخدمة المختارة',
            value: booking.service.name['ar'] ?? '',
            isHeader: true,
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _InfoRow(
            label: 'تاريخ وموعد الخدمة',
            value: DateFormat(
              'hh:mm a - yyyy/MM/dd',
              'ar',
            ).format(booking.scheduledAt),
          ),
          _InfoRow(
            label: 'حالة الطلب الحالية',
            value: _getStatusText(booking.status),
            valueColor: _getStatusColor(booking.status),
            isStatus: true,
          ),
          _InfoRow(
            label: 'السعر الإجمالي',
            value: '${booking.price.total} ج.م',
            isPrice: true,
          ),
          _InfoRow(
            label: 'وسيلة التحصيل المحددة',
            value: booking.paymentMethod?.toLowerCase() == 'instapay'
                ? 'تحويل إنستا باي (InstaPay)'
                : booking.paymentMethod?.toLowerCase() == 'vodafone_cash'
                ? 'تحويل فودافون كاش (Vodafone Cash)'
                : 'نقداً (كاش)',
          ),
          _InfoRow(
            label: 'حالة سداد تحصيل الفني',
            value: booking.paymentStatus == 'paid'
                ? 'تمت التسوية'
                : 'معلّق قيد التحصيل',
            valueColor: booking.paymentStatus == 'paid'
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
        return 'طلب جديد';
      case OrderStatus.pending:
        return 'بانتظار التعيين';
      case OrderStatus.assigned:
        return 'بانتظار قبول الفني';
      case OrderStatus.accepted:
        return 'مقبول (بانتظار التأكيد)';
      case OrderStatus.ready:
        return 'مؤكد (جاهز للتنفيذ)';
      case OrderStatus.onTheWay:
        return 'في الطريق للموقع';
      case OrderStatus.arrived:
        return 'وصل للموقع';
      case OrderStatus.inProgress:
        return 'قيد التنفيذ';
      case OrderStatus.completed:
        return 'مكتمل بنجاح';
      case OrderStatus.failed:
      case OrderStatus.failedNoShow:
        return 'فشل (عدم وصول)';
      case OrderStatus.expired:
        return 'منتهي الصلاحية';
      case OrderStatus.cancelled:
        return 'ملغي';
      case OrderStatus.pendingInspection:
        return 'بانتظار المعاينة';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
      case OrderStatus.pending:
        return const Color(0xFF94A3B8);
      case OrderStatus.assigned:
      case OrderStatus.accepted:
      case OrderStatus.ready:
        return const Color(0xFF1E3A8A);
      case OrderStatus.onTheWay:
        return const Color(0xFFF59E0B);
      case OrderStatus.arrived:
        return const Color(0xFF06B6D4);
      case OrderStatus.inProgress:
        return const Color(0xFF8B5CF6);
      case OrderStatus.completed:
        return const Color(0xFF10B981);
      case OrderStatus.failed:
      case OrderStatus.failedNoShow:
      case OrderStatus.expired:
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
      case OrderStatus.pendingInspection:
        return const Color(0xFF8B5CF6);
    }
  }

  Widget _buildCustomerCard(BuildContext context, UserProfile? customer) {
    final address = booking.address;
    final fullAddress =
        '${address.city}، ${address.street}، عمارة ${address.buildingNumber}${address.apartmentNumber != null ? '، شقة ${address.apartmentNumber}' : ''}${address.floorNumber != null ? '، دور ${address.floorNumber}' : ''}';

    // 1. Start with Manual Contact Data (Snapshot)
    String displayName = booking.contact.name;
    String displayPhone = booking.contact.phone.isNotEmpty
        ? booking.contact.phone.first
        : '';

    // 2. Resolve based on user type
    if (customer != null) {
      if (!customer.isAdmin) {
        // Real Customer: Use profile data as it's the source of truth for their account.
        if (customer.fullName.isNotEmpty &&
            !customer.fullName.toLowerCase().contains('user') &&
            customer.fullName != 'Client') {
          displayName = customer.fullName;
        }

        // If profile has phones, use them as they might be more up-to-date
        if (customer.phoneNumbers.isNotEmpty) {
          displayPhone = customer.phoneNumbers.first.phoneNumber;
        }
      } else {
        // Admin Profile: This was a manual booking.
        // We keep the snapshot data (displayName/displayPhone) as it holds the manually entered client info.
        // Note: If it shows 'Client' or is empty, it's because the data wasn't saved correctly in previous versions.
      }
    }

    return _InfoCard(
      child: Column(
        children: [
          _InfoRow(label: 'اسم العميل', value: displayName),
          _InfoRow(
            label: 'رقم الجوال',
            value: displayPhone.isNotEmpty ? displayPhone : 'غير متوفر',
            trailing: displayPhone.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.phone_enabled_rounded,
                      color: Colors.green,
                      size: 28,
                    ),
                    onPressed: () => _makeCall(displayPhone),
                  )
                : null,
          ),
          _InfoRow(
            label: 'عنوان الموقع بالتفصيل',
            value: fullAddress,
            isLast: false,
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showCopyMessageDialog(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(
                  Icons.share_rounded,
                  size: 16,
                  color: Color(0xFF1E3A8A),
                ),
                label: const Text(
                  'رسالة تأكيد الحجز (واتساب)',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard(UserProfile? technician) {
    final techPhone = technician?.phoneNumbers.isNotEmpty == true
        ? technician!.phoneNumbers.first.phoneNumber
        : '';

    return _InfoCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF1E3A8A),
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الفني المعين:',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      technician?.fullName ??
                          (booking.technicianId ?? 'لم يتم التعيين بعد'),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              if (techPhone.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.phone_enabled_rounded,
                    color: Colors.green,
                    size: 28,
                  ),
                  onPressed: () => _makeCall(techPhone),
                ),
            ],
          ),
          if (techPhone.isNotEmpty) ...[
            const Divider(height: 32, color: Color(0xFFF1F5F9)),
            _InfoRow(
              label: 'رقم جوال الفني',
              value: techPhone,
              isLast: true,
              trailing: IconButton(
                icon: const Icon(
                  Icons.phone_enabled_rounded,
                  color: Colors.green,
                  size: 20,
                ),
                onPressed: () => _makeCall(techPhone),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final statuses = [
      {
        'status': 'assigned',
        'label': 'تم التكليف بالفني',
        'time': booking.assignedAt,
      },
      {
        'status': 'accepted',
        'label': 'تم قبول الطلب',
        'time': booking.acceptedAt,
      },
      {
        'status': 'on_the_way',
        'label': 'الفني في الطريق',
        'time': booking.dispatchedAt,
      },
      {'status': 'arrived', 'label': 'وصل للموقع', 'time': booking.arrivedAt},
      {
        'status': 'in_progress',
        'label': 'بدء العمل الفعلي',
        'time': booking.startedAt,
      },
      {
        'status': 'completed',
        'label': 'إتمام المهمة',
        'time': booking.completedAt,
      },
    ];

    return _InfoCard(
      child: Column(
        children: statuses.map((s) {
          final isPast = s['time'] != null;
          final isLast = statuses.last == s;
          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPast
                            ? const Color(0xFF1E3A8A)
                            : const Color(0xFFE2E8F0),
                        border: isPast
                            ? Border.all(
                                color: const Color(
                                  0xFF1E3A8A,
                                ).withValues(alpha: 0.2),
                                width: 4,
                              )
                            : null,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: isPast
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['label'] as String,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: isPast
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isPast
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                        if (isPast)
                          Text(
                            DateFormat(
                              'hh:mm a - yyyy/MM/dd',
                              'ar',
                            ).format(s['time'] as DateTime),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontFamily: 'Cairo',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final status = booking.status;
    final canAction =
        status != OrderStatus.completed &&
        status != OrderStatus.cancelled &&
        status != OrderStatus.failedNoShow &&
        status != OrderStatus.expired;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (canAction) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showEditOrderDetailsSheet(context),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text(
                    'تعديل تفاصيل الطلب والأسعار',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Emerald
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'إعادة جدولة',
                    icon: Icons.calendar_today_rounded,
                    onPressed: canAction
                        ? () => _showRescheduleSheet(context)
                        : null,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'تغيير الفني',
                    icon: Icons.swap_horiz_rounded,
                    onPressed: canAction
                        ? () => _showReassignSheet(context)
                        : null,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'إلغاء الطلب',
                    icon: Icons.cancel_outlined,
                    onPressed: canAction
                        ? () => _showCancelDialog(context)
                        : null,
                    color: const Color(0xFFEF4444),
                    isOutline: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditOrderDetailsSheet(BuildContext context) {
    final cubit = context.read<AdminBookingDetailsCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EditOrderDetailsSheet(
        booking: booking,
        cubit: cubit,
        onError: (message) => _showErrorDialog(context, message),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    String selectedReasonCode = 'admin_decision';
    final bookingCubit = context.read<AdminBookingDetailsCubit>();
    final authCubit = context.read<AuthCubit>();

    final reasons = [
      {
        'code': 'admin_decision',
        'label': 'قرار إداري',
        'icon': Icons.admin_panel_settings_rounded,
      },
      {
        'code': 'customer_request',
        'label': 'طلب العميل',
        'icon': Icons.person_outline_rounded,
      },
      {
        'code': 'technician_unavailable',
        'label': 'الفني غير متاح',
        'icon': Icons.engineering_rounded,
      },
      {
        'code': 'duplicate_booking',
        'label': 'حجز مكرر',
        'icon': Icons.content_copy_rounded,
      },
      {
        'code': 'payment_issue',
        'label': 'مشكلة في الدفع',
        'icon': Icons.payment_rounded,
      },
      {'code': 'other', 'label': 'سبب آخر', 'icon': Icons.more_horiz_rounded},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.cancel_rounded,
                        color: Color(0xFFEF4444),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إلغاء الطلب',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '#${booking.displayId}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Warning banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'هذا الإجراء لا يمكن التراجع عنه. سيتم إخطار الفني والعميل بالإلغاء.',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Reason selector
                const Text(
                  'سبب الإلغاء',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                ...reasons.map((r) {
                  final isSelected = selectedReasonCode == r['code'];
                  return GestureDetector(
                    onTap: () => setSheetState(
                      () => selectedReasonCode = r['code'] as String,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            r['icon'] as IconData,
                            size: 20,
                            color: isSelected
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              r['label'] as String,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF1E293B),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Notes (optional)
                const Text(
                  'ملاحظات إضافية (اختياري)',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'أي ملاحظات إضافية...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontFamily: 'Cairo',
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Confirm cancel button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel_rounded, size: 20),
                    label: const Text(
                      'تأكيد إلغاء الطلب',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      final adminId = authCubit.userId ?? '';
                      bookingCubit.cancelBooking(
                        bookingId: booking.id,
                        adminId: adminId,
                        reasonCode: selectedReasonCode,
                        notes: reasonController.text.isNotEmpty
                            ? reasonController.text
                            : null,
                      );
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRescheduleSheet(BuildContext context) async {
    DateTime selectedDate = booking.scheduledAt;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(booking.scheduledAt);
    final reasonController = TextEditingController();
    bool isLoadingAvailability = true;
    Map<String, Map<String, bool>> availabilityMap = {};

    // Fetch availability immediately
    final startDate = DateTime.now();
    final endDate = startDate.add(const Duration(days: 30));

    GetIt.I<AvailabilityRemoteDataSource>()
        .getAvailableDays(
          serviceId: booking.service.subServiceId,
          startDate: DateFormat('yyyy-MM-dd').format(startDate),
          endDate: DateFormat('yyyy-MM-dd').format(endDate),
        )
        .then((list) {
          final String serviceKey =
              booking.service.name['en']?.toLowerCase().replaceAll(' ', '') ??
              'service';
          final Map<String, Map<String, bool>> map = {};
          for (final item in list) {
            final dateStr =
                item['available_date']
                    as String; // Assuming 'available_date' based on standard schema
            map[dateStr] = {
              serviceKey: true,
            }; // If it's in the list, it's available
          }
          availabilityMap = map;
          isLoadingAvailability = false;
        });

    final bookingCubit = context.read<AdminBookingDetailsCubit>();
    final authCubit = context.read<AuthCubit>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          if (isLoadingAvailability && availabilityMap.isEmpty) {
            GetIt.I<AvailabilityRemoteDataSource>()
                .getAvailableDays(
                  serviceId: booking.service.subServiceId,
                  startDate: DateFormat('yyyy-MM-dd').format(startDate),
                  endDate: DateFormat('yyyy-MM-dd').format(endDate),
                )
                .then((list) {
                  if (context.mounted) {
                    final String serviceKey =
                        booking.service.name['en']?.toLowerCase().replaceAll(
                          ' ',
                          '',
                        ) ??
                        'service';
                    final Map<String, Map<String, bool>> map = {};
                    for (final item in list) {
                      final dateStr = item['available_date'] as String;
                      map[dateStr] = {serviceKey: true};
                    }
                    setSheetState(() {
                      availabilityMap = map;
                      isLoadingAvailability = false;
                    });
                  }
                });
          }

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'إعادة جدولة الطلب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اختر الموعد الجديد المناسب من المواعيد المتاحة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Horizontal Date Picker
                  const Text(
                    'اختر التاريخ الجديد',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isLoadingAvailability)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    )
                  else
                    HorizontalDatePicker(
                      selectedDate: selectedDate,
                      selectedService: booking.service.name['en'] ?? 'Service',
                      availabilityMap: availabilityMap,
                      firstDate: startDate,
                      daysCount: 30,
                      onDateSelected: (date, _) =>
                          setSheetState(() => selectedDate = date),
                    ),

                  const SizedBox(height: 24),

                  // Time Selection
                  _buildSelectionTile(
                    context: context,
                    label: 'وقت الخدمة الجديد',
                    value: selectedTime.format(context),
                    icon: Icons.access_time_filled_rounded,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF1E3A8A),
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (time != null) {
                        setSheetState(() => selectedTime = time);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Reason
                  const Text(
                    'سبب إعادة الجدولة (اختياري)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'اكتب ملاحظاتك هنا...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        final newDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        final adminId = authCubit.userId ?? '';
                        bookingCubit.reschedule(
                          bookingId: booking.id,
                          newDateTime: newDateTime,
                          adminId: adminId,
                          reason: reasonController.text,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'تأكيد الموعد الجديد',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectionTile({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Color(0xFF1E293B),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  void _showReassignSheet(BuildContext context) async {
    debugPrint('🔍 [AdminBookingDetailsScreen] _showReassignSheet opened for Booking ID: "${booking.id}"');
    final reasonController = TextEditingController();
    String? selectedTechId;
    bool isLoadingTechs = true;
    List<UserRemoteModel> technicians = [];

    final bookingCubit = context.read<AdminBookingDetailsCubit>();
    final authCubit = context.read<AuthCubit>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          if (isLoadingTechs && technicians.isEmpty) {
            debugPrint('🔍 [AdminBookingDetailsScreen] Initiating fetch for qualified technicians. SubService ID: "${booking.service.subServiceId}", Date: ${booking.scheduledAt}');
            GetIt.I<UserManagementRepository>()
                .getTechniciansBySubService(
                  booking.service.subServiceId,
                  date: booking.scheduledAt,
                )
                .then((list) {
                  debugPrint('ℹ️ [AdminBookingDetailsScreen] Fetch complete. Received ${list.length} technicians.');
                  if (context.mounted) {
                    setSheetState(() {
                      technicians = list;
                      isLoadingTechs = false;
                    });
                  }
                }).catchError((error) {
                  debugPrint('❌ [AdminBookingDetailsScreen] Fetch failed with error: $error');
                  if (context.mounted) {
                    setSheetState(() {
                      isLoadingTechs = false;
                    });
                  }
                });
          }

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'تغيير الفني المسؤول',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اختر الفني الجديد الذي سيقوم بتنفيذ هذا الطلب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (isLoadingTechs)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    )
                  else
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: technicians.length,
                        itemBuilder: (context, index) {
                          final tech = technicians[index];
                          final isSelected = selectedTechId == tech.uid;
                          return GestureDetector(
                            onTap: () => setSheetState(() {
                              selectedTechId = tech.uid;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFFF7ED)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isSelected
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFCBD5E1),
                                    radius: 18,
                                    child: Text(
                                      tech.fullName.isNotEmpty
                                          ? tech.fullName[0].toUpperCase()
                                          : 'T',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tech.fullName,
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontWeight: isSelected
                                                ? FontWeight.w900
                                                : FontWeight.bold,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                        Text(
                                          tech.email,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFFF59E0B),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),
                  const Text(
                    'سبب تغيير الفني (اختياري)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'لماذا تريد تغيير الفني؟',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (selectedTechId != null)
                          ? () {
                              final adminId = authCubit.userId ?? '';
                              debugPrint('🚀 [AdminBookingDetailsScreen] Submitting reassignment. Technician ID: "$selectedTechId", Admin ID: "$adminId", Reason: "${reasonController.text}"');
                              bookingCubit.reassign(
                                bookingId: booking.id,
                                newTechnicianId: selectedTechId!,
                                adminId: adminId,
                                reason: reasonController.text,
                              );
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'تأكيد تعيين الفني',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;
  final bool isHeader;
  final bool isStatus;
  final bool isPrice;
  final Widget? trailing;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
    this.isHeader = false,
    this.isStatus = false,
    this.isPrice = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isStatus)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (valueColor ?? const Color(0xFF1E3A8A))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          value,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: valueColor ?? const Color(0xFF1E3A8A),
                            fontSize: 11,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          value,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: (isHeader || isPrice)
                                ? FontWeight.w900
                                : FontWeight.bold,
                            fontSize: isHeader ? 16 : (isPrice ? 16 : 14),
                            color: isPrice
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // ignore: use_null_aware_elements
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool isOutline;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutline) {
      return SizedBox(
        height: 54,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: onPressed == null
                ? const Color(0xFF94A3B8)
                : color,
            side: BorderSide(
              color: onPressed == null
                  ? const Color(0xFFE2E8F0)
                  : color.withValues(alpha: 0.5),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(icon, size: 16),
          label: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFF1F5F9),
          disabledForegroundColor: const Color(0xFF94A3B8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _EditOrderDetailsSheet extends StatefulWidget {
  final Booking booking;
  final AdminBookingDetailsCubit cubit;
  final void Function(String) onError;

  const _EditOrderDetailsSheet({
    super.key,
    required this.booking,
    required this.cubit,
    required this.onError,
  });

  @override
  State<_EditOrderDetailsSheet> createState() => _EditOrderDetailsSheetState();
}

class _EditOrderDetailsSheetState extends State<_EditOrderDetailsSheet> {
  SubServiceEntity? _subService;
  bool _loadingService = true;
  final Map<String, dynamic> _dynamicInputs = {};
  final List<String> _selectedOptions = [];
  BookingPricing? _calculatedPricing;
  bool _isCalculating = false;
  final Map<String, String> _validationErrors = {};

  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }

  Future<void> _loadServiceDetails() async {
    final getServiceById = GetIt.instance<GetServiceByIdUseCase>();
    final sId = widget.booking.serviceId ?? widget.booking.service.subServiceId;
    final result = await getServiceById(sId, forceRefresh: true);

    if (mounted) {
      result.fold(
        (failure) {
          // ignore: avoid_print
          print(
            '==================================================================',
          );
          // ignore: avoid_print
          print(
            '❌ [_EditOrderDetailsSheet] Load Service Details Error: ${failure.message}',
          );
          // ignore: avoid_print
          print(
            '==================================================================',
          );
          Navigator.pop(context);
          widget.onError("فشل تحميل بيانات الخدمة: ${failure.message}");
        },
        (service) {
          final subService = ServiceMapper.serviceToSubServiceEntity(service);
          setState(() {
            _subService = subService;
            _loadingService = false;
            if (widget.booking.pricingInputs != null) {
              _dynamicInputs.addAll(widget.booking.pricingInputs!);
            }
            if (_dynamicInputs['selected_options'] != null) {
              _selectedOptions.addAll(
                List<String>.from(_dynamicInputs['selected_options']),
              );
            }
            _calculatedPricing = widget.booking.price;
          });
        },
      );
    }
  }

  Future<void> _calculatePrice() async {
    if (_subService == null) return;

    // Validate inputs
    final errors = <String, String>{};
    final adjustedInputs = Map<String, dynamic>.from(_dynamicInputs);
    bool hasAdjustments = false;

    for (final field in _subService!.price.fields) {
      final val = adjustedInputs[field.id];
      final isRequired = field.required;

      if (isRequired) {
        if (val == null ||
            (val is String && val.trim().isEmpty) ||
            val == 0 ||
            val == 0.0) {
          errors[field.id] = "هذا الحقل مطلوب";
        } else if (field.type == DynamicFieldType.number) {
          final numVal = val is num ? val : num.tryParse(val.toString());
          if (numVal != null && field.min != null && numVal < field.min!) {
            adjustedInputs[field.id] = field.min!.toDouble();
            hasAdjustments = true;
          }
        }
      } else {
        if (val != null &&
            (val is! String || val.trim().isNotEmpty) &&
            field.type == DynamicFieldType.number &&
            val != 0 &&
            val != 0.0) {
          final numVal = val is num ? val : num.tryParse(val.toString());
          if (numVal != null && field.min != null && numVal < field.min!) {
            adjustedInputs[field.id] = field.min!.toDouble();
            hasAdjustments = true;
          }
        }
      }
    }

    if (errors.isNotEmpty) {
      setState(() {
        _validationErrors.clear();
        _validationErrors.addAll(errors);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "يرجى استكمال الحقول المطلوبة بشكل صحيح",
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _validationErrors.clear();
      if (hasAdjustments) {
        _dynamicInputs.clear();
        _dynamicInputs.addAll(adjustedInputs);
      }
      _isCalculating = true;
    });

    final calculatePriceUseCase = GetIt.instance<CalculatePriceUseCase>();
    final cleanInputs = Map<String, dynamic>.from(_dynamicInputs);
    cleanInputs.removeWhere((k, v) => v == null || v == "");

    final result = await calculatePriceUseCase(
      CalculatePriceParams(
        priceEntity: _subService!.price,
        subServiceId: _subService!.id,
        pricingInputs: cleanInputs,
        selectedOptions: _selectedOptions,
      ),
    );

    if (mounted) {
      setState(() {
        _isCalculating = false;
      });
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "فشل حساب السعر: ${failure.message}",
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        },
        (pricing) {
          setState(() {
            _calculatedPricing = pricing;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingService) {
      return Container(
        color: Colors.white,
        height: 300,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final computedFieldIds =
        _subService!.computedFields?.map((cf) => cf.id).toSet() ?? {};
    final filteredFields = _subService!.price.fields
        .where((f) => !computedFieldIds.contains(f.id))
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "تعديل تفاصيل الطلب والأسعار",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Form Renderer
            DynamicFormRenderer(
              fields: filteredFields,
              values: _dynamicInputs,
              options: _subService!.price.options,
              selectedOptions: _selectedOptions,
              validationErrors: _validationErrors,
              onFieldChanged: (key, value) {
                setState(() {
                  if (value == null) {
                    _dynamicInputs.remove(key);
                  } else {
                    _dynamicInputs[key] = value;
                  }
                  _validationErrors.remove(key);
                  _calculatedPricing = null;
                });
              },
              onOptionToggled: (optionKey) {
                setState(() {
                  if (_selectedOptions.contains(optionKey)) {
                    _selectedOptions.remove(optionKey);
                  } else {
                    _selectedOptions.add(optionKey);
                  }
                  _dynamicInputs['selected_options'] = _selectedOptions;
                  _calculatedPricing = null;
                });
              },
            ),

            const SizedBox(height: 24),

            // Recalculation Button
            if (_calculatedPricing == null)
              ElevatedButton.icon(
                onPressed: _isCalculating ? null : _calculatePrice,
                icon: _isCalculating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.calculate_rounded),
                label: Text(
                  _isCalculating ? "جاري الحساب..." : "حساب السعر الجديد",
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A), // Slate blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              )
            else ...[
              // Pricing breakdown card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "تفاصيل الحساب الجديد",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPriceRow(
                      "سعر الخدمة الأساسي",
                      "${_calculatedPricing!.basePrice.toStringAsFixed(2)} ج.م",
                    ),
                    if (_calculatedPricing!.extraFees > 0) ...[
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        "رسوم إضافية",
                        "${_calculatedPricing!.extraFees.toStringAsFixed(2)} ج.م",
                      ),
                    ],
                    if (_calculatedPricing!.discount > 0) ...[
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        "الخصم المطبق",
                        "- ${_calculatedPricing!.discount.toStringAsFixed(2)} ج.م",
                        isDiscount: true,
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                    _buildPriceRow(
                      "إجمالي السعر الجديد للعميل",
                      "${_calculatedPricing!.total.toStringAsFixed(2)} ج.م",
                      isBold: true,
                      textColor: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Save button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.cubit.updateBookingDetails(
                    booking: widget.booking,
                    pricingInputs: _dynamicInputs,
                    price: _calculatedPricing!,
                  );
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  "تحديث وحفظ التعديلات",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    bool isDiscount = false,
    Color? textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? Colors.black87 : Colors.black54,
              fontFamily: 'Cairo',
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color:
                textColor ?? (isDiscount ? Colors.redAccent : Colors.black87),
            fontFamily: 'Cairo',
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
