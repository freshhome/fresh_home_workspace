import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared/shared.dart';
import 'package:shared_features/shared_features.dart';
import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fresh_home_admin/features/user_management/domain/repositories/user_management_repository.dart';
import '../../domain/usecases/admin_reassign_booking.dart';
import '../../domain/usecases/admin_reschedule_booking.dart';
import '../../domain/usecases/admin_delete_booking.dart';
import '../cubit/admin_bookings_cubit.dart';

/// Redesigned Admin Booking Card:
/// - Upper Half: Order data (Service name, Customer name, Status & badges on start side;
///   Order ID, Price, Date & Time on trailing side).
/// - Lower Half: Quick Action Buttons (Call client, Reschedule, Change technician, Cancel booking, Delete permanently).
class AdminBookingCard extends StatelessWidget {
  final Booking booking;

  const AdminBookingCard({
    super.key,
    required this.booking,
  });

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
      case OrderStatus.pending:
        return const Color(0xFF64748B);
      case OrderStatus.assigned:
      case OrderStatus.accepted:
      case OrderStatus.ready:
        return const Color(0xFF1E3A8A);
      case OrderStatus.pendingInspection:
        return const Color(0xFF8B5CF6);
      case OrderStatus.onTheWay:
        return const Color(0xFFF59E0B);
      case OrderStatus.arrived:
        return const Color(0xFF06B6D4);
      case OrderStatus.inProgress:
        return const Color(0xFF3B82F6);
      case OrderStatus.completed:
        return const Color(0xFF10B981);
      case OrderStatus.cancelled:
      case OrderStatus.failed:
      case OrderStatus.failedNoShow:
      case OrderStatus.expired:
        return const Color(0xFFEF4444);
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
        return 'جديد';
      case OrderStatus.pending:
        return 'بانتظار تعيين';
      case OrderStatus.assigned:
        return 'مسند لفني';
      case OrderStatus.accepted:
        return 'مقبول';
      case OrderStatus.ready:
        return 'جاهز للتنفيذ';
      case OrderStatus.onTheWay:
        return 'في الطريق';
      case OrderStatus.arrived:
        return 'وصل للموقع';
      case OrderStatus.inProgress:
        return 'قيد العمل';
      case OrderStatus.completed:
        return 'مكتمل';
      case OrderStatus.cancelled:
        return 'ملغي';
      case OrderStatus.failed:
        return 'فاشل';
      case OrderStatus.failedNoShow:
        return 'فشل (عدم حضور)';
      case OrderStatus.expired:
        return 'منتهي';
      case OrderStatus.pendingInspection:
        return 'بانتظار المعاينة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceName = booking.service.name['ar'] ??
        booking.service.name['en'] ??
        'خدمة منزلية';

    final districtName = (booking.address.district != null &&
            booking.address.district!.trim().isNotEmpty)
        ? booking.address.district!.trim()
        : (booking.address.city.trim().isNotEmpty
            ? booking.address.city.trim()
            : (booking.address.governorate.trim().isNotEmpty
                ? booking.address.governorate.trim()
                : 'العنوان غير محدد'));

    final totalVal = booking.price.total;
    final priceFormatted = totalVal % 1 == 0
        ? totalVal.toInt().toString()
        : totalVal.toStringAsFixed(1);

    final idText = booking.displayId.isNotEmpty
        ? booking.displayId
        : (booking.id.length >= 8 ? booking.id.substring(0, 8) : booking.id);

