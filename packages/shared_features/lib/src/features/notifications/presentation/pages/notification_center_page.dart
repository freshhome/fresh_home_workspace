import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import '../cubit/notification_cubit.dart';
import '../../domain/entities/notification.dart';
import '../utils/notification_router.dart';

class NotificationCenterPage extends StatelessWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            l10n.notifications_title,
            style: themeText.titleSectionSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.done_all_rounded, color: themeColor.primary),
              onPressed: () =>
                  context.read<NotificationCubit>().markAllAsRead(),
              tooltip: l10n.notifications_mark_all_read,
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: themeColor.primary,
            unselectedLabelColor: themeColor.secondaryText,
            indicatorColor: themeColor.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: themeText.textBodyPrimary.copyWith(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: themeText.textBodyPrimary,
            tabs: [
              Tab(text: l10n.notifications_tab_all),
              Tab(text: l10n.notifications_tab_orders),
              Tab(text: l10n.notifications_tab_system),
            ],
          ),
        ),
        body: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is NotificationError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(state.message, style: themeText.textBodyPrimary),
                    TextButton(
                      onPressed: () =>
                          context.read<NotificationCubit>().refresh(),
                      child: Text(l10n.general_retry),
                    ),
                  ],
                ),
              );
            }
            if (state is NotificationLoaded) {
              if (state.notifications.isEmpty) {
                return _buildEmptyState(context, l10n, themeColor, themeText);
              }

              return TabBarView(
                children: [
                  _NotificationsList(notifications: state.notifications),
                  _NotificationsList(
                    notifications: state.notifications
                        .where(
                          (n) =>
                              n.metadata['booking_id'] != null ||
                              n.metadata['type'] == 'order',
                        )
                        .toList(),
                    emptyMessage: l10n.notifications_empty_orders,
                  ),
                  _NotificationsList(
                    notifications: state.notifications
                        .where(
                          (n) =>
                              n.metadata['booking_id'] == null &&
                              n.metadata['type'] != 'order',
                        )
                        .toList(),
                    emptyMessage: l10n.notifications_empty_system,
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText, {
    String? message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: themeColor.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: themeColor.primary.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message ?? l10n.notifications_empty,
            style: themeText.titleSectionSmall.copyWith(
              color: themeColor.secondaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.notifications_empty_subtitle,
            textAlign: TextAlign.center,
            style: themeText.textCaption.copyWith(
              color: themeColor.secondaryText.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  final List<AppNotification> notifications;
  final String? emptyMessage;

  const _NotificationsList({required this.notifications, this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
      final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: themeColor.unselectedItem.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage ?? l10n.notifications_empty,
              style: themeText.textBodyPrimary.copyWith(
                color: themeColor.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => context.read<NotificationCubit>().refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return _NotificationTile(notification: notif);
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
    final timeStr = DateFormat(
      'hh:mm a - dd/MM',
      'ar',
    ).format(notification.createdAt);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationCubit>().markAsRead(notification.id);
          }
          NotificationRouter.navigate(context, notification);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : themeColor.primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: notification.isRead
                  ? Colors.white
                  : themeColor.primary.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getBgColor(
                    notification.metadata['status'],
                    themeColor,
                    notification.isRead,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getIcon(notification.metadata['status']),
                  color: _getIconColor(
                    notification.metadata['status'],
                    themeColor,
                    notification.isRead,
                  ),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: themeText.textBodyPrimary.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: notification.isRead
                                  ? themeColor.secondaryText
                                  : themeColor.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: themeColor.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: themeText.textCaption.copyWith(
                        color: themeColor.secondaryText.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: themeColor.secondaryText.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: themeText.textCaption.copyWith(
                            fontSize: 11,
                            color: themeColor.secondaryText.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      ],
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

  Color _getBgColor(String? status, ThemeColorExtension theme, bool isRead) {
    if (isRead) return Colors.grey.withValues(alpha: 0.05);
    switch (status) {
      case 'completed':
        return Colors.green.withValues(alpha: 0.1);
      case 'cancelled':
        return Colors.red.withValues(alpha: 0.1);
      case 'in_progress':
        return Colors.blue.withValues(alpha: 0.1);
      default:
        return theme.primary.withValues(alpha: 0.1);
    }
  }

  Color _getIconColor(String? status, ThemeColorExtension theme, bool isRead) {
    if (isRead) return theme.secondaryText.withValues(alpha: 0.4);
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      default:
        return theme.primary;
    }
  }

  IconData _getIcon(String? status) {
    switch (status) {
      case 'assigned':
        return Icons.person_add_alt_1_rounded;
      case 'accepted':
        return Icons.assignment_turned_in_rounded;
      case 'on_the_way':
        return Icons.local_shipping_rounded;
      case 'in_progress':
        return Icons.build_circle_rounded;
      case 'completed':
        return Icons.verified_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }
}
