import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/domain/technician/entities/smart_schedule_entry.dart';
import 'package:shared/domain/technician/entities/technician_pool_status.dart';
import 'package:shared/presentation/dialogs/dialog_helper.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubit/smart_schedule_cubit.dart';
import '../cubit/smart_schedule_state.dart';

class SmartSchedulePage extends StatelessWidget {
  const SmartSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeColor = context.themeColor;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            l10n.smart_schedule_title,
            style: const TextStyle(
              color: Color(0xFF0D327D),
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontFamily: 'Cairo',
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0D327D),
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFF0D327D),
                size: 23,
              ),
              tooltip: 'دليل حالات التقويم',
              onPressed: () => _showCalendarGuideModal(context),
            ),
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF0D327D),
                size: 24,
              ),
              onPressed: () {
                // Notifications action
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: BlocBuilder<SmartScheduleCubit, SmartScheduleState>(
          builder: (context, state) {
            if (state is SmartScheduleLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0D327D),
                ),
              );
            }

            if (state is SmartScheduleError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 64,
                        color: themeColor.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: themeColor.textPrimary,
                          fontFamily: 'Cairo',
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          final techId =
                              GetIt.instance<SupabaseClient>()
                                  .auth
                                  .currentUser
                                  ?.id ??
                              '';
                          context.read<SmartScheduleCubit>().loadSchedule(techId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D327D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.general_retry,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is SmartScheduleLoaded) {
              final currentSelectedEntry = _resolveEntryForDate(
                state.schedule,
                state.selectedDate,
              );

              return RefreshIndicator(
                onRefresh: () async {
                  final techId =
                      GetIt.instance<SupabaseClient>().auth.currentUser?.id ??
                      '';
                  await context.read<SmartScheduleCubit>().loadSchedule(
                        techId,
                        month: state.currentMonth,
                      );
                },
                color: const Color(0xFF0D327D),
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // 1. Month Navigation Header & Stats
                      _MonthSelectorHeader(
                        currentMonth: state.currentMonth,
                        schedule: state.schedule,
                        onPrevMonth: () {
                          final techId =
                              GetIt.instance<SupabaseClient>()
                                  .auth
                                  .currentUser
                                  ?.id ??
                              '';
                          context
                              .read<SmartScheduleCubit>()
                              .changeMonth(techId, -1);
                        },
                        onNextMonth: () {
                          final techId =
                              GetIt.instance<SupabaseClient>()
                                  .auth
                                  .currentUser
                                  ?.id ??
                              '';
                          context
                              .read<SmartScheduleCubit>()
                              .changeMonth(techId, 1);
                        },
                      ),
                      const SizedBox(height: 14),

                      // 2. Calendar Card Container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 14,
                        ),
                        child: Column(
                          children: [
                            // Weekdays Row (أ، إ، ث، أ، خ، ج، س)
                            const _WeekDaysHeader(),
                            const SizedBox(height: 8),

                            // Calendar Grid of Compact All-in-One Day Nodes
                            _MonthCalendarGrid(
                              currentMonth: state.currentMonth,
                              selectedDate: state.selectedDate,
                              schedule: state.schedule,
                              onSelectDate: (date) {
                                final techId =
                                    GetIt.instance<SupabaseClient>()
                                        .auth
                                        .currentUser
                                        ?.id ??
                                    '';
                                context
                                    .read<SmartScheduleCubit>()
                                    .selectDate(techId, date);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Status Legend Bar (ممتلئ - متاح جزئياً - فاضي - إجازة / مغلق)
                      _ScheduleStatusLegend(
                        onOpenGuide: () => _showCalendarGuideModal(context),
                      ),
                      const SizedBox(height: 18),

                      // 4. Integrated Selected Day & Inline Capacity Controls Card
                      _IntegratedDayManagementCard(
                        selectedDate: state.selectedDate,
                        entry: currentSelectedEntry,
                        pools: state.poolBreakdown ?? [],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  static SmartScheduleEntry _resolveEntryForDate(
    List<SmartScheduleEntry> schedule,
    DateTime date,
  ) {
    for (final e in schedule) {
      if (e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day) {
        return e;
      }
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final bool isPast = date.isBefore(todayStart);

    return SmartScheduleEntry(
      date: date,
      status: isPast ? 'past' : 'available',
      utilization: 0.0,
      bookingsCount: 0,
      capacity: isPast ? 0 : 5,
      riskScore: 0.0,
      forceMultiplier: 1.0,
      suggestion: '',
      isOverride: false,
    );
  }

  void _showCalendarGuideModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CalendarStatesGuideModal(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 1. Month Selector Header
// ═══════════════════════════════════════════════════════════════════════
class _MonthSelectorHeader extends StatelessWidget {
  final DateTime currentMonth;
  final List<SmartScheduleEntry> schedule;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const _MonthSelectorHeader({
    required this.currentMonth,
    required this.schedule,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final monthYearTitle = DateFormat('MMMM yyyy', locale).format(currentMonth);

    int totalMonthBookings = 0;

    for (final entry in schedule) {
      if (entry.date.year == currentMonth.year &&
          entry.date.month == currentMonth.month) {
        totalMonthBookings += entry.bookingsCount;
      }
    }

    final subtitle = '$totalMonthBookings طلب خلال الشهر';

    final now = DateTime.now();
    final minMonth = DateTime(now.year, now.month - 1, 1);
    final maxMonth = DateTime(now.year, now.month + 1, 1);

    final currentMonthDate = DateTime(currentMonth.year, currentMonth.month, 1);
    final bool canGoPrev = currentMonthDate.isAfter(minMonth);
    final bool canGoNext = currentMonthDate.isBefore(maxMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: canGoPrev ? onPrevMonth : null,
          icon: Icon(
            Icons.chevron_left_rounded,
            size: 32,
            color: canGoPrev ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
          ),
          splashRadius: 24,
        ),
        Expanded(
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  monthYearTitle,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D327D),
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: canGoNext ? onNextMonth : null,
          icon: Icon(
            Icons.chevron_right_rounded,
            size: 32,
            color: canGoNext ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
          ),
          splashRadius: 24,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 2. Weekdays Header Row (أحد، إثنين، ثلاثاء، أربعاء، خميس، جمعة، سبت)
// ═══════════════════════════════════════════════════════════════════════
class _WeekDaysHeader extends StatelessWidget {
  const _WeekDaysHeader();

  @override
  Widget build(BuildContext context) {
    final days = ['أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((day) {
        return Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                day,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B), // Darker, bolder, clearer
                  height: 1.0,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 3. Month Calendar Grid (Compact & Spaced)
// ═══════════════════════════════════════════════════════════════════════
class _MonthCalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final List<SmartScheduleEntry> schedule;
  final ValueChanged<DateTime> onSelectDate;

  const _MonthCalendarGrid({
    required this.currentMonth,
    required this.selectedDate,
    required this.schedule,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    final startingOffset = firstDayOfMonth.weekday % 7;
    final totalCells = startingOffset + daysInMonth;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 3,
        mainAxisSpacing: 6,
        mainAxisExtent: 46,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < startingOffset) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - startingOffset + 1;
        final cellDate = DateTime(
          currentMonth.year,
          currentMonth.month,
          dayNumber,
        );

        final isSelected = cellDate.year == selectedDate.year &&
            cellDate.month == selectedDate.month &&
            cellDate.day == selectedDate.day;

        SmartScheduleEntry? matchedEntry;
        for (final e in schedule) {
          if (e.date.year == cellDate.year &&
              e.date.month == cellDate.month &&
              e.date.day == cellDate.day) {
            matchedEntry = e;
            break;
          }
        }

        final entry = matchedEntry ??
            SmartSchedulePage._resolveEntryForDate(schedule, cellDate);

        return _CalendarDayCell(
          dayNumber: dayNumber,
          date: cellDate,
          entry: entry,
          isSelected: isSelected,
          onTap: () => onSelectDate(cellDate),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 4. Single-Ring Progress Painter
// ═══════════════════════════════════════════════════════════════════════
class _SingleRingProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _SingleRingProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 2.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SingleRingProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 5. Calendar Day Cell Widget
// ═══════════════════════════════════════════════════════════════════════
class _CalendarDayCell extends StatelessWidget {
  final int dayNumber;
  final DateTime date;
  final SmartScheduleEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.dayNumber,
    required this.date,
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final bool isPast = date.isBefore(todayStart);

    final bool isHoliday = entry.isOverride &&
        (entry.status.toLowerCase() == 'holiday' ||
            entry.status.toLowerCase() == 'vacation' ||
            entry.status.toLowerCase() == 'blocked' ||
            entry.status.toLowerCase() == 'closed' ||
            entry.capacity == 0);

    final int displayCapacity = entry.capacity > 0 ? entry.capacity : 5;
    final int displayBookings = entry.bookingsCount;

    final bool isFull = !isHoliday && displayCapacity > 0 && displayBookings >= displayCapacity;
    final bool isPartial = !isHoliday && displayBookings > 0 && !isFull;
    final bool isEmpty = !isHoliday && displayBookings == 0;

    String subLabel;
    Color subLabelColor;

    if (isPast) {
      subLabel = '$displayBookings/$displayCapacity';
      subLabelColor = const Color(0xFF94A3B8);
    } else if (isHoliday) {
      subLabel = 'إجازة';
      subLabelColor = const Color(0xFF16A34A);
    } else if (isFull) {
      subLabel = '$displayBookings/$displayCapacity';
      subLabelColor = const Color(0xFF0284C7);
    } else if (isPartial) {
      subLabel = '$displayBookings/$displayCapacity';
      subLabelColor = const Color(0xFF0284C7);
    } else {
      subLabel = '$displayBookings/$displayCapacity';
      subLabelColor = const Color(0xFF94A3B8);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: _buildAllInOneCircle(
          isPast: isPast,
          isSelected: isSelected,
          isHoliday: isHoliday,
          isFull: isFull,
          isPartial: isPartial,
          isEmpty: isEmpty,
          subLabel: subLabel,
          subLabelColor: subLabelColor,
          displayBookings: displayBookings,
          displayCapacity: displayCapacity,
        ),
      ),
    );
  }

  Widget _buildAllInOneCircle({
    required bool isPast,
    required bool isSelected,
    required bool isHoliday,
    required bool isFull,
    required bool isPartial,
    required bool isEmpty,
    required String subLabel,
    required Color subLabelColor,
    required int displayBookings,
    required int displayCapacity,
  }) {
    if (isSelected) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF0284C7),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.35),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$dayNumber',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subLabel,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    if (isPast) {
      return Opacity(
        opacity: 0.35,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$dayNumber',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subLabel,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isHoliday) {
      return Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$dayNumber',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
                height: 1.0,
              ),
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.spa_rounded, size: 8, color: Color(0xFF16A34A)),
                SizedBox(width: 1),
                Text(
                  'إجازة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (isFull) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF0284C7),
            width: 2.8,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$dayNumber',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                height: 1.0,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subLabel,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: subLabelColor,
                height: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    if (isPartial) {
      final double progress = (displayBookings / displayCapacity).clamp(0.0, 1.0);
      return SizedBox(
        width: 44,
        height: 44,
        child: CustomPaint(
          painter: _SingleRingProgressPainter(
            progress: progress,
            trackColor: const Color(0xFFE2E8F0),
            progressColor: const Color(0xFF0284C7),
            strokeWidth: 2.8,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$dayNumber',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subLabel,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: subLabelColor,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 2.5,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$dayNumber',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subLabel,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: subLabelColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 6. Status Legend Row
// ═══════════════════════════════════════════════════════════════════════
class _ScheduleStatusLegend extends StatelessWidget {
  final VoidCallback onOpenGuide;

  const _ScheduleStatusLegend({
    required this.onOpenGuide,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpenGuide,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 6,
          children: [
            _buildRingDotItem(const Color(0xFF0284C7), 'ممتلئ'),
            _buildPartialArcDotItem('متاح جزئياً'),
            _buildRingDotItem(const Color(0xFFCBD5E1), 'فاضي'),
            _buildIconItem(
              const Icon(
                Icons.spa_rounded,
                size: 13,
                color: Color(0xFF16A34A),
              ),
              'إجازة / مغلق',
              const Color(0xFF16A34A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingDotItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildPartialArcDotItem(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 9,
          height: 9,
          child: CustomPaint(
            painter: const _SingleRingProgressPainter(
              progress: 0.6,
              trackColor: Color(0xFFCBD5E1),
              progressColor: Color(0xFF0284C7),
              strokeWidth: 2.2,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildIconItem(Widget icon, String label, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 7. Integrated Selected Day & Inline Capacity Controls Card (دمج التحكم في نفس الشاشة)
// ═══════════════════════════════════════════════════════════════════════
class _IntegratedDayManagementCard extends StatelessWidget {
  final DateTime selectedDate;
  final SmartScheduleEntry entry;
  final List<TechnicianPoolStatus> pools;

  const _IntegratedDayManagementCard({
    required this.selectedDate,
    required this.entry,
    required this.pools,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SmartScheduleCubit>();
    final techId = GetIt.instance<SupabaseClient>().auth.currentUser?.id ?? '';
    final locale = Localizations.localeOf(context).languageCode;
    final formattedDate = DateFormat('EEEE، d MMMM', locale).format(selectedDate);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final bool isPast = selectedDate.isBefore(todayStart);

    final int effectiveBookings = pools.isNotEmpty
        ? pools.map((p) => p.currentLoad).fold<int>(0, (a, b) => a + b)
        : entry.bookingsCount;

    final int effectiveCapacity = pools.isNotEmpty
        ? pools.map((p) => p.effectiveCapacity).fold<int>(0, (a, b) => a + b)
        : entry.capacity;

    final bool isAllPoolsBlocked = pools.isNotEmpty && pools.every((p) => p.isBlocked);
    final bool hasExplicitBlock = entry.isOverride &&
        (entry.status.toLowerCase() == 'holiday' ||
            entry.status.toLowerCase() == 'vacation' ||
            entry.status.toLowerCase() == 'blocked' ||
            entry.status.toLowerCase() == 'closed' ||
            entry.capacity == 0);
    final bool isHoliday = isAllPoolsBlocked || hasExplicitBlock;

    final bool isFull = !isHoliday && effectiveCapacity > 0 && effectiveBookings >= effectiveCapacity;
    final bool isPartial = !isHoliday && effectiveBookings > 0 && !isFull;
    final bool isEmpty = !isHoliday && effectiveBookings == 0;

    String headerTagText;
    Color headerTagBg;
    Color headerTagTextColor;

    if (isPast) {
      headerTagText = 'يوم سابق (أرشيف)';
      headerTagBg = const Color(0xFFF1F5F9);
      headerTagTextColor = const Color(0xFF64748B);
    } else if (isHoliday) {
      headerTagText = 'إجازة / مغلق 🍃';
      headerTagBg = const Color(0xFFDCFCE7);
      headerTagTextColor = const Color(0xFF16A34A);
    } else if (isFull) {
      headerTagText = 'ممتلئ بالحجوزات';
      headerTagBg = const Color(0xFFE0F2FE);
      headerTagTextColor = const Color(0xFF0284C7);
    } else if (isPartial) {
      headerTagText = 'متاح جزئياً ($effectiveBookings/$effectiveCapacity)';
      headerTagBg = const Color(0xFFE0F2FE);
      headerTagTextColor = const Color(0xFF0284C7);
    } else if (isEmpty) {
      headerTagText = 'متاح بالكامل (0/$effectiveCapacity)';
      headerTagBg = const Color(0xFFE0F2FE);
      headerTagTextColor = const Color(0xFF0284C7);
    } else {
      headerTagText = 'متاح ($effectiveBookings/$effectiveCapacity)';
      headerTagBg = const Color(0xFFE0F2FE);
      headerTagTextColor = const Color(0xFF0284C7);
    }

    String subtitleText;
    if (isPast) {
      subtitleText = 'الطلبات المسجلة سابقاً: $effectiveBookings طلبات';
    } else if (isHoliday) {
      subtitleText = 'يوم عطلة / إجازة (السعة المتاحة: 0 طلب)';
    } else {
      subtitleText = 'إجمالي الطلبات: $effectiveBookings · الطاقة الاستيعابية: $effectiveCapacity طلب';
    }

    return Container(
      width: double.infinity,
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
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Date Title + Status Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: headerTagBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  headerTagText,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: headerTagTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Subtitle
          Text(
            subtitleText,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Day-Off / Work Inline Quick Toggle Action
          if (!isPast) ...[
            _buildDayOffActionRow(context, cubit, pools, techId, isHoliday),
            const SizedBox(height: 16),
          ],

          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // 3. Section Title: Capacity Pools & Interactive Slot Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'خزائن العمل والشيفتات اليومية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D327D),
                ),
              ),
              if (!isPast && pools.isNotEmpty)
                Text(
                  'انقر على الخانة للتحكم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Pools list with interactive slots
          if (pools.isNotEmpty)
            ...pools.map((pool) => _buildPoolItemWithSlots(
                  context,
                  cubit: cubit,
                  pool: pool,
                  techId: techId,
                  isDayHoliday: isHoliday,
                  isDayPast: isPast,
                ))
          else
            _buildEmptyPoolsPlaceholder(isPast: isPast, isHoliday: isHoliday),
        ],
      ),
    );
  }

  Widget _buildDayOffActionRow(
    BuildContext context,
    SmartScheduleCubit cubit,
    List<TechnicianPoolStatus> pools,
    String techId,
    bool isHoliday,
  ) {
    if (isHoliday) {
      // Button to unblock / cancel holiday and open day
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {
            _handleBulkUpdate(
              context,
              cubit,
              pools,
              techId,
              action: 'open_all',
            );
          },
          icon: const Icon(Icons.flash_on_rounded, size: 20),
          label: const Text(
            'إلغاء الإجازة وتفعيل اليوم للعمل ⚡',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    // Buttons for Active Day: Take Day Off + Quick Bulk Actions
    return Row(
      children: [
        // Take Day Off Button
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                _handleBulkUpdate(
                  context,
                  cubit,
                  pools,
                  techId,
                  action: 'close_all',
                );
              },
              icon: const Icon(Icons.spa_rounded, size: 18, color: Color(0xFFDC2626)),
              label: const Text(
                'أخذ إجازة اليوم 🌴',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Quick Close Remaining Capacity
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: () {
                _handleBulkUpdate(
                  context,
                  cubit,
                  pools,
                  techId,
                  action: 'close_remaining',
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF8FAFC),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'غلق المتبقي',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPoolItemWithSlots(
    BuildContext context, {
    required SmartScheduleCubit cubit,
    required TechnicianPoolStatus pool,
    required String techId,
    required bool isDayHoliday,
    required bool isDayPast,
  }) {
    final effectiveCap = pool.effectiveCapacity;
    final int availableCount = effectiveCap - pool.currentLoad;
    final bool isPoolBlocked = pool.isBlocked || isDayHoliday;
    final List<String> mask =
        pool.slotMask?.split(',') ?? List.filled(pool.maxCapacity, '1');

    String statusBadgeText;
    Color statusBadgeBg;
    Color statusBadgeTextColor;

    if (isDayPast) {
      statusBadgeText = 'سابق (${pool.currentLoad})';
      statusBadgeBg = const Color(0xFFF1F5F9);
      statusBadgeTextColor = const Color(0xFF64748B);
    } else if (isPoolBlocked) {
      statusBadgeText = 'إجازة / مغلق (0)';
      statusBadgeBg = const Color(0xFFDCFCE7);
      statusBadgeTextColor = const Color(0xFF16A34A);
    } else if (availableCount <= 0) {
      statusBadgeText = 'ممتلئ (${pool.currentLoad}/$effectiveCap)';
      statusBadgeBg = const Color(0xFFDCFCE7);
      statusBadgeTextColor = const Color(0xFF16A34A);
    } else {
      statusBadgeText = '$availableCount متاح من ${pool.maxCapacity}';
      statusBadgeBg = const Color(0xFFE0F2FE);
      statusBadgeTextColor = const Color(0xFF0284C7);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper Row: Title, Service Tag, Badge, Settings Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pool.title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (pool.services != null && pool.services!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          pool.services!.take(2).join(' • '),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBadgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusBadgeText,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusBadgeTextColor,
                  ),
                ),
              ),
              if (!isDayPast)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                  tooltip: 'إعدادات الخزانة',
                  onPressed: () => _showPoolSettingsDialog(context, cubit, pool, techId),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Slots Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(pool.maxCapacity, (index) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: _buildSlotBox(
                    context,
                    cubit: cubit,
                    pool: pool,
                    index: index,
                    mask: mask,
                    isPoolBlocked: isPoolBlocked,
                    isDayPast: isDayPast,
                    techId: techId,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotBox(
    BuildContext context, {
    required SmartScheduleCubit cubit,
    required TechnicianPoolStatus pool,
    required int index,
    required List<String> mask,
    required bool isPoolBlocked,
    required bool isDayPast,
    required String techId,
  }) {
    final bool isBooked = index < pool.currentLoad;
    final bool isAvailable = !isPoolBlocked &&
        !isBooked &&
        (index < mask.length && mask[index] == '1');

    Gradient gradient;
    String label;
    IconData icon;

    if (isBooked) {
      gradient = const LinearGradient(
        colors: [Color(0xFF0D327D), Color(0xFF0284C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      label = 'محجوز';
      icon = Icons.person_rounded;
    } else if (isAvailable) {
      gradient = const LinearGradient(
        colors: [Color(0xFF15803D), Color(0xFF22C55E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      label = 'متاح';
      icon = Icons.check_circle_outline_rounded;
    } else {
      gradient = const LinearGradient(
        colors: [Color(0xFFB91C1C), Color(0xFFEF4444)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      label = 'مغلق';
      icon = Icons.block_rounded;
    }

    return GestureDetector(
      onTap: isDayPast
          ? null
          : () {
              if (isBooked) {
                _showTransferRequestDialog(
                  context,
                  cubit: cubit,
                  techId: techId,
                  poolId: pool.poolId,
                  slotIndex: index,
                );
              } else {
                _handleSlotToggle(
                  context,
                  cubit: cubit,
                  pool: pool,
                  techId: techId,
                  index: index,
                  isAvailable: isAvailable,
                  mask: mask,
                );
              }
            },
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          gradient: isDayPast
              ? const LinearGradient(
                  colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                )
              : gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (!isDayPast)
              BoxShadow(
                color: (isBooked
                        ? const Color(0xFF0284C7)
                        : (isAvailable
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444)))
                    .withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDayPast ? Icons.history_rounded : icon,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSlotToggle(
    BuildContext context, {
    required SmartScheduleCubit cubit,
    required TechnicianPoolStatus pool,
    required String techId,
    required int index,
    required bool isAvailable,
    required List<String> mask,
  }) {
    DialogHelper.showConfirmation(
      context,
      title: isAvailable ? 'غلق الخانة' : 'فتح الخانة',
      desc: isAvailable
          ? 'هل ترغب في غلق هذه الخانة ومنع استقبال طلبات جديدة فيها؟'
          : 'هل ترغب في فتح هذه الخانة لاستقبال الطلبات؟',
      onConfirm: () {
        final List<String> newMask = List.from(mask);
        newMask[index] = isAvailable ? '0' : '1';
        final int newCap = newMask.where((e) => e == '1').length;

        cubit.updatePoolCapacity(
          technicianId: techId,
          poolId: pool.poolId,
          date: selectedDate,
          newCapacity: newCap,
          slotMask: newMask.join(','),
        );
      },
    );
  }

  void _showPoolSettingsDialog(
    BuildContext context,
    SmartScheduleCubit cubit,
    TechnicianPoolStatus pool,
    String techId,
  ) {
    final List<String> initialMask =
        pool.slotMask?.split(',') ?? List.filled(pool.maxCapacity, '1');
    List<String> draftMask = List.from(initialMask);

    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
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
                  Expanded(
                    child: Text(
                      'شيفتات ${pool.title}',
                      style: const TextStyle(
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
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                draftMask = List.filled(pool.maxCapacity, '1');
                              });
                            },
                            icon: const Icon(Icons.done_all, color: Colors.green, size: 18),
                            label: const Text(
                              'فتح الكل',
                              style: TextStyle(fontFamily: 'Cairo', color: Colors.green, fontSize: 12),
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
                                  cubit: cubit,
                                  techId: techId,
                                  poolId: pool.poolId,
                                );
                              } else {
                                setDialogState(() {
                                  draftMask = List.filled(pool.maxCapacity, '0');
                                });
                              }
                            },
                            icon: const Icon(Icons.block, color: Colors.red, size: 18),
                            label: const Text(
                              'غلق الكل',
                              style: TextStyle(fontFamily: 'Cairo', color: Colors.red, fontSize: 12),
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
                        dense: true,
                        leading: Icon(
                          isBooked ? Icons.person : (isOpen ? Icons.check_circle : Icons.block),
                          color: isBooked
                              ? const Color(0xFF0D327D)
                              : (isOpen ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
                        ),
                        title: Text(
                          'الطلب ${index + 1}',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        ),
                        trailing: isBooked
                            ? const Text(
                                'محجوز',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontFamily: 'Cairo',
                                ),
                              )
                            : Switch(
                                value: isOpen,
                                activeThumbColor: const Color(0xFF0284C7),
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
                  child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final int newCap = draftMask.where((e) => e == '1').length;
                    cubit.updatePoolCapacity(
                      technicianId: techId,
                      poolId: pool.poolId,
                      date: selectedDate,
                      newCapacity: newCap,
                      slotMask: draftMask.join(','),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D327D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('تأكيد التعديلات', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            );
          },
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
      _showTransferRequestDialog(
        context,
        cubit: cubit,
        techId: techId,
        isFullDay: true,
      );
      return;
    }

    DialogHelper.showConfirmation(
      context,
      title: action == 'open_all' ? 'تفعيل اليوم للعمل' : 'تأكيد الإجراء',
      desc: action == 'open_all'
          ? 'هل ترغب في فتح جميع الخزائن واستقبال الطلبات لهذا اليوم؟'
          : (action == 'close_remaining'
              ? 'هل ترغب في غلق الخانات المتبقية ومنع استقبال طلبات إضافية اليوم؟'
              : 'هل أنت متأكد من أخذ إجازة وغلق اليوم بالكامل؟'),
      onConfirm: () async {
        if (pools.isEmpty) {
          final int newCap = action == 'open_all' ? 5 : 0;
          final bool isBlocked = action == 'close_all';
          await cubit.updateDailyCapacity(
            technicianId: techId,
            date: selectedDate,
            newCapacity: newCap,
            isBlocked: isBlocked,
          );
        } else {
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
                date: selectedDate,
                newCapacity: newCap,
                slotMask: newMask,
              ),
            );
          }

          await Future.wait(updates);
        }
      },
    );
  }

  void _showTransferRequestDialog(
    BuildContext context, {
    required SmartScheduleCubit cubit,
    required String techId,
    String? poolId,
    int? slotIndex,
    bool isFullDay = false,
  }) {
    DialogHelper.showConfirmation(
      context,
      title: 'محاولة نقل الحجوزات',
      desc: isFullDay
          ? 'اليوم يحتوي على حجوزات قائمة. هل تريد محاولة نقلها لفنيين آخرين وإغلاق اليوم بالكامل؟'
          : (poolId != null && slotIndex == null
              ? 'هذه الخزانة تحتوي على حجوزات. هل تريد محاولة نقلها لفني آخر وإغلاق الخزانة؟'
              : 'هذه الخانة محجوزة بالفعل. هل تريد محاولة نقل الأوردر لفني آخر وإغلاق الخانة؟'),
      okText: 'بدء المحاولة',
      cancelText: 'تراجع',
      onConfirm: () async {
        final bool success = await cubit.reassignAndBlockCapacity(
          technicianId: techId,
          date: selectedDate,
          poolId: poolId,
          slotIndex: slotIndex,
        );

        if (context.mounted) {
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
              builder: (_) => BlocProvider.value(
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
                      child: const Text('حسناً', style: TextStyle(fontFamily: 'Cairo')),
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

  Widget _buildEmptyPoolsPlaceholder({required bool isPast, required bool isHoliday}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          isHoliday
              ? 'اليوم مغلق / في إجازة (السعة: 0)'
              : 'جاري تحميل تفاصيل الخزائن لهذا اليوم...',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12.5,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 8. Interactive Calendar States Guide Modal
// ═══════════════════════════════════════════════════════════════════════
class _CalendarStatesGuideModal extends StatelessWidget {
  const _CalendarStatesGuideModal();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'دليل حالات التقويم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D327D),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildGuideCard(
                  title: 'يوم في الماضي',
                  description:
                      'تاريخ مضى (مثل: 1). يظهر بشفافية منخفضة للدلالة على أنه في الماضي وغير قابل للتعديل.',
                  badgeWidget: Opacity(
                    opacity: 0.35,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          '1',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                        Text(
                          '0/5',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 8.5,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildGuideCard(
                  title: 'يوم ممتلئ بالحجوزات',
                  description:
                      'تاريخ بحلقة زرقاء كاملة ونسبة (5/5) بالداخل، يوضح أن جميع السعات مشغولة بالكامل.',
                  badgeWidget: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0284C7),
                        width: 2.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          '15',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '5/5',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildGuideCard(
                  title: 'يوم متاح لحجوزات إضافية',
                  description:
                      'تاريخ بحلقة تقدم زرقاء جزئية ونسبة توافر (مثل 3/5) مدمجة داخل الدائرة.',
                  badgeWidget: SizedBox(
                    width: 44,
                    height: 44,
                    child: CustomPaint(
                      painter: const _SingleRingProgressPainter(
                        progress: 0.6,
                        trackColor: Color(0xFFE2E8F0),
                        progressColor: Color(0xFF0284C7),
                        strokeWidth: 2.8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            '22',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '3/5',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildGuideCard(
                  title: 'يوم إجازة / مغلق يدوياً',
                  description:
                      'خلفية رمادية فاتحة تحتوي على أيقونة ورقة شجر 🍃 وكلمة إجازة، تدل على أن الفني في عطلة.',
                  badgeWidget: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          '10',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        Text(
                          'إجازة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildGuideCard(
                  title: 'يوم فاضي وقابل للحجز',
                  description:
                      'تاريخ بحلقة رمادية هادئة ونسبة (0/5) بالداخل، يظهر توافراً كاملاً لاستقبال الطلبات.',
                  badgeWidget: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 2.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          '25',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '0/5',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildGuideCard(
                  title: 'اليوم المحدد الحالي',
                  description:
                      'دائرة زرقاء ممتلئة بتباين ناصع مع إبراز رقم اليوم ونسبة الحجز باللون الأبيض.',
                  badgeWidget: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          '8',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '0/5',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard({
    required String title,
    required String description,
    required Widget badgeWidget,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            child: Center(child: badgeWidget),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D327D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
