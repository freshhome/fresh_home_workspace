import '../../domain/entities/notification_campaign.dart';

class NotificationCampaignModel extends NotificationCampaign {
  const NotificationCampaignModel({
    required super.id,
    required super.title,
    required super.body,
    super.imageUrl,
    required super.targetType,
    required super.targetFilter,
    super.deepLink,
    required super.payload,
    required super.priority,
    super.scheduledAt,
    super.sentAt,
    required super.status,
    required super.successCount,
    required super.failureCount,
    super.createdBy,
    required super.createdAt,
  });

  factory NotificationCampaignModel.fromJson(Map<String, dynamic> json) {
    return NotificationCampaignModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['image_url'] as String?,
      targetType: _parseTargetType(json['target_type'] as String),
      targetFilter: json['target_filter'] as Map<String, dynamic>? ?? {},
      deepLink: json['deep_link'] as String?,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      priority: _parsePriority(json['priority'] as String?),
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at'] as String).toLocal() : null,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String).toLocal() : null,
      status: _parseStatus(json['status'] as String),
      successCount: json['success_count'] as int? ?? 0,
      failureCount: json['failure_count'] as int? ?? 0,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'target_type': targetType.name,
      'target_filter': targetFilter,
      'deep_link': deepLink,
      'payload': payload,
      'priority': priority.name,
      'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
      'sent_at': sentAt?.toUtc().toIso8601String(),
      'status': status.name,
      'success_count': successCount,
      'failure_count': failureCount,
      'created_by': createdBy,
    };
  }

  factory NotificationCampaignModel.fromEntity(NotificationCampaign entity) {
    return NotificationCampaignModel(
      id: entity.id,
      title: entity.title,
      body: entity.body,
      imageUrl: entity.imageUrl,
      targetType: entity.targetType,
      targetFilter: entity.targetFilter,
      deepLink: entity.deepLink,
      payload: entity.payload,
      priority: entity.priority,
      scheduledAt: entity.scheduledAt,
      sentAt: entity.sentAt,
      status: entity.status,
      successCount: entity.successCount,
      failureCount: entity.failureCount,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
    );
  }

  static TargetType _parseTargetType(String value) {
    switch (value) {
      case 'customers':
        return TargetType.customers;
      case 'technicians':
        return TargetType.technicians;
      case 'single_user':
        return TargetType.singleUser;
      case 'city':
        return TargetType.city;
      case 'service':
        return TargetType.service;
      case 'topic':
        return TargetType.topic;
      case 'all':
      default:
        return TargetType.all;
    }
  }

  static NotificationPriority _parsePriority(String? value) {
    if (value == 'high') return NotificationPriority.high;
    return NotificationPriority.normal;
  }

  static CampaignStatus _parseStatus(String value) {
    switch (value) {
      case 'scheduled':
        return CampaignStatus.scheduled;
      case 'sending':
        return CampaignStatus.sending;
      case 'sent':
        return CampaignStatus.sent;
      case 'failed':
        return CampaignStatus.failed;
      case 'draft':
      default:
        return CampaignStatus.draft;
    }
  }
}
