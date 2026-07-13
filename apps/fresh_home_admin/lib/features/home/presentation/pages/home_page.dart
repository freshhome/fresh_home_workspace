import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final l10n = context.l10n;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive grid configurations based on viewport width
    final int crossAxisCount = screenWidth < 600
        ? 2
        : screenWidth < 960
            ? 3
            : 4;

    final double childAspectRatio = screenWidth < 600
        ? 2.5
        : screenWidth < 960
            ? 2.3
            : 2.2;

    final double padding = screenWidth < 600 ? 16.0 : 32.0;

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        title: Text(
          l10n.admin_dashboard_title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: themeColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Header Section
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.admin_welcome_title,
                              style: TextStyle(
                                fontSize: screenWidth < 600 ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                color: themeColor.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.admin_welcome_subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: themeColor.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (screenWidth >= 600)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: themeColor.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings_rounded,
                                color: themeColor.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.settings_section_admin,
                                style: TextStyle(
                                  color: themeColor.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 📊 KPI Analytics Grid Section
                  _buildKpiSection(context, screenWidth),
                  const SizedBox(height: 32),

                  // 🧭 Responsive Feature Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                    children: [
                      // Booking Dispatch Board
                      _buildFeatureCard(
                        context,
                        title: l10n.admin_nav_dispatch,
                        icon: Icons.edit_calendar_rounded,
                        color: Colors.purple,
                        onTap: () => GoRouter.of(context).pushNamed('admin_dashboard'),
                      ),
                      // Services Management
                      _buildFeatureCard(
                        context,
                        title: l10n.admin_nav_services,
                        icon: Icons.design_services_rounded,
                        color: themeColor.primary,
                        onTap: () => GoRouter.of(context).pushNamed(AppRoutes.servicesManagement),
                      ),
                      // Pricing Governance
                      _buildFeatureCard(
                        context,
                        title: l10n.admin_nav_pricing,
                        icon: Icons.gavel_rounded,
                        color: Colors.amber.shade800,
                        onTap: () => GoRouter.of(context).push('/pricing-governance'),
                      ),
                      // Bookings Management
                      _buildFeatureCard(
                        context,
                        title: l10n.admin_nav_bookings,
                        icon: Icons.calendar_month_rounded,
                        color: Colors.blueAccent,
                        onTap: () => GoRouter.of(context).push('/admin/bookings'),
                      ),
                      // Users Access Management
                      _buildFeatureCard(
                        context,
                        title: l10n.admin_nav_users,
                        icon: Icons.people_alt_rounded,
                        color: Colors.orange,
                        onTap: () => GoRouter.of(context).pushNamed(AppRoutes.adminUserManagement),
                      ),
                      // Financial Center
                      _buildFeatureCard(
                        context,
                        title: l10n.admin_nav_finance,
                        icon: Icons.account_balance_rounded,
                        color: Colors.green,
                        onTap: () => GoRouter.of(context).push('/admin/finance'),
                      ),
                      // Reviews Moderation
                      _buildFeatureCard(
                        context,
                        title: l10n.admin_nav_reviews,
                        icon: Icons.rate_review_rounded,
                        color: const Color(0xFF1E3A8A),
                        onTap: () => GoRouter.of(context).push('/admin-reviews'),
                      ),
                      // Cloud Sync Monitor (Supabase)
                      _buildFeatureCard(
                        context,
                        title: l10n.admin_nav_supabase,
                        icon: Icons.cloud_done_rounded,
                        color: Colors.teal,
                        onTap: () => GoRouter.of(context).pushNamed(AppRoutes.adminSupabaseServices),
                      ),
                      // WhatsApp Configuration Settings
                      _buildFeatureCard(
                        context,
                        title: 'إعدادات الواتساب',
                        icon: Icons.chat_bubble_outline_rounded,
                        color: Colors.green.shade600,
                        onTap: () => GoRouter.of(context).push('/admin/whatsapp-settings'),
                      ),
                      // Motion Review Playground
                      _buildFeatureCard(
                        context,
                        title: 'مراجعة حركات النظام',
                        icon: Icons.motion_photos_on_rounded,
                        color: Colors.pink.shade700,
                        onTap: () => GoRouter.of(context).push('/admin/motion-review'),
                      ),
                      // Dispatch Algorithm Lab
                      _buildFeatureCard(
                        context,
                        title: 'مختبر خوارزميات التوزيع',
                        icon: Icons.science_outlined,
                        color: Colors.deepPurple,
                        onTap: () => GoRouter.of(context).push('/admin/dispatch-lab'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSection(BuildContext context, double screenWidth) {
    final cards = [
      _buildKpiCard(
        context,
        title: 'حجوزات اليوم',
        value: '24 حجزاً',
        icon: Icons.trending_up_rounded,
        color: Colors.green,
      ),
      _buildKpiCard(
        context,
        title: 'الطلبات المعلقة',
        value: '5 طلبات',
        icon: Icons.pending_actions_rounded,
        color: Colors.orange,
      ),
      _buildKpiCard(
        context,
        title: 'نسبة الإشغال',
        value: '82%',
        icon: Icons.pie_chart_rounded,
        color: Colors.blue,
      ),
    ];

    if (screenWidth < 600) {
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: c,
        )).toList(),
      );
    }

    return Row(
      children: cards.map((c) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: c,
        ),
      )).toList(),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final themeColor = context.themeColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeColor.unselectedItem.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeColor.secondaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    color: themeColor.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final themeColor = context.themeColor;

    return Container(
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeColor.unselectedItem.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: themeColor.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: themeColor.unselectedItem.withValues(alpha: 0.2),
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
