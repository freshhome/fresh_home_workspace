import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_campaign.dart';
import '../cubit/notification_management_cubit.dart';
import 'send_notification_screen.dart';
import 'simple_test_notification_screen.dart';

class NotificationDashboardScreen extends StatefulWidget {
  const NotificationDashboardScreen({super.key});

  @override
  State<NotificationDashboardScreen> createState() => _NotificationDashboardScreenState();
}

class _NotificationDashboardScreenState extends State<NotificationDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationManagementCubit>().fetchCampaigns();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الإشعارات (Campaigns)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, size: 28),
            tooltip: 'مختبر الإشعارات (Test)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SimpleTestNotificationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, size: 28),
            tooltip: 'حملة جديدة',
            onPressed: () {
              final cubit = context.read<NotificationManagementCubit>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: const SendNotificationScreen(),
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: BlocBuilder<NotificationManagementCubit, NotificationManagementState>(
        builder: (context, state) {
          if (state is NotificationManagementLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotificationManagementError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  TextButton(
                    onPressed: () => context.read<NotificationManagementCubit>().fetchCampaigns(),
                    child: const Text('إعادة المحاولة'),
                  )
                ],
              ),
            );
          } else if (state is NotificationManagementLoaded) {
            if (state.campaigns.isEmpty) {
              return const Center(child: Text('لا توجد أي حملات إعلانية سابقة.'));
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<NotificationManagementCubit>().fetchCampaigns(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: state.campaigns.length,
                itemBuilder: (context, index) {
                  return _buildCampaignCard(state.campaigns[index], context);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.send),
        label: const Text('إرسال إشعار'),
        onPressed: () {
          final cubit = context.read<NotificationManagementCubit>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: const SendNotificationScreen(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCampaignCard(NotificationCampaign campaign, BuildContext context) {
    final bool isFailed = campaign.status == CampaignStatus.failed;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    campaign.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _buildStatusBadge(campaign.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              campaign.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الاستهداف: ${campaign.targetType.name.toUpperCase()}', 
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    Text(
                      campaign.scheduledAt != null 
                        ? 'مجدول: ${campaign.scheduledAt.toString().substring(0, 16)}' 
                        : 'أرسل: ${campaign.createdAt.toString().substring(0, 16)}',
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('نجاح: ${campaign.successCount} ✅', style: const TextStyle(fontSize: 12, color: Colors.green)),
                    Text('فشل: ${campaign.failureCount} ❌', style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ],
                ),
              ],
            ),
            if (isFailed)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh, color: Colors.red),
                  label: const Text('إعادة المحاولة (Retry)', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    context.read<NotificationManagementCubit>().retryCampaign(campaign.id);
                  },
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(CampaignStatus status) {
    Color color;
    String text;
    switch (status) {
      case CampaignStatus.sent:
        color = Colors.green;
        text = 'مكتمل';
        break;
      case CampaignStatus.sending:
        color = Colors.blue;
        text = 'جاري الإرسال';
        break;
      case CampaignStatus.scheduled:
        color = Colors.orange;
        text = 'مجدول';
        break;
      case CampaignStatus.failed:
        color = Colors.red;
        text = 'فشل';
        break;
      default:
        color = Colors.grey;
        text = 'مسودة';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
