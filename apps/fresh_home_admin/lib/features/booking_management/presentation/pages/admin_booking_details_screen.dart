import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
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

  const AdminBookingDetailsScreen({
    super.key,
    this.booking,
    this.bookingId,
  });

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
      builder: (context, state) {
        if (state is AdminBookingDetailsLoading || state is AdminBookingDetailsInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is AdminBookingDetailsError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(state.message)),
          );
        }
        if (state is AdminBookingDetailsLoaded) {
          return _AdminBookingDetailsContent(
            booking: state.booking!,
            customer: state.customer,
            technician: state.technician,
          );
        }
        return const Scaffold(body: Center(child: Text('Unknown State')));
      },
    );
  }
}

class _AdminBookingDetailsContent extends StatelessWidget {
  final Booking booking;
  final User? customer;
  final User? technician;

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
            Navigator.pop(context);
          }
          if (state is AdminBookingDetailsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 28),
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
                                booking.criticalReason ?? 'يوجد تأخير غير محدد في هذا الطلب، يرجى المتابعة فوراً.',
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
                _buildCustomerCard(customer),
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
            isLast: true,
            isPrice: true,
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

  Widget _buildCustomerCard(User? customer) {
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
        if (customer.phones.isNotEmpty) {
          displayPhone = customer.phones.first;
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
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard(User? technician) {
    final techPhone = technician?.phones.isNotEmpty == true
        ? technician!.phones.first
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
      {
        'status': 'arrived',
        'label': 'وصل للموقع',
        'time': booking.arrivedAt,
      },
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
                                color: const Color(0xFF1E3A8A).withValues(alpha:0.2),
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
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'إعادة جدولة',
                    icon: Icons.calendar_today_rounded,
                    onPressed: canAction ? () => _showRescheduleSheet(context) : null,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'تغيير الفني',
                    icon: Icons.swap_horiz_rounded,
                    onPressed: canAction ? () => _showReassignSheet(context) : null,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'إلغاء الطلب',
                    icon: Icons.cancel_outlined,
                    onPressed: canAction ? () => _showCancelDialog(context) : null,
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

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    String selectedReasonCode = 'admin_decision';
    final bookingCubit = context.read<AdminBookingDetailsCubit>();
    final authCubit = context.read<AuthCubit>();

    final reasons = [
      {'code': 'admin_decision',     'label': 'قرار إداري',              'icon': Icons.admin_panel_settings_rounded},
      {'code': 'customer_request',   'label': 'طلب العميل',              'icon': Icons.person_outline_rounded},
      {'code': 'technician_unavailable', 'label': 'الفني غير متاح',     'icon': Icons.engineering_rounded},
      {'code': 'duplicate_booking',  'label': 'حجز مكرر',               'icon': Icons.content_copy_rounded},
      {'code': 'payment_issue',      'label': 'مشكلة في الدفع',         'icon': Icons.payment_rounded},
      {'code': 'other',              'label': 'سبب آخر',                'icon': Icons.more_horiz_rounded},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24, left: 24, right: 24,
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
                    width: 48, height: 5,
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
                      child: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إلغاء الطلب',
                          style: TextStyle(
                            fontFamily: 'Cairo', fontWeight: FontWeight.w900,
                            fontSize: 20, color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '#${booking.displayId}',
                          style: const TextStyle(
                            fontFamily: 'Cairo', color: Color(0xFF64748B), fontSize: 14,
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
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'هذا الإجراء لا يمكن التراجع عنه. سيتم إخطار الفني والعميل بالإلغاء.',
                          style: TextStyle(
                            fontFamily: 'Cairo', fontSize: 12,
                            color: Color(0xFF92400E), fontWeight: FontWeight.bold,
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
                    fontFamily: 'Cairo', fontWeight: FontWeight.w900,
                    fontSize: 15, color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                ...reasons.map((r) {
                  final isSelected = selectedReasonCode == r['code'];
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedReasonCode = r['code'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            r['icon'] as IconData,
                            size: 20,
                            color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              r['label'] as String,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                                color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFFEF4444), size: 20),
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
                    fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                    fontSize: 14, color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'أي ملاحظات إضافية...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
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
                        fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      final adminId = authCubit.userId ?? '';
                      bookingCubit.cancelBooking(
                        bookingId: booking.id,
                        adminId: adminId,
                        reasonCode: selectedReasonCode,
                        notes: reasonController.text.isNotEmpty ? reasonController.text : null,
                      );
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    if (time != null) setSheetState(() => selectedTime = time);
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
    final reasonController = TextEditingController();
    String? selectedTechId;
    bool isLoadingTechs = true;
    List<UserRemoteModel> technicians = [];

    // Fetch technicians specialized in this service
    GetIt.I<UserManagementRepository>()
        .getTechniciansBySubService(booking.service.subServiceId)
        .then((list) {
          technicians = list;
          isLoadingTechs = false;
        });

    final bookingCubit = context.read<AdminBookingDetailsCubit>();
    final authCubit = context.read<AuthCubit>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          if (isLoadingTechs && technicians.isEmpty) {
            GetIt.I<UserManagementRepository>()
                .getTechniciansBySubService(booking.service.subServiceId)
                .then((list) {
                  if (context.mounted) {
                    setSheetState(() {
                      technicians = list;
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
                              .withValues(alpha:0.1),
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
            foregroundColor: onPressed == null ? const Color(0xFF94A3B8) : color,
            side: BorderSide(
              color: onPressed == null ? const Color(0xFFE2E8F0) : color.withValues(alpha:0.5),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: Icon(icon, size: 16),
          label: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12,
          ),
        ),
      ),
    );
  }
}
