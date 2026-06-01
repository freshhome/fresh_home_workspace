import 'package:equatable/equatable.dart';

enum TargetType { all, customers, technicians, singleUser, city, service, topic }
enum CampaignStatus { draft, scheduled, sending, sent, failed }
enum NotificationPriority { normal, high }

class NotificationCampaign extends Equatable {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final TargetType targetType;
  final Map<String, dynamic> targetFilter;
  final String? deepLink;
  final Map<String, dynamic> payload;
  final NotificationPriority priority;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final CampaignStatus status;
  final int successCount;
  final int failureCount;
  final String? createdBy;
  final DateTime createdAt;

  const NotificationCampaign({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.targetType,
    required this.targetFilter,
    this.deepLink,
    required this.payload,
    required this.priority,
    this.scheduledAt,
    this.sentAt,
    required this.status,
    required this.successCount,
    required this.failureCount,
    this.createdBy,
    required this.createdAt,
  });

  // Factory for creating a new unsent campaign locally before sending
  factory NotificationCampaign.create({
    required String title,
    required String body,
    String? imageUrl,
    required TargetType targetType,
    Map<String, dynamic>? targetFilter,
    String? deepLink,
    Map<String, dynamic>? payload,
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? scheduledAt,
  }) {
    return NotificationCampaign(
      id: '', // Will be assigned by DB
      title: title,
      body: body,
      imageUrl: imageUrl,
      targetType: targetType,
      targetFilter: targetFilter ?? {},
      deepLink: deepLink,
      payload: payload ?? {},
      priority: priority,
      scheduledAt: scheduledAt,
      sentAt: null,
      status: scheduledAt != null ? CampaignStatus.scheduled : CampaignStatus.sending,
      successCount: 0,
      failureCount: 0,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        imageUrl,
        targetType,
        targetFilter,
        deepLink,
        payload,
        priority,
        scheduledAt,
        sentAt,
        status,
        successCount,
        failureCount,
        createdBy,
        createdAt,
      ];
}
