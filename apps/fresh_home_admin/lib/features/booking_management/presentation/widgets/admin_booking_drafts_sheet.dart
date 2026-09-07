import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:shared/domain/booking/entities/booking/booking_draft.dart';
import 'package:shared_features/shared_features.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubit/admin_booking_drafts_cubit.dart';

class AdminBookingDraftsSheet extends StatelessWidget {
  const AdminBookingDraftsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminBookingDraftsCubit>(),
        child: const AdminBookingDraftsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_late_outlined,
                    color: Color(0xFF1E3A8A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المسودات المعلقة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'حجوزات المكالمات المحفوظة محلياً',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<AdminBookingDraftsCubit, AdminBookingDraftsState>(
                  builder: (context, state) {
                    if (state is AdminBookingDraftsLoaded &&
                        state.drafts.isNotEmpty) {
                      return TextButton.icon(
                        onPressed: () => _confirmClearAll(context),
                        icon: const Icon(Icons.delete_sweep_outlined,
                            size: 18, color: Colors.redAccent),
                        label: const Text(
                          'مسح الكل',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body
          Expanded(
            child: BlocBuilder<AdminBookingDraftsCubit, AdminBookingDraftsState>(
              builder: (context, state) {
                if (state is AdminBookingDraftsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AdminBookingDraftsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 44, color: Colors.redAccent),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: const TextStyle(
                              fontFamily: 'Cairo', color: Colors.redAccent),
                        ),
                      ],
                    ),
                  );
                }
                if (state is AdminBookingDraftsLoaded) {
                  if (state.drafts.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: state.drafts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final draft = state.drafts[index];
                      return _buildDraftCard(context, draft);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 56,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد مسودات معلقة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'عندما يتصل عميل ويطلب إرسال العنوان أو اللوكيشن لاحقاً، يمكنك حفظ الحجز كمسودة والرجوع إليه من هنا فوراً.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftCard(BuildContext context, BookingDraft draft) {
    final clientName =
        (draft.clientName != null && draft.clientName!.trim().isNotEmpty)
            ? draft.clientName!
            : 'عميل مكالمة (بدون اسم)';
    final clientPhone =
        (draft.clientPhone != null && draft.clientPhone!.trim().isNotEmpty)
            ? draft.clientPhone!
            : 'لم يسجل رقم الهاتف';
    final serviceName = draft.serviceName ?? 'لم تحدد الخدمة';
    final priceStr = draft.priceTotal != null
        ? '${draft.priceTotal!.toStringAsFixed(0)} ج.م'
        : 'سعر غير محسوب';
    final timeAgo = _formatRelativeTime(draft.updatedAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Client & Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.person,
                            color: Color(0xFF1E3A8A), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          clientName,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timeAgo,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 2: Phone
            Row(
              children: [
                const Icon(Icons.phone_iphone_rounded,
                    size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  clientPhone,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            // Row 3: Service & Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.cleaning_services_outlined,
                          size: 16, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          serviceName,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  priceStr,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            if (draft.scheduledAt != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(draft.scheduledAt!),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            // Actions
            Row(
              children: [
                // Delete button
                IconButton(
                  onPressed: () => _confirmDelete(context, draft),
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  tooltip: 'حذف المسودة',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Resume button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _resumeDraft(context, draft),
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: const Text(
                      'استكمال الحجز',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
  }

  void _resumeDraft(BuildContext context, BookingDraft draft) {
    Navigator.of(context).pop(); // Close sheet

    final adminId = Supabase.instance.client.auth.currentUser?.id ?? '';
    GoRouter.of(context).pushNamed(
      AppRoutes.bookingFlow,
      extra: BookingFlowConfig(
        mode: BookingFlowMode.admin,
        actorId: adminId,
        initialDraft: draft,
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<AdminBookingDraftsCubit>().loadDrafts();
      }
    });
  }

  void _confirmDelete(BuildContext context, BookingDraft draft) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'حذف المسودة',
            style: TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Text(
            'هل أنت متأكد من حذف مسودة "${draft.clientName ?? 'العميل'}"؟ لا يمكن التراجع عن هذا الإجراء.',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('إلغاء',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                context.read<AdminBookingDraftsCubit>().deleteDraft(draft.id);
              },
              child: const Text(
                'حذف',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'مسح جميع المسودات',
            style: TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: const Text(
            'هل أنت متأكد من مسح جميع المسودات المعلقة؟',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('إلغاء',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                context.read<AdminBookingDraftsCubit>().clearAllDrafts();
              },
              child: const Text(
                'مسح الكل',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} د';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} س';
    } else {
      return 'منذ ${diff.inDays} ي';
    }
  }
}
