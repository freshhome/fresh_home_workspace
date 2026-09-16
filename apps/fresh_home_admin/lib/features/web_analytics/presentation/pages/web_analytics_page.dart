import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared/shared.dart';
import '../../domain/entities/page_stat_entity.dart';
import '../../domain/entities/web_analytics_entity.dart';
import '../cubit/web_analytics_cubit.dart';
import '../cubit/web_analytics_state.dart';

class WebAnalyticsPage extends StatefulWidget {
  const WebAnalyticsPage({super.key});

  @override
  State<WebAnalyticsPage> createState() => _WebAnalyticsPageState();
}

class _WebAnalyticsPageState extends State<WebAnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 16.0 : 28.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070F26) : const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            fontFamily: 'Cairo',
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF0B1739) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<WebAnalyticsCubit>().loadTodayAnalytics(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<WebAnalyticsCubit, WebAnalyticsState>(
        builder: (context, state) {
          if (state is WebAnalyticsLoading || state is WebAnalyticsInitial) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: themeColor.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'جاري جلب إحصائيات زوار اليوم...',
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

          if (state is WebAnalyticsError) {
            return _buildErrorState(context, state.message);
          }

          if (state is WebAnalyticsLoaded) {
            final data = state.analytics;
            return RefreshIndicator(
              color: themeColor.primary,
              backgroundColor: themeColor.cardBackground,
              onRefresh: () =>
                  context.read<WebAnalyticsCubit>().loadTodayAnalytics(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 20.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Live status bar & Timestamp
                          _buildLiveStatusHeader(context),
                          const SizedBox(height: 20),

                          // 2. Real KPI Cards (Users, Views, Views/User)
                          _buildKpiSection(context, data),
                          const SizedBox(height: 28),

                          // 3. Top Visited Pages List (Real data driven)
                          _buildTopPagesSection(context, data),
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Live Status Header
  // ---------------------------------------------------------------------------
  Widget _buildLiveStatusHeader(BuildContext context) {
    final themeColor = context.themeColor;
    final now = DateFormat('HH:mm').format(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Live badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF0284C7),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'تقرير اليوم المباشر',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
                ),
              ),
            ],
          ),
        ),

        // Updated time
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'محدث الآن: $now بتوقيت القاهرة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: themeColor.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Real KPI Cards
  // ---------------------------------------------------------------------------
  Widget _buildKpiSection(BuildContext context, WebAnalyticsEntity data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final avgViews = data.totalUsers > 0
        ? (data.totalViews / data.totalUsers).toStringAsFixed(1)
        : '0.0';

    return Column(
      children: [
        Row(
          children: [
            // Card 1: Active Users
            Expanded(
              child: _buildKpiCard(
                context,
                isDark: isDark,
                title: 'إجمالي زوار اليوم',
                value: '${data.totalUsers}',
                unit: 'زائر',
                icon: Icons.people_alt_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBgColor: const Color(0xFF0284C7).withValues(alpha: 0.1),
                badgeText: 'نشط اليوم',
                badgeColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 14),

            // Card 2: Page Views
            Expanded(
              child: _buildKpiCard(
                context,
                isDark: isDark,
                title: 'إجمالي مشاهدات الصفحات',
                value: '${data.totalViews}',
                unit: 'مشاهدة',
                icon: Icons.visibility_rounded,
                iconColor: const Color(0xFF8B5CF6),
                iconBgColor: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                badgeText: 'مرات التصفح',
                badgeColor: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Metric Bar: Average Views per Visitor
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131F3F) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_graph_rounded,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'معدل التصفح لكل زائر:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Text(
                '$avgViews صفحة / زائر',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131F3F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Badge & Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Count & Unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Title
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Top Visited Pages Section (Real Google Analytics Data)
  // ---------------------------------------------------------------------------
  Widget _buildTopPagesSection(BuildContext context, WebAnalyticsEntity data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = context.themeColor;
    final pages = data.pages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الصفحات الأكثر زيارة اليوم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'بيانات المشاهدات الفعلية من Google Analytics 4',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: themeColor.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${pages.length} مسار',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: themeColor.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // List or Empty State
        if (pages.isEmpty)
          _buildEmptyPagesCard(context, isDark)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pages.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final page = pages[index];
              final rank = index + 1;

              // Calculate real share from totalViews
              final int sharePercent = data.totalViews > 0
                  ? ((page.views / data.totalViews) * 100).round()
                  : 0;

              return _buildPageCardItem(
                context,
                isDark: isDark,
                rank: rank,
                page: page,
                sharePercent: sharePercent,
              );
            },
          ),
      ],
    );
  }

  Widget _buildPageCardItem(
    BuildContext context, {
    required bool isDark,
    required int rank,
    required PageStatEntity page,
    required int sharePercent,
  }) {
    // Friendly Arabic title mapping from path
    String friendlyTitle = 'صفحة الموقع';
    final p = page.path.toLowerCase();
    if (p == '/' || p == '') {
      friendlyTitle = 'الرئيسية';
    } else if (p.contains('clean') || p.contains('servic')) {
      friendlyTitle = 'خدمات التنظيف والصيانة';
    } else if (p.contains('book')) {
      friendlyTitle = 'شاشة الحجز المباشر';
    } else if (p.contains('login') || p.contains('auth')) {
      friendlyTitle = 'تسجيل الدخول';
    } else if (p.contains('order')) {
      friendlyTitle = 'متابعة الطلبات';
    } else if (p.contains('profile')) {
      friendlyTitle = 'الملف الشخصي';
    } else {
      friendlyTitle = page.path;
    }

    // Rank badge colors
    Color badgeColor = const Color(0xFF94A3B8);
    if (rank == 1) {
      badgeColor = const Color(0xFF0F4C81);
    } else if (rank == 2) {
      badgeColor = const Color(0xFF3B82F6);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131F3F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank badge (#1, #2, #3...)
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Real Path
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friendlyTitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      page.path.isEmpty ? '/' : page.path,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Real Stats (Users & Views)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${page.views} مشاهدة',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${page.users} زائر ($sharePercent%)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Real proportional progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: (sharePercent / 100).clamp(0.04, 1.0),
                backgroundColor:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  rank == 1
                      ? const Color(0xFF0F4C81)
                      : (rank == 2
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF94A3B8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPagesCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131F3F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.query_stats_rounded,
            size: 40,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 10),
          Text(
            'لا توجد زيارات مسجلة اليوم حتى الآن',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'سيتم ظهور المسارات والصفحات تلقائياً بمجرد تصفح الزوار لموقع فريش هوم.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error State Widget
  // ---------------------------------------------------------------------------
  Widget _buildErrorState(BuildContext context, String message) {
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
              'تعذر تحميل بيانات التحليلات',
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
              child: Column(
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (message.contains('credentials') ||
                      message.contains('environment') ||
                      message.contains('500')) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'السبب: تأكد من إضافة مفاتيح Google Analytics في Vercel.\n(GA_PROPERTY_ID, GA_CLIENT_EMAIL, GA_PRIVATE_KEY)',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: themeColor.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
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
                  context.read<WebAnalyticsCubit>().loadTodayAnalytics(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(
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
