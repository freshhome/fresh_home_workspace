import 'package:flutter/material.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/widget/my_custom_button.dart';
import 'package:go_router/go_router.dart';
import '../../../technician_orders/presentation/routes/technician_orders_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final textTheme = Theme.of(context).extension<AppTextThemeExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: themeColor.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFE2E8F0),
                        backgroundImage: AssetImage(
                          'packages/shared/assets/core/images/Frame 1000006212.png',
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C566),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.tech_dashboard_title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.textOverline.copyWith(
                            color: themeColor.secondaryText,
                            letterSpacing: 0.5,
                            fontSize: 10,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          l10n.tech_greeting_morning,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.textBodySecondary.copyWith(
                            color: themeColor.secondaryText,
                            fontSize: 12,
                            height: 1.2,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          'Fahd',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleDisplaySmall.copyWith(
                            height: 1.0,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                            color: themeColor.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 2, 2, 2),
                    decoration: BoxDecoration(
                      color: themeColor.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [themeColor.cardShadow],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.tech_status_online,
                          style: const TextStyle(
                            color: Color(0xFF00C566),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Transform.scale(
                          scale: 0.65,
                          child: Switch.adaptive(
                            value: true,
                            onChanged: (v) {},
                            activeThumbColor: const Color(0xFF00C566),
                            activeTrackColor: const Color(
                              0xFF00C566,
                            ).withValues(alpha: 0.5),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeColor.cardBackground,
                      shape: BoxShape.circle,
                      boxShadow: [themeColor.cardShadow],
                    ),
                    child: Stack(
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          color: themeColor.textPrimary,
                          size: 22,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Stats Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeColor.cardBackground,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [themeColor.cardShadow],
                ),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.8,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildStatItem(context, l10n.tech_stats_jobs_today, '4'),
                    GestureDetector(
                      onTap: () => context.pushNamed(
                        TechnicianOrdersRoutes.technicianFinancialPortal,
                      ),
                      behavior: HitTestBehavior.opaque,
                      child: _buildStatItem(
                        context,
                        l10n.tech_stats_earnings,
                        '240.50',
                      ),
                    ),
                    _buildStatItem(
                      context,
                      l10n.tech_stats_rating,
                      '4.9',
                      icon: Icons.star_rounded,
                    ),
                    _buildStatItem(context, l10n.tech_stats_acceptance, '98%'),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Quick Tools
              Text(
                l10n.tech_quick_tools_title,
                style: textTheme.textOverline.copyWith(
                  color: themeColor.secondaryText,
                  letterSpacing: 1.2,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildToolItem(
                    context,
                    Icons.account_balance_wallet_outlined,
                    l10n.tech_tool_wallet,
                    onTap: () => context.pushNamed(
                      TechnicianOrdersRoutes.technicianFinancialPortal,
                    ),
                  ),
                  _buildToolItem(
                    context,
                    Icons.calendar_today_outlined,
                    l10n.tech_tool_schedule,
                    onTap: () => context.pushNamed('smart_schedule'),
                  ),
                  _buildToolItem(
                    context,
                    Icons.star_outline_rounded,
                    l10n.tech_tool_reviews,
                  ),
                  _buildToolItem(
                    context,
                    Icons.headset_mic_outlined,
                    l10n.tech_tool_support,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Active Job Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.tech_active_job_title,
                    style: textTheme.textOverline.copyWith(
                      color: themeColor.secondaryText,
                      letterSpacing: 1.2,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.tech_job_status_upcoming,
                      style: textTheme.textOverline.copyWith(
                        color: themeColor.primary,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Active Job Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeColor.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [themeColor.cardShadow],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'John Doe',
                                style: textTheme.titleSectionLarge.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                  color: themeColor.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AC Repair & Maintenance',
                                style: textTheme.textBodySecondary.copyWith(
                                  color: themeColor.secondaryText,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '14:00',
                          style: TextStyle(
                            color: themeColor.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Progress Indicator
                    Row(
                      children: [
                        _buildProgressStep(
                          context,
                          l10n.tech_job_status_accepted,
                          true,
                        ),
                        _buildProgressStep(
                          context,
                          l10n.tech_job_status_in_progress,
                          false,
                        ),
                        _buildProgressStep(
                          context,
                          l10n.tech_job_status_completed,
                          false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: MyCustomButton(
                            text: l10n.tech_action_view_details,
                            isOutlined: true,
                            borderColor: themeColor.primary,
                            height: 56,
                            borderRadius: 16,
                            leadingIcon: Icon(
                              Icons.info_outline_rounded,
                              color: themeColor.primary,
                              size: 18,
                            ),
                            textStyle: textTheme.textButton.copyWith(
                              color: themeColor.primary,
                              fontFamily: 'Cairo',
                            ),
                            onPressed: () {
                              // TODO: Navigate to Order Details
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MyCustomButton(
                            text: l10n.tech_action_start_job,
                            backgroundColor: themeColor.primary,
                            height: 56,
                            borderRadius: 16,
                            leadingIcon: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            textStyle: textTheme.textButton.copyWith(
                              color: Colors.white,
                              fontFamily: 'Cairo',
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
  }) {
    final themeColor = context.themeColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: themeColor.secondaryText,
            fontSize: 13,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: themeColor.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, color: Colors.amber, size: 20),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildToolItem(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    final themeColor = context.themeColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: themeColor.cardBackground,
              shape: BoxShape.circle,
              boxShadow: [themeColor.cardShadow],
            ),
            child: Icon(icon, color: themeColor.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: themeColor.textPrimary.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(BuildContext context, String label, bool isActive) {
    final themeColor = context.themeColor;
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: isActive
                    ? Container()
                    : Divider(
                        color: themeColor.unselectedItem.withValues(alpha: 0.3),
                        thickness: 1.5,
                      ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isActive
                      ? themeColor.primary
                      : themeColor.unselectedItem.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Divider(
                  color: themeColor.unselectedItem.withValues(alpha: 0.3),
                  thickness: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              color: isActive ? themeColor.primary : themeColor.secondaryText,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