    final isFinished = booking.status == OrderStatus.completed ||
        booking.status == OrderStatus.cancelled ||
        booking.status == OrderStatus.failed ||
        booking.status == OrderStatus.failedNoShow ||
        booking.status == OrderStatus.expired;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------------------------------------------------------------
              // Emergency / Critical alert if active
              // -------------------------------------------------------------
              if (booking.isCritical) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking.criticalReason ?? 'حالة طوارئ نشطة',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Color(0xFFB91C1C),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // -------------------------------------------------------------
              // Upper Area: Row 1 & Row 2 (Tapping opens booking details)
              // -------------------------------------------------------------
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => GoRouter.of(context).push(
                    '/admin/bookings/detail/${booking.id}',
                    extra: booking,
                  ),
                  child: Column(
                    children: [
                      // Row 1: Right = Service Name, Left = ID Badge
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Service Name (Bold, adaptive to 2 lines to prevent clipping)
                            Expanded(
                              child: Text(
                                serviceName,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                  color: Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // ID Badge (#FH-O-...)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#$idText',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Row 2: Bordered Box (Right = District, Left = Price)
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // District / Area
                              Expanded(
                                child: Text(
                                  districtName,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Formatted Price: "السعر : 5000 ج.م"
                              Text.rich(
                                TextSpan(
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'السعر : ',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '$priceFormatted ',
                                      style: const TextStyle(
                                        color: Color(0xFFE11D48),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'ج.م',
                                      style: TextStyle(
                                        color: Color(0xFF059669),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // Row 3: Action Icon Buttons
              // For finished/completed orders: 3 buttons (Call, Re-book, Delete)
              // For active orders: 5 buttons (Call, Reschedule, Tech, Cancel, Delete)
              // -------------------------------------------------------------
              Directionality(
                textDirection: TextDirection.rtl,
                child: isFinished
                    ? Row(
                        children: [
                          // 1. Phone (Call Customer) - Green
                          Expanded(
                            child: _buildSquareActionButton(
                              key: const Key('admin_card_call_button'),
                              context: context,
                              icon: Icons.phone_outlined,
                              iconColor: const Color(0xFF059669),
                              backgroundColor: const Color(0xFFECFDF5),
                              borderColor: const Color(0xFFA7F3D0),
                              tooltip: 'اتصال بالعميل',
                              onTap: () => _callCustomer(context),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 2. Re-book (إعادة الحجز) - Blue
                          Expanded(
                            child: _buildSquareActionButton(
                              key: const Key('admin_card_rebook_button'),
                              context: context,
                              icon: Icons.replay_rounded,
                              iconColor: const Color(0xFF2563EB),
                              backgroundColor: const Color(0xFFEFF6FF),
                              borderColor: const Color(0xFFBFDBFE),
                              tooltip: 'إعادة الحجز',
                              onTap: () => _rebookOrder(context),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 3. Delete Permanently - Red
                          Expanded(
                            child: _buildSquareActionButton(
                              key: const Key('admin_card_delete_button'),
                              context: context,
                              icon: Icons.delete_outline_rounded,
                              iconColor: const Color(0xFFE11D48),
                              backgroundColor: const Color(0xFFFEF2F2),
                              borderColor: const Color(0xFFFECACA),
                              tooltip: 'حذف نهائي',
                              onTap: () => _confirmPermanentDelete(context),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          // 1. Phone (Call Customer) - Green
                          Expanded(
                            child: _buildSquareActionButton(
                              key: const Key('admin_card_call_button'),
                              context: context,
                              icon: Icons.phone_outlined,
                              iconColor: const Color(0xFF059669),
                              backgroundColor: const Color(0xFFECFDF5),
                              borderColor: const Color(0xFFA7F3D0),
                              tooltip: 'اتصال بالعميل',
                              onTap: () => _callCustomer(context),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 2. Clock (Reschedule) - Blue
                          Expanded(
                            child: _buildSquareActionButton(
                              key: const Key('admin_card_reschedule_button'),
                              context: context,
                              icon: Icons.access_time_rounded,
                              iconColor: const Color(0xFF2563EB),
                              backgroundColor: const Color(0xFFEFF6FF),
                              borderColor: const Color(0xFFBFDBFE),
                              tooltip: 'تعديل الموعد',
                              onTap: () => _showRescheduleSheet(context),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 3. Technician (Reassign) - Yellow/Amber
                          Expanded(
                            child: _buildSquareActionButton(
                              key: const Key('admin_card_technician_button'),
                              context: context,
                              icon: Icons.manage_accounts_outlined,
                              iconColor: const Color(0xFFD97706),
                              backgroundColor: const Color(0xFFFEFCE8),
                              borderColor: const Color(0xFFFDE68A),
                              tooltip: 'تغيير الفني',
                              onTap: () => _showReassignSheet(context),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 4. Cancel / Edit Note - Slate/Blue-Grey
                          Expanded(
                            child: _buildSquareActionButton(
                              key: const Key('admin_card_cancel_button'),
                              context: context,
                              icon: Icons.edit_note_rounded,
                              iconColor: const Color(0xFF334155),
                              backgroundColor: const Color(0xFFF8FAFC),
                              borderColor: const Color(0xFFE2E8F0),
                              tooltip: 'إلغاء الحجز',
                              onTap: () => _showCancelDialog(context),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 5. Delete Permanently - Red
                          Expanded(
                            child: _buildSquareActionButton(
                              key: const Key('admin_card_delete_button'),
                              context: context,
                              icon: Icons.delete_outline_rounded,
                              iconColor: const Color(0xFFE11D48),
                              backgroundColor: const Color(0xFFFEF2F2),
                              borderColor: const Color(0xFFFECACA),
                              tooltip: 'حذف نهائي',
                              onTap: () => _confirmPermanentDelete(context),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquareActionButton({
    Key? key,
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              height: 48,
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // Quick Action 1: الاتصال بالعميل
  // ==========================================================================
  void _callCustomer(BuildContext context) async {
    final phones = booking.contact.phone;
    if (phones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يوجد رقم هاتف مسجل لهذا العميل.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (phones.length == 1) {
      final uri = Uri.parse('tel:${phones.first.trim()}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تعذر فتح الاتصال بالرقم ${phones.first}',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
      return;
    }

    // Multiple numbers: show picker
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر رقم الاتصال بالعميل:',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            ...phones.map(
              (p) => ListTile(
                leading: const Icon(
                  Icons.phone_rounded,
                  color: Color(0xFF10B981),
                ),
                title: Text(
                  p,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final uri = Uri.parse('tel:${p.trim()}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // Quick Action: إعادة الحجز للأوردرات المكتملة / المنتهية
  // ==========================================================================
  void _rebookOrder(BuildContext context) {
    final adminId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final draftId =
        'rebook_${booking.id}_${DateTime.now().millisecondsSinceEpoch}';

    final draft = BookingDraft(
      id: draftId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      currentStepIndex: 2, // Lands directly on Schedule step (Date & Time selection)
      clientName: booking.contact.name,
      clientPhone: booking.contact.phone.isNotEmpty
          ? booking.contact.phone.first
          : null,
      serviceName: booking.service.name['ar'] ?? booking.service.name['en'],
      serviceTitle:
          booking.service.name.map((k, v) => MapEntry(k, v.toString())),
      subServiceId: booking.service.subServiceId,
      serviceImage: booking.service.image,
      priceTotal: booking.price.total,
      isPriceCalculated: true,
      scheduledAt: null, // Intentionally null so new dates can be selected
      manualClientGovernorate: booking.address.governorate,
      manualClientCity: booking.address.city,
      manualClientDistrict: booking.address.district,
      manualClientStreet: booking.address.streetOrCompound,
      manualClientBuilding: booking.address.buildingIdentifier,
      manualClientFloor: booking.address.floor,
      manualClientApartment: booking.address.apartmentOrUnit,
      manualClientLandmark: booking.address.landmark,
      manualClientPropertyType: booking.address.propertyType,
      manualClientLocationUrl: booking.address.locationUrl,
      manualClientLatitude: booking.address.latitude,
      manualClientLongitude: booking.address.longitude,
    );

    GoRouter.of(context).pushNamed(
      AppRoutes.bookingFlow,
      extra: BookingFlowConfig(
        mode: BookingFlowMode.admin,
        actorId: adminId,
        preSelectedService: booking.service,
        initialDraft: draft,
      ),
    );
  }

  // ==========================================================================
  // Quick Action 2: تعديل الموعد (Reschedule)
  // ==========================================================================
  void _showRescheduleSheet(BuildContext context) async {
    DateTime selectedDate = booking.scheduledAt;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(booking.scheduledAt);
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'تعديل موعد الحجز',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pick Date
                  const Text(
                    'التاريخ الجديد:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF1E3A8A),
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF8FAFC),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: Color(0xFF1E3A8A),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('yyyy/MM/dd').format(selectedDate),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pick Time
                  const Text(
                    'الوقت الجديد:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
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
                      if (picked != null) {
                        setSheetState(() => selectedTime = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF8FAFC),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFF1E3A8A),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedTime.format(context),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reason
                  const Text(
                    'سبب إعادة الجدولة (اختياري):',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'مثال: طلب العميل تعديل الوقت...',
                      hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setSheetState(() => isSubmitting = true);
                              final combinedDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );
                              final adminId = Supabase
                                      .instance.client.auth.currentUser?.id ??
                                  '';

                              final rescheduleUseCase =
                                  GetIt.I<AdminRescheduleBooking>();
                              final result = await rescheduleUseCase(
                                bookingId: booking.id,
                                newDateTime: combinedDateTime,
                                adminId: adminId,
                                reason: reasonController.text.trim().isNotEmpty
                                    ? reasonController.text.trim()
                                    : 'تعديل موعد بواسطة الإدارة',
                              );

                              if (context.mounted) {
                                Navigator.pop(sheetContext);
                                result.fold(
                                  (failure) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'فشل تعديل الموعد: ${failure.message}',
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                        backgroundColor:
                                            const Color(0xFFEF4444),
                                      ),
                                    );
                                  },
                                  (_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'تم تعديل موعد الحجز بنجاح!',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                        backgroundColor:
                                            Color(0xFF10B981),
                                      ),
                                    );
                                    context
                                        .read<AdminBookingsCubit>()
                                        .refreshBookings();
                                  },
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'تأكيد تعديل الموعد',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // Quick Action 3: تغيير الفني (Change Technician)
  // ==========================================================================
  void _showReassignSheet(BuildContext context) async {
    final reasonController = TextEditingController();
    String? selectedTechId;
    bool isLoadingTechs = true;
    bool isSubmitting = false;
    List<UserRemoteModel> technicians = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          if (isLoadingTechs && technicians.isEmpty) {
            GetIt.I<UserManagementRepository>()
                .getTechniciansBySubService(
                  booking.service.subServiceId,
                  date: booking.scheduledAt,
                )
                .then((list) {
                  if (context.mounted) {
                    setSheetState(() {
                      technicians = list;
                      isLoadingTechs = false;
                    });
                  }
                })
                .catchError((_) {
                  if (context.mounted) {
                    setSheetState(() {
                      isLoadingTechs = false;
                    });
                  }
                });
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'إعادة تعيين فني للطلب',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اختر الفني البديل من قائمة الفنيين المؤهلين للخدمة:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (isLoadingTechs) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                      ),
                    ),
                  ] else if (technicians.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'لا يوجد فنيين آخرين متاحين لهذه الخدمة في هذا الموعد.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: Color(0xFFB91C1C),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: technicians.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tech = technicians[index];
                          final isSelected = selectedTechId == tech.id;
                          return InkWell(
                            onTap: () {
                              setSheetState(() => selectedTechId = tech.id);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEFF6FF)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1E3A8A)
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    child: Text(
                                      tech.fullName.isNotEmpty
                                          ? tech.fullName[0]
                                          : 'ف',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tech.fullName,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          tech.phones?.isNotEmpty == true
                                              ? tech.phones!.first.phoneNumber
                                              : tech.email,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
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
                                      color: Color(0xFF1E3A8A),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'سبب تغيير الفني (اختياري)...',
                      hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: (selectedTechId == null || isSubmitting)
                          ? null
                          : () async {
                              setSheetState(() => isSubmitting = true);
                              final adminId = Supabase
                                      .instance.client.auth.currentUser?.id ??
                                  '';
                              final reassignUseCase =
                                  GetIt.I<AdminReassignBooking>();
                              final result = await reassignUseCase(
                                bookingId: booking.id,
                                newTechnicianId: selectedTechId!,
                                adminId: adminId,
                                reason: reasonController.text.trim().isNotEmpty
                                    ? reasonController.text.trim()
                                    : 'إعادة تعيين فني بواسطة الإدارة',
                              );

                              if (context.mounted) {
                                Navigator.pop(sheetContext);
                                result.fold(
                                  (failure) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'فشل تغيير الفني: ${failure.message}',
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                        backgroundColor:
                                            const Color(0xFFEF4444),
                                      ),
                                    );
                                  },
                                  (_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'تم تغيير الفني وإسناد الطلب بنجاح!',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                        backgroundColor:
                                            Color(0xFF10B981),
                                      ),
                                    );
                                    context
                                        .read<AdminBookingsCubit>()
                                        .refreshBookings();
                                  },
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'تأكيد تعيين الفني',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // Quick Action 4: إلغاء الحجز (Cancel Booking)
  // ==========================================================================
  void _showCancelDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    String selectedReasonCode = 'admin_decision';

    final reasons = [
      {'code': 'admin_decision', 'label': 'قرار إداري'},
      {'code': 'customer_request', 'label': 'طلب العميل'},
      {'code': 'technician_unavailable', 'label': 'عدم توفر فني'},
      {'code': 'duplicate_booking', 'label': 'حجز مكرر'},
      {'code': 'other', 'label': 'أسباب أخرى'},
    ];

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  color: Color(0xFFE11D48),
                ),
                SizedBox(width: 8),
                Text(
                  'إلغاء الحجز',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'هل أنت متأكد من إلغاء الحجز رقم #${booking.displayId}؟',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'سبب الإلغاء:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReasonCode,
                        isExpanded: true,
                        items: reasons
                            .map(
                              (r) => DropdownMenuItem(
                                value: r['code'],
                                child: Text(
                                  r['label']!,
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedReasonCode = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'ملاحظات إضافية...',
                      hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'تراجع',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final adminId =
                      Supabase.instance.client.auth.currentUser?.id ?? '';
                  final repo = GetIt.I<BookingRepository>();

                  final result = await repo.transitionBooking(
                    bookingId: booking.id,
                    newStatus: OrderStatus.cancelled,
                    actorId: adminId,
                    actorRole: 'admin',
                    reason: selectedReasonCode,
                    notes: reasonController.text.trim().isNotEmpty
                        ? reasonController.text.trim()
                        : null,
                  );

                  if (context.mounted) {
                    result.fold(
                      (failure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'فشل إلغاء الحجز: ${failure.message}',
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      },
                      (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم إلغاء الحجز بنجاح.',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                        context
                            .read<AdminBookingsCubit>()
                            .refreshBookings();
                      },
                    );
                  }
                },
                child: const Text(
                  'تأكيد الإلغاء',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // Quick Action 5: حذف الأوردر نهائياً (Delete Booking Permanently)
  // ==========================================================================
  void _confirmPermanentDelete(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Color(0xFFDC2626),
              size: 26,
            ),
            SizedBox(width: 8),
            Text(
              'تأكيد الحذف النهائي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من رغبتك في حذف الحجز رقم #${booking.displayId} نهائياً؟',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Text(
                '⚠️ تحذير: هذا الإجراء سيقوم بمسح الحجز وكافة السجلات المرتبطة به بشكل كامل ولا يمكن التراجع عنه.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final deleteUseCase = GetIt.I<AdminDeleteBooking>();
              final result = await deleteUseCase(bookingId: booking.id);

              if (context.mounted) {
                result.fold(
                  (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'فشل حذف الحجز: ${failure.message}',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  },
                  (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تم حذف الحجز نهائياً بنجاح.',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                    context.read<AdminBookingsCubit>().refreshBookings();
                  },
                );
              }
            },
            child: const Text(
              'حذف نهائي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
