// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewModel _$ReviewModelFromJson(Map<String, dynamic> json) => ReviewModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      customerId: json['customer_id'] as String,
      technicianId: json['technician_id'] as String,
      serviceId: json['service_id'] as String,
      ratingValue: (json['rating_value'] as num).toInt(),
      feedbackText: json['feedback_text'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] == null
          ? null
          : DateTime.parse(json['approved_at'] as String),
      serviceTitle: json['service_title'] as Map<String, dynamic>?,
      serviceImage: json['service_image'] as String?,
      technicianFirstName: json['technician_first_name'] as String?,
      technicianLastName: json['technician_last_name'] as String?,
      technicianAvatarUrl: json['technician_avatar_url'] as String?,
      customerFirstName: json['customer_first_name'] as String?,
      customerLastName: json['customer_last_name'] as String?,
      customerAvatarUrl: json['customer_avatar_url'] as String?,
    );

Map<String, dynamic> _$ReviewModelToJson(ReviewModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'booking_id': instance.bookingId,
      'customer_id': instance.customerId,
      'technician_id': instance.technicianId,
      'service_id': instance.serviceId,
      'rating_value': instance.ratingValue,
      'feedback_text': instance.feedbackText,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'approved_by': instance.approvedBy,
      'approved_at': instance.approvedAt?.toIso8601String(),
      'service_title': instance.serviceTitle,
      'service_image': instance.serviceImage,
      'technician_first_name': instance.technicianFirstName,
      'technician_last_name': instance.technicianLastName,
      'technician_avatar_url': instance.technicianAvatarUrl,
      'customer_first_name': instance.customerFirstName,
      'customer_last_name': instance.customerLastName,
      'customer_avatar_url': instance.customerAvatarUrl,
    };
