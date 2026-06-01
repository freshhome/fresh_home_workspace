import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/domain/technician/entities/smart_schedule_entry.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubit/smart_schedule_cubit.dart';
import '../cubit/smart_schedule_state.dart';
import 'daily_capacity_management_page.dart';

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
        backgroundColor: themeColor.background,
        appBar: AppBar(
          title: Text(
            l10n.smart_schedule_title,
            style: TextStyle(
              color: themeColor.textPrimary,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          backgroundColor: themeColor.background,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: themeColor.textPrimary),
        ),
        body: BlocBuilder<SmartScheduleCubit, SmartScheduleState>(
          builder: (context, state) {
            if (state is SmartScheduleLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SmartScheduleError) {
              print("==================🔴🔴🔴🔴🔴🔴🔴========");
              print(state.message);
              print("==================🔴🔴🔴🔴🔴🔴🔴========");

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: themeColor.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: TextStyle(color: themeColor.textPrimary),
                    ),
                    const SizedBox(height: 16),
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
                      child: Text(l10n.general_retry),
                    ),
                  ],
                ),
              );
            }

            if (state is SmartScheduleLoaded) {
              if (state.schedule.isEmpty) {
                return Center(
                  child: Text(
                    l10n.technician_orders_empty,
                    style: TextStyle(color: themeColor.secondaryText),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  final techId =
                      GetIt.instance<SupabaseClient>().auth.currentUser?.id ??
                      '';
                  await context.read<SmartScheduleCubit>().loadSchedule(techId);
                },
                color: themeColor.primary,
                backgroundColor: themeColor.cardBackground,
                child: Column(
                  children: [
                    if (state.generalRecommendation.isNotEmpty)
                      _buildRecommendationHeader(
                        context,
                        state.generalRecommendation,
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
                        itemCount: state.schedule.length,
                        itemBuilder: (context, index) =>
                            _DayScheduleCard(entry: state.schedule[index]),
                      ),
                    ),
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

  Widget _buildRecommendationHeader(
    BuildContext context,
    String recommendation,
  ) {
    final themeColor = context.themeColor;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: themeColor.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: themeColor.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: themeColor.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
                color: themeColor.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Premium Day Schedule Card
// ═══════════════════════════════════════════════════════════════════════
class _DayScheduleCard extends StatelessWidget {
  final SmartScheduleEntry entry;
  const _DayScheduleCard({required this.entry});

  bool get _isToday {
    final now = DateTime.now();
    return entry.date.year == now.year &&
        entry.date.month == now.month &&
        entry.date.day == now.day;
  }

  bool get _isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return entry.date.year == tomorrow.year &&
        entry.date.month == tomorrow.month &&
        entry.date.day == tomorrow.day;
  }

  String _resolvedStatus() {
    if (entry.bookingsCount == 0) return 'empty';
    if (entry.bookingsCount >= entry.capacity) return 'full';
    return 'available';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeColor = context.themeColor;
    final locale = Localizations.localeOf(context).languageCode;

    final dayName = DateFormat('EEEE', locale).format(entry.date); // Tuesday
    final dayNumber = DateFormat('d', locale).format(entry.date); // 23
    final monthName = DateFormat('MMMM', locale).format(entry.date); // April

    final resolvedStatus = _resolvedStatus();
    final statusColor = _statusColor(context, resolvedStatus);
    final statusLabel = _statusLabel(context, resolvedStatus, l10n);

    // Premium Decoration with Today/Tomorrow focus
    BoxDecoration cardDecoration;
    final bool isGradientCard = _isToday || _isTomorrow;

    if (_isToday) {
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
      );
    } else if (_isTomorrow) {
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
          color: statusColor.withValues(alpha: 0.12),
          width: 1.5,
        ),
      );
    }

    String displayDayName;
    if (_isToday) {
      displayDayName = l10n.technician_orders_tab_today;
    } else if (_isTomorrow) {
      displayDayName = locale == 'ar' ? 'بكرة' : 'Tomorrow';
    } else {
      displayDayName = dayName;
    }

    final Color contentColor = isGradientCard
        ? Colors.white
        : themeColor.textPrimary;

    return InkWell(
      onTap: () {
        final cubit = context.read<SmartScheduleCubit>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: cubit,
              child: DailyCapacityManagementPage(entry: entry),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: cardDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                // ── TOP SECTION: Date Box | Main Info | Status Badge ──────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildDateBox(
                      isGradientCard ? Colors.white : statusColor,
                      dayNumber,
                      monthName,
                      isInverse: isGradientCard,
                    ),

                    const SizedBox(width: 16),

                    // Day Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayDayName,
                            style: TextStyle(
                              color: contentColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Status Badge at the end
                    _StatusBadge(
                      label: statusLabel,
                      color: isGradientCard ? Colors.white : statusColor,
                      isInverse: isGradientCard,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── BOTTOM SECTION: Bookings Count & Progress ──────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.bookingsCount} / ${entry.capacity} ${l10n.nav_my_orders}',
                      style: TextStyle(
                        color: contentColor,
                        fontSize: 13,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:
                            (isGradientCard
                                    ? Colors.white
                                    : themeColor.unselectedItem)
                                .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (entry.bookingsCount / entry.capacity).clamp(
                        0.0,
                        1.0,
                      ),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isGradientCard
                                ? [
                                    Colors.white.withValues(alpha: 0.6),
                                    Colors.white,
                                  ]
                                : [
                                    statusColor.withValues(alpha: 0.7),
                                    statusColor,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isGradientCard ? Colors.white : statusColor)
                                      .withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
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

  Color _statusColor(BuildContext context, String resolved) {
    switch (resolved) {
      case 'full':
        return const Color(0xFFC62828); // Red
      case 'available':
        return const Color(0xFF2E7D32); // Green
      case 'empty':
      default:
        return const Color(0xFF0D47A1); // Deep Blue
    }
  }

  String _statusLabel(
    BuildContext context,
    String resolved,
    AppLocalizations l10n,
  ) {
    switch (resolved) {
      case 'empty':
        return l10n.schedule_status_clear; // خالٍ
      case 'available':
        return l10n.schedule_status_available; // متاح
      case 'full':
        return l10n.schedule_status_full; // مكتمل
      default:
        return resolved;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isInverse;

  const _StatusBadge({
    required this.label,
    required this.color,
    this.isInverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isInverse
            ? Colors.white.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInverse
              ? Colors.white.withValues(alpha: 0.4)
              : color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
