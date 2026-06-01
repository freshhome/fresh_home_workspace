import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fresh_home_staff/features/technician_schedule/presentation/cubit/smart_schedule_state.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/domain/technician/entities/technician_pool_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubit/smart_schedule_cubit.dart';
import 'package:intl/intl.dart';
import 'package:shared/domain/technician/entities/smart_schedule_entry.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

import 'package:shared/presentation/dialogs/dialog_helper.dart';

class DailyCapacityManagementPage extends StatefulWidget {
  final SmartScheduleEntry entry;

  const DailyCapacityManagementPage({super.key, required this.entry});

  @override
  State<DailyCapacityManagementPage> createState() =>
      _DailyCapacityManagementPageState();
}

class _DailyCapacityManagementPageState
    extends State<DailyCapacityManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final techId =
          GetIt.instance<SupabaseClient>().auth.currentUser?.id ?? '';
      context.read<SmartScheduleCubit>().loadDailyBreakdown(
        technicianId: techId,
        date: widget.entry.date,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final locale = Localizations.localeOf(context).languageCode;
    final fullDate = DateFormat(
      'EEEE، d MMMM',
      locale,
    ).format(widget.entry.date);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: themeColor.primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'إدارة قدرة الخزائن',
            style: TextStyle(
              color: Color(0xFF0D327D),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        body: BlocBuilder<SmartScheduleCubit, SmartScheduleState>(
          builder: (context, state) {
            if (state is SmartScheduleLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SmartScheduleError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Cairo',
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          final techId =
                              GetIt.instance<SupabaseClient>()
                                  .auth
                                  .currentUser
                                  ?.id ??
                              '';
                          context.read<SmartScheduleCubit>().loadDailyBreakdown(
                            technicianId: techId,
                            date: widget.entry.date,
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is SmartScheduleLoaded) {
              final pools = state.poolBreakdown ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(context, fullDate, pools),
                    const SizedBox(height: 24),

                    if (pools.isEmpty)
                      const Center(
                        child: Text(
                          'لا توجد خزائن نشطة لهذا اليوم',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),

                    ...pools.map((pool) => _buildPoolCard(context, pool)),

                    const SizedBox(
                      height: 100,
                    ), // Extra space for FAB or scrolling
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildPoolCard(BuildContext context, TechnicianPoolStatus pool) {
    final availableCount =
        (pool.overrideCapacity ?? pool.maxCapacity) - pool.currentLoad;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Upper Header with Title and Settings
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pool.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'Cairo',
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (pool.services != null && pool.services!.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: pool.services!
                              .take(3)
                              .map(
                                (service) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF0D327D,
                                    ).withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF0D327D,
                                      ).withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Text(
                                    service,
                                    style: const TextStyle(
                                      color: Color(0xFF0D327D),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        )
                      else
                        const Text(
                          'لا توجد خدمات',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontFamily: 'Cairo',
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showSettingsDialog(context, pool),
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.grey,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$availableCount متاح من ${pool.maxCapacity}',
                    style: const TextStyle(
                      color: Color(0xFF3F51B5),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 32, thickness: 1, color: Color(0xFFF5F5F5)),

          // Slots Grid
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pool.maxCapacity, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _buildSlotSquare(context, pool, index),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotSquare(
    BuildContext context,
    TechnicianPoolStatus pool,
    int index,
  ) {
    final List<String> mask =
        pool.slotMask?.split(',') ?? List.filled(pool.maxCapacity, '1');

    final bool isBooked = index < pool.currentLoad;
    // An available slot is one that is NOT booked and is marked as '1' in the mask
    final bool isAvailable =
        !pool.isBlocked &&
        !isBooked &&
        (index < mask.length && mask[index] == '1');

    Gradient gradient;
    Color shadowColor;
    String label;
    IconData icon;

    if (isBooked) {
      gradient = const LinearGradient(
        colors: [Color(0xFF0D327D), Color(0xFF22A5FC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      shadowColor = const Color(0xFF0D327D).withValues(alpha: 0.2);
      label = 'محجوز';
      icon = Icons.person_outline;
    } else if (isAvailable) {
      gradient = const LinearGradient(
        colors: [Color(0xFF1B5E20), Color(0xFF2ECC71)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      shadowColor = const Color(0xFF1B5E20).withValues(alpha: 0.2);
      label = 'متاح';
      icon = Icons.check_circle_outline;
    } else {
      gradient = const LinearGradient(
        colors: [Color(0xFFB71C1C), Color(0xFFEF5350)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      shadowColor = const Color(0xFFB71C1C).withValues(alpha: 0.2);
      label = 'مغلق';
      icon = Icons.block_flipped;
    }

    return GestureDetector(
      onTap: isBooked
          ? () => _showTransferRequestDialog(
              context,
              poolId: pool.poolId,
              slotIndex: index,
            )
          : () => _handleSlotClick(context, pool, index, isAvailable, mask),
      child: Column(
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isBooked
                  ? const Color(0xFF0D327D)
                  : (isAvailable
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFFB71C1C)),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  void _handleSlotClick(
    BuildContext context,
    TechnicianPoolStatus pool,
    int index,
    bool isAvailable,
    List<String> mask,
  ) {
    final cubit = context.read<SmartScheduleCubit>();
    final techId = GetIt.instance<SupabaseClient>().auth.currentUser?.id ?? '';

    DialogHelper.showConfirmation(
      context,
      title: isAvailable ? 'غلق الخانة' : 'فتح الخانة',
      desc: isAvailable
          ? 'هل أنت متأكد من رغبتك في غلق هذه الخانة ومنع الحجوزات؟'
          : 'هل أنت متأكد من إعادة فتح هذه الخانة لاستقبال الحجوزات؟',
      onConfirm: () {
        final List<String> newMask = List.from(mask);
        newMask[index] = isAvailable ? '0' : '1';

        final int newCap = newMask.where((e) => e == '1').length;

        cubit.updatePoolCapacity(
          technicianId: techId,
          poolId: pool.poolId,
          date: widget.entry.date,
          newCapacity: newCap,
          slotMask: newMask.join(','),
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context, TechnicianPoolStatus pool) {
    final cubit = context.read<SmartScheduleCubit>();
    final techId = GetIt.instance<SupabaseClient>().auth.currentUser?.id ?? '';
    final List<String> initialMask =
        pool.slotMask?.split(',') ?? List.filled(pool.maxCapacity, '1');
    List<String> draftMask = List.from(initialMask);

    showDialog(
      context: context,
      builder: (_) {
        return BlocProvider.value(
          value: cubit,
          child: StatefulBuilder(
            builder: (dContext, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'إمكانية الحجز اليومي',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dContext),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  draftMask = List.filled(
                                    pool.maxCapacity,
                                    '1',
                                  );
                                });
                              },
                              icon: const Icon(
                                Icons.done_all,
                                color: Colors.green,
                                size: 18,
                              ),
                              label: const Text(
                                'فتح الكل',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                if (pool.currentLoad > 0) {
                                  Navigator.pop(dContext);
                                  _showTransferRequestDialog(
                                    context,
                                    poolId: pool.poolId,
                                  );
                                } else {
                                  setDialogState(() {
                                    draftMask = List.filled(
                                      pool.maxCapacity,
                                      '0',
                                    );
                                  });
                                }
                              },
                              icon: const Icon(
                                Icons.block,
                                color: Colors.red,
                                size: 18,
                              ),
                              label: const Text(
                                'غلق الكل',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      ...List.generate(pool.maxCapacity, (index) {
                        final bool isBooked = index < pool.currentLoad;
                        final bool isOpen = draftMask[index] == '1';

                        return ListTile(
                          leading: Icon(
                            isBooked
                                ? Icons.person
                                : (isOpen ? Icons.check_circle : Icons.block),
                            color: isBooked
                                ? const Color(0xFF0D327D)
                                : (isOpen
                                      ? const Color(0xFF1B5E20)
                                      : const Color(0xFFB71C1C)),
                          ),
                          title: Text(
                            'الأوردر ${index + 1}',
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                          trailing: isBooked
                              ? const Text(
                                  'محجوزة',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontFamily: 'Cairo',
                                  ),
                                )
                              : Switch(
                                  value: isOpen,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      draftMask[index] = val ? '1' : '0';
                                    });
                                  },
                                ),
                        );
                      }),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final int newCap = draftMask
                          .where((e) => e == '1')
                          .length;
                      cubit.updatePoolCapacity(
                        technicianId: techId,
                        poolId: pool.poolId,
                        date: widget.entry.date,
                        newCapacity: newCap,
                        slotMask: draftMask.join(','),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'تأكيد التعديلات',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }



  Widget _buildHeaderCard(
    BuildContext context,
    String fullDate,
    List<TechnicianPoolStatus> pools,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D327D), Color(0xFF22A5FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D327D).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تاريخ اليوم المختار',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fullDate,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          if (pools.length > 1)
            IconButton(
              onPressed: () => _showGeneralSettingsDialog(context, pools),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  void _showGeneralSettingsDialog(
    BuildContext context,
    List<TechnicianPoolStatus> pools,
  ) {
    final cubit = context.read<SmartScheduleCubit>();
    final techId = GetIt.instance<SupabaseClient>().auth.currentUser?.id ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'إدارة اليوم بالكامل',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'اختر إجراءً ليتم تطبيقه على جميع الخزائن المتاحة اليوم',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 24),
              _ActionCard(
                title: 'فتح اليوم بالكامل',
                subtitle: 'فتح جميع الخانات لاستقبال الحجوزات',
                icon: Icons.lock_open_rounded,
                color: const Color(0xFF1B5E20),
                backgroundColor: const Color(0xFFE8F5E9),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _handleBulkUpdate(
                    context,
                    cubit,
                    pools,
                    techId,
                    action: 'open_all',
                  );
                },
              ),
              const SizedBox(height: 16),
              _ActionCard(
                title: 'غلق باقي اليوم',
                subtitle: 'منع الحجوزات الجديدة مع الإبقاء على الحالية',
                icon: Icons.hourglass_bottom_rounded,
                color: const Color(0xFF0D327D),
                backgroundColor: const Color(0xFFE3F2FD),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _handleBulkUpdate(
                    context,
                    cubit,
                    pools,
                    techId,
                    action: 'close_remaining',
                  );
                },
              ),
              const SizedBox(height: 16),
              _ActionCard(
                title: 'غلق اليوم بالكامل',
                subtitle: 'إغلاق جميع الخزائن ومنع أي حجوزات إضافية',
                icon: Icons.block_rounded,
                color: const Color(0xFFB71C1C),
                backgroundColor: const Color(0xFFFFEBEE),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _handleBulkUpdate(
                    context,
                    cubit,
                    pools,
                    techId,
                    action: 'close_all',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBulkUpdate(
    BuildContext context,
    SmartScheduleCubit cubit,
    List<TechnicianPoolStatus> pools,
    String techId, {
    required String action,
  }) {
    if (action == 'close_all' && pools.any((p) => p.currentLoad > 0)) {
      _showTransferRequestDialog(context, isFullDay: true);
      return;
    }

    DialogHelper.showConfirmation(
      context,
      title: 'تأكيد الإجراء الجماعي',
      desc: 'هل أنت متأكد من تطبيق هذا الإجراء على جميع الخزائن اليوم؟',
      onConfirm: () async {
        DialogHelper.showLoading(context);

        try {
          final List<Future> updates = [];

          for (final pool in pools) {
            String? newMask;
            int newCap = pool.maxCapacity;

            if (action == 'open_all') {
              newMask = List.filled(pool.maxCapacity, '1').join(',');
              newCap = pool.maxCapacity;
            } else if (action == 'close_remaining') {
              final List<String> currentMask = List.filled(
                pool.maxCapacity,
                '0',
              );
              for (int i = 0; i < pool.currentLoad; i++) {
                currentMask[i] = '1';
              }
              newMask = currentMask.join(',');
              newCap = pool.currentLoad;
            } else if (action == 'close_all') {
              newMask = List.filled(pool.maxCapacity, '0').join(',');
              newCap = 0;
            }

            updates.add(
              cubit.updatePoolCapacity(
                technicianId: techId,
                poolId: pool.poolId,
                date: widget.entry.date,
                newCapacity: newCap,
                slotMask: newMask,
              ),
            );
          }

          await Future.wait(updates);
        } finally {
          if (context.mounted) DialogHelper.dismissLoading(context);
        }
      },
    );
  }

  void _showTransferRequestDialog(
    BuildContext context, {
    String? poolId,
    int? slotIndex,
    bool isFullDay = false,
  }) {
    final cubit = context.read<SmartScheduleCubit>();
    final techId = GetIt.instance<SupabaseClient>().auth.currentUser?.id ?? '';

    DialogHelper.showConfirmation(
      context,
      title: 'محاولة نقل الحجوزات',
      desc: isFullDay
          ? 'اليوم يحتوي على حجوزات قائمة. هل تريد محاولة نقلها لفنيين آخرين وإغلاق اليوم بالكامل؟'
          : (poolId != null && slotIndex == null
                ? 'هذه الخزانة تحتوي على حجوزات. هل تريد محاولة نقلها وإغلاق الخزانة؟'
                : 'هذه الخانة محجوزة بالفعل. هل تريد محاولة نقل الأوردر لفني آخر وإغلاق الخانة؟'),
      okText: 'بدء المحاولة',
      cancelText: 'تراجع',
      onConfirm: () async {
        DialogHelper.showLoading(context);

        final bool success = await cubit.reassignAndBlockCapacity(
          technicianId: techId,
          date: widget.entry.date,
          poolId: poolId,
          slotIndex: slotIndex,
        );

        if (context.mounted) {
          DialogHelper.dismissLoading(context);

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'تم نقل الحجوزات بنجاح وتحديث الحالة.',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            showDialog(
              context: context,
              builder: (dContext) => BlocProvider.value(
                value: cubit,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: const Text(
                    'تعذر النقل التلقائي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    'عذراً، لم نتمكن من العثور على فني بديل متاح حالياً لنقل هذه الحجوزات.\n\nيرجى التواصل مع الإدارة لإلغاء أو إعادة جدولة الحجوزات يدوياً قبل إغلاق هذه السعة.',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'حسناً',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
