import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import '../../domain/entities/booking_funnel_entity.dart';
import '../cubit/booking_funnel_cubit.dart';
import '../cubit/booking_funnel_state.dart';

/// Widget displaying the 5-step Booking Funnel, Drop-off progression, and KPIs.
class BookingFunnelView extends StatelessWidget {
  const BookingFunnelView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<BookingFunnelCubit, BookingFunnelState>(
      builder: (context, state) {
        if (state is BookingFunnelLoading || state is BookingFunnelInitial) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: themeColor.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  isArabic
                      ? 'جاري جلب بيانات مسار الحجز...'
                      : 'Loading booking funnel data...',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: themeColor.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is BookingFunnelError) {
          return _buildErrorState(context, state.message, isArabic, isDark);
        }

        if (state is BookingFunnelEmpty) {
          return _buildEmptyState(context, isArabic, isDark);
        }

        if (state is BookingFunnelLoaded) {
          final funnel = state.funnel;
          return RefreshIndicator(
            color: themeColor.primary,
            backgroundColor: themeColor.cardBackground,
            onRefresh: () =>
                context.read<BookingFunnelCubit>().loadFunnelStats(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header with description & overall conversion badge
                        _buildFunnelHeader(context, funnel, isArabic, isDark),
                        const SizedBox(height: 20),

                        // 2. Summary KPI Cards (5 milestones)
                        _buildKpiGrid(context, funnel, isArabic, isDark),
                        const SizedBox(height: 28),

                        // 3. Funnel Flow Visualization with Drop-offs
                        _buildFunnelProgressionSection(
                            context, funnel, isArabic, isDark),
                        const SizedBox(height: 28),

                        // 4. Drop-off Summary Table / Insights
                        _buildDropOffSummarySection(
                            context, funnel, isArabic, isDark),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Header Section
  // ---------------------------------------------------------------------------
  Widget _buildFunnelHeader(
    BuildContext context,
    BookingFunnelEntity funnel,
    bool isArabic,
    bool isDark,
  ) {
    final themeColor = context.themeColor;
    final conversion = funnel.summary.overallConversionRate.toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131F3F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.filter_alt_rounded,
              color: themeColor.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'مسار خطوات الحجز' : 'Booking Funnel',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic
                      ? 'يمثل تدفق رحلات الحجز الفريدة (Unique Sessions) عبر الموقع خطوة بخطوة'
                      : 'Tracks unique customer booking journeys through the website step-by-step',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Overall Conversion Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isArabic ? 'معدل الإتمام الكلي' : 'Overall Conversion',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
                Text(
                  '$conversion%',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. KPI Summary Grid
  // ---------------------------------------------------------------------------
  Widget _buildKpiGrid(
    BuildContext context,
    BookingFunnelEntity funnel,
    bool isArabic,
    bool isDark,
  ) {
    // Map steps to counts
    int countS1 = 0;
    int countS2 = 0;
    int countS3 = 0;
    int countS4 = 0;
    int countS5 = 0;

    for (final step in funnel.steps) {
      switch (step.stepNumber) {
        case 1:
          countS1 = step.count;
          break;
        case 2:
          countS2 = step.count;
          break;
        case 3:
          countS3 = step.count;
          break;
        case 4:
          countS4 = step.count;
          break;
        case 5:
          countS5 = step.count;
          break;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final cardWidth = isSmall
            ? (constraints.maxWidth - 10) / 2
            : (constraints.maxWidth - 32) / 3;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildSmallKpiCard(
                title: isArabic ? 'بدء الحجز (اختيار الخدمة)' : 'Service Selected',
                value: '$countS1',
                stepNum: 1,
                icon: Icons.touch_app_rounded,
                color: const Color(0xFF0284C7),
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildSmallKpiCard(
                title: isArabic ? 'حساب السعر' : 'Price Calculated',
                value: '$countS2',
                stepNum: 2,
                icon: Icons.calculate_rounded,
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildSmallKpiCard(
                title: isArabic ? 'اختيار الموعد' : 'Schedule Selected',
                value: '$countS3',
                stepNum: 3,
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildSmallKpiCard(
                title: isArabic ? 'تأكيد العنوان' : 'Address Confirmed',
                value: '$countS4',
                stepNum: 4,
                icon: Icons.location_on_rounded,
                color: const Color(0xFFEC4899),
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildSmallKpiCard(
                title: isArabic ? 'إتمام الحجز' : 'Booking Created',
                value: '$countS5',
                stepNum: 5,
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmallKpiCard({
    required String title,
    required String value,
    required int stepNum,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131F3F) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Funnel Visualization (5 Stages with Drop-off Indicators)
  // ---------------------------------------------------------------------------
  Widget _buildFunnelProgressionSection(
    BuildContext context,
    BookingFunnelEntity funnel,
    bool isArabic,
    bool isDark,
  ) {
    final sortedSteps = [...funnel.steps]
      ..sort((a, b) => a.stepNumber.compareTo(b.stepNumber));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isArabic ? 'المسار التدريجي للتحويل' : 'Step-by-Step Conversion Flow',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              isArabic ? 'نسبة الإتمام من البداية' : 'Completion Rate from Started',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Render steps and drop-off dividers
        for (int i = 0; i < sortedSteps.length; i++) ...[
          _buildFunnelStepCard(
            context,
            step: sortedSteps[i],
            isArabic: isArabic,
            isDark: isDark,
          ),
          if (i < sortedSteps.length - 1)
            _buildTransitionDropOffWidget(
              context,
              fromStep: sortedSteps[i],
              toStep: sortedSteps[i + 1],
              isArabic: isArabic,
              isDark: isDark,
            ),
        ],
      ],
    );
  }

  Widget _buildFunnelStepCard(
    BuildContext context, {
    required BookingFunnelStepEntity step,
    required bool isArabic,
    required bool isDark,
  }) {
    // Stage colors
    final colors = [
      const Color(0xFF0284C7), // Step 1: Sky Blue
      const Color(0xFF8B5CF6), // Step 2: Violet
      const Color(0xFFF59E0B), // Step 3: Amber
      const Color(0xFFEC4899), // Step 4: Pink
      const Color(0xFF10B981), // Step 5: Emerald
    ];

    final color = colors[(step.stepNumber - 1).clamp(0, colors.length - 1)];

    final stepTitlesAr = [
      'اختيار الخدمة',
      'حساب السعر',
      'اختيار الموعد',
      'تأكيد العنوان والبيانات',
      'إتمام الحجز بنجاح',
    ];

    final stepTitlesEn = [
      'Service Selected',
      'Price Calculated',
      'Schedule Selected',
      'Address Confirmed',
      'Booking Created',
    ];

    final title = isArabic
        ? (step.stepNumber <= stepTitlesAr.length
            ? stepTitlesAr[step.stepNumber - 1]
            : step.displayNameAr)
        : (step.stepNumber <= stepTitlesEn.length
            ? stepTitlesEn[step.stepNumber - 1]
            : step.eventName);

    final completionPct = step.completionRate.clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131F3F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Step number badge
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${step.stepNumber}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Event name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      step.eventName,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              // Count & Cumulative completion percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${step.count} ${isArabic ? 'جلسة' : 'sessions'}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '${completionPct.toStringAsFixed(1)}% ${isArabic ? 'وصول' : 'reached'}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Visual Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 7,
              child: LinearProgressIndicator(
                value: (completionPct / 100.0).clamp(0.0, 1.0),
                backgroundColor:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionDropOffWidget(
    BuildContext context, {
    required BookingFunnelStepEntity fromStep,
    required BookingFunnelStepEntity toStep,
    required bool isArabic,
    required bool isDark,
  }) {
    // Drop off rate and count
    final dropCount = fromStep.dropOffCount;
    final dropRate = fromStep.dropOffRate;
    final retentionRate = fromStep.count > 0
        ? ((toStep.count / fromStep.count) * 100).clamp(0.0, 100.0)
        : 0.0;

    final isSignificantDrop = dropRate >= 30.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 20.0),
      child: Row(
        children: [
          // Vertical connector arrow
          Column(
            children: [
              Container(
                width: 2,
                height: 12,
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              ),
              Icon(
                Icons.arrow_downward_rounded,
                size: 16,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
              Container(
                width: 2,
                height: 12,
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Drop-off badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSignificantDrop
                  ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                  : const Color(0xFF64748B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSignificantDrop
                    ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                    : const Color(0xFF64748B).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_down_rounded,
                  size: 14,
                  color: isSignificantDrop
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  isArabic
                      ? 'تسرب: $dropCount جلسة (${dropRate.toStringAsFixed(1)}%)'
                      : 'Drop-off: $dropCount sessions (${dropRate.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSignificantDrop
                        ? const Color(0xFFEF4444)
                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Forward Retention Badge
          Text(
            isArabic
                ? 'استمرار: ${retentionRate.toStringAsFixed(1)}%'
                : 'Progression: ${retentionRate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Drop-Off Summary / Analysis Card
  // ---------------------------------------------------------------------------
  Widget _buildDropOffSummarySection(
    BuildContext context,
    BookingFunnelEntity funnel,
    bool isArabic,
    bool isDark,
  ) {
    final biggestStep = funnel.summary.biggestDropOffStep;
    final biggestRate = funnel.summary.biggestDropOffRate;
    final biggestCount = funnel.summary.biggestDropOffCount;

    String biggestStepTitle = isArabic ? 'غير محدد' : 'None';
    if (biggestStep == 1) {
      biggestStepTitle = isArabic
          ? 'اختيار الخدمة ← حساب السعر'
          : 'Service Selected → Price Calculated';
    } else if (biggestStep == 2) {
      biggestStepTitle = isArabic
          ? 'حساب السعر ← اختيار الموعد'
          : 'Price Calculated → Schedule Selected';
    } else if (biggestStep == 3) {
      biggestStepTitle = isArabic
          ? 'اختيار الموعد ← تأكيد العنوان'
          : 'Schedule Selected → Address Confirmed';
    } else if (biggestStep == 4) {
      biggestStepTitle = isArabic
          ? 'تأكيد العنوان ← إتمام الحجز'
          : 'Address Confirmed → Booking Created';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131F3F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                size: 20,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'تحليل نقاط التسرب (Drop-off Analysis)' : 'Drop-off Analysis',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (biggestStep != null && biggestCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic
                              ? 'أعلى نقطة تسرب للجلسات:'
                              : 'Highest drop-off transition:',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '$biggestStepTitle ($biggestCount جلسة - ${biggestRate.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            isArabic
                ? '• يتم احتساب التحويل والتسرب تلقائياً بواسطة محرك التحليلات بقاعدة البيانات (RPC).\n'
                  '• كل جلسة (Session ID) تُحتسب مرة واحدة فقط في كل مرحلة لمنع التكرار.\n'
                  '• لا يتم تخمين أسباب التراجع، بل يتم رصد الوقائع الرقمية المؤكدة بدقة.'
                : '• Calculations are strictly computed by the database aggregation engine (RPC).\n'
                  '• Each Session ID is counted once per step to prevent duplicate distortion.\n'
                  '• The dashboard reports exact progression without unverified speculation.',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              height: 1.6,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty State Widget
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context, bool isArabic, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131F3F) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.filter_alt_off_rounded,
                size: 52,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 14),
              Text(
                isArabic
                    ? 'لا توجد بيانات لمسار الحجز حتى الآن'
                    : 'No booking funnel data yet',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isArabic
                    ? 'ستظهر إحصائيات خطوات الحجز ومعدلات التحويل تلقائياً بمجرد قيام الزوار ببدء رحلة الحجز عبر الموقع.'
                    : 'Funnel progression and drop-off rates will appear automatically once customers begin booking journeys.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.themeColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () =>
                    context.read<BookingFunnelCubit>().loadFunnelStats(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  isArabic ? 'تحديث' : 'Refresh',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error State Widget
  // ---------------------------------------------------------------------------
  Widget _buildErrorState(
    BuildContext context,
    String message,
    bool isArabic,
    bool isDark,
  ) {
    final themeColor = context.themeColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic
                  ? 'تعذر تحميل بيانات مسار الحجز'
                  : 'Failed to load booking funnel data',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: themeColor.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxWidth: 550),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: themeColor.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  context.read<BookingFunnelCubit>().loadFunnelStats(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                isArabic ? 'إعادة المحاولة' : 'Retry',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
