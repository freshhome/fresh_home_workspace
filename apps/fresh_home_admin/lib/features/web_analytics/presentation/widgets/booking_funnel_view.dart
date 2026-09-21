import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
        BookingFunnelEntity? funnel;
        if (state is BookingFunnelLoaded) {
          funnel = state.funnel;
        }

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
                      // 1. Horizontal Filter Cards (Today, All, Last 7 Days, Pick Date)
                      _buildFilterCards(context, state, isArabic, isDark),
                      const SizedBox(height: 20),

                      // 2. Dynamic content based on state
                      if (state is BookingFunnelLoading ||
                          state is BookingFunnelInitial)
                        _buildLoadingContent(context, isArabic)
                      else if (state is BookingFunnelError)
                        _buildErrorContent(
                            context, state.message, isArabic, isDark)
                      else if (state is BookingFunnelEmpty)
                        _buildEmptyContent(context, isArabic, isDark)
                      else if (funnel != null) ...[
                        // 3. Summary KPI Cards (5 milestones)
                        _buildKpiGrid(context, funnel, isArabic, isDark),
                        const SizedBox(height: 28),

                        // 4. Funnel Flow Visualization with Drop-offs
                        _buildFunnelProgressionSection(
                            context, funnel, isArabic, isDark),
                        const SizedBox(height: 28),

                        // 5. Drop-off Summary Table / Insights
                        _buildDropOffSummarySection(
                            context, funnel, isArabic, isDark),
                        const SizedBox(height: 36),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Horizontal Filter Cards (Today, All, Last 7 Days, Pick Date)
  // ---------------------------------------------------------------------------
  Widget _buildFilterCards(
    BuildContext context,
    BookingFunnelState state,
    bool isArabic,
    bool isDark,
  ) {
    final themeColor = context.themeColor;
    final cubit = context.read<BookingFunnelCubit>();
    final activeFilter = state.filter;
    final now = DateTime.now();

    final todayFormatted = DateFormat('d MMM', isArabic ? 'ar' : 'en').format(now);
    final customDateFormatted = state.customDate != null
        ? DateFormat('d MMM yyyy', isArabic ? 'ar' : 'en').format(state.customDate!)
        : (isArabic ? 'اختيار يوم معين' : 'Pick a Date');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // 1. اليوم (Today)
          _buildFilterCardItem(
            context: context,
            title: isArabic ? 'اليوم' : 'Today',
            subtitle: todayFormatted,
            icon: Icons.today_rounded,
            isSelected: activeFilter == FunnelDateFilter.today,
            onTap: () => cubit.applyDateFilter(FunnelDateFilter.today),
            isDark: isDark,
          ),
          const SizedBox(width: 10),

          // 2. الكل (All)
          _buildFilterCardItem(
            context: context,
            title: isArabic ? 'الكل' : 'All',
            subtitle: isArabic ? 'كافة الفترات' : 'All time',
            icon: Icons.all_inclusive_rounded,
            isSelected: activeFilter == FunnelDateFilter.all,
            onTap: () => cubit.applyDateFilter(FunnelDateFilter.all),
            isDark: isDark,
          ),
          const SizedBox(width: 10),

          // 3. آخر 7 أيام (Last 7 Days)
          _buildFilterCardItem(
            context: context,
            title: isArabic ? 'آخر 7 أيام' : 'Last 7 Days',
            subtitle: isArabic ? 'أسبوع' : 'Past week',
            icon: Icons.date_range_rounded,
            isSelected: activeFilter == FunnelDateFilter.last7Days,
            onTap: () => cubit.applyDateFilter(FunnelDateFilter.last7Days),
            isDark: isDark,
          ),
          const SizedBox(width: 10),

          // 4. اختيار يوم معين (Pick Specific Day)
          _buildFilterCardItem(
            context: context,
            title: customDateFormatted,
            subtitle: state.customDate != null
                ? (isArabic ? 'اضغط للتغيير' : 'Tap to change')
                : (isArabic ? 'تحديد تاريخ' : 'Select date'),
            icon: Icons.calendar_month_rounded,
            isSelected: activeFilter == FunnelDateFilter.custom,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: state.customDate ?? DateTime.now(),
                firstDate: DateTime(2023, 1, 1),
                lastDate: DateTime.now(),
                locale: isArabic ? const Locale('ar', 'SA') : const Locale('en', 'US'),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: themeColor.primary,
                        onPrimary: Colors.white,
                        surface: isDark ? const Color(0xFF131F3F) : Colors.white,
                        onSurface: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && context.mounted) {
                cubit.applyDateFilter(FunnelDateFilter.custom, customDate: picked);
              }
            },
            isDark: isDark,
            isCustomDate: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCardItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    bool isCustomDate = false,
  }) {
    final themeColor = context.themeColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? themeColor.primary
                : (isDark ? const Color(0xFF131F3F) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? themeColor.primary
                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: themeColor.primary.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : themeColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : themeColor.primary,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.85)
                          : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
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
                title: isArabic ? 'شاشة التفاصيل' : 'Details Screen',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${isArabic ? 'معدل الإتمام: ' : 'Conversion: '}${funnel.summary.overallConversionRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
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
      'شاشة التفاصيل',
      'حساب السعر',
      'اختيار الموعد',
      'تأكيد العنوان والبيانات',
      'إتمام الحجز بنجاح',
    ];

    final stepTitlesEn = [
      'Details Screen',
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
          ? 'شاشة التفاصيل ← حساب السعر'
          : 'Details Screen → Price Calculated';
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
  // Loading, Empty, and Error States (Embedded under persistent filter bar)
  // ---------------------------------------------------------------------------
  Widget _buildLoadingContent(BuildContext context, bool isArabic) {
    final themeColor = context.themeColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
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
      ),
    );
  }

  Widget _buildEmptyContent(BuildContext context, bool isArabic, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(28),
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
                size: 48,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 12),
              Text(
                isArabic
                    ? 'لا توجد بيانات لمسار الحجز في هذه الفترة'
                    : 'No booking funnel data in this period',
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
                    ? 'لم يتم تسجيل خطوات حجز في النطاق الزمني المحدد. يمكنك تجربة "الكل" أو اختيار يوم آخر.'
                    : 'No booking steps recorded in the selected timeframe. Try selecting "All" or another date.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.themeColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context
                    .read<BookingFunnelCubit>()
                    .applyDateFilter(FunnelDateFilter.all),
                icon: const Icon(Icons.all_inclusive_rounded, size: 18),
                label: Text(
                  isArabic ? 'عرض كافة الفترات (الكل)' : 'Show All Time',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContent(
    BuildContext context,
    String message,
    bool isArabic,
    bool isDark,
  ) {
    final themeColor = context.themeColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131F3F) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isArabic
                    ? 'تعذر تحميل بيانات مسار الحجز'
                    : 'Failed to load booking funnel data',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: themeColor.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () =>
                    context.read<BookingFunnelCubit>().loadFunnelStats(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
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
      ),
    );
  }
}
