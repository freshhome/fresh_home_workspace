import 'package:json_annotation/json_annotation.dart';
import '../../../domain/reviews/entities/review_entity.dart';

part 'review_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ReviewModel extends ReviewEntity {
  @JsonKey(name: 'id')
  @override
  final String id;

  @JsonKey(name: 'booking_id')
  @override
  final String bookingId;

  @JsonKey(name: 'customer_id')
  @override
  final String customerId;

  @JsonKey(name: 'technician_id')
  @override
  final String technicianId;

  @JsonKey(name: 'service_id')
  @override
  final String serviceId;

  @JsonKey(name: 'rating_value')
  @override
  final int ratingValue;

  @JsonKey(name: 'feedback_text')
  @override
  final String? feedbackText;

  @JsonKey(name: 'status')
  @override
  final String status;

  @JsonKey(name: 'created_at')
  @override
  final DateTime createdAt;

  @JsonKey(name: 'approved_by')
  @override
  final String? approvedBy;

  @JsonKey(name: 'approved_at')
  @override
  final DateTime? approvedAt;

  @JsonKey(name: 'service_title')
  @override
  final Map<String, dynamic>? serviceTitle;

  @JsonKey(name: 'service_image')
  @override
  final String? serviceImage;

  @JsonKey(name: 'technician_first_name')
  @override
  final String? technicianFirstName;

  @JsonKey(name: 'technician_last_name')
  @override
  final String? technicianLastName;

  @JsonKey(name: 'technician_avatar_url')
  @override
  final String? technicianAvatarUrl;

  @JsonKey(name: 'customer_first_name')
  @override
  final String? customerFirstName;

  @JsonKey(name: 'customer_last_name')
  @override
  final String? customerLastName;

  @JsonKey(name: 'customer_avatar_url')
  @override
  final String? customerAvatarUrl;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.technicianId,
    required this.serviceId,
    required this.ratingValue,
    this.feedbackText,
    required this.status,
    required this.createdAt,
    this.approvedBy,
    this.approvedAt,
    this.serviceTitle,
    this.serviceImage,
    this.technicianFirstName,
    this.technicianLastName,
    this.technicianAvatarUrl,
    this.customerFirstName,
    this.customerLastName,
    this.customerAvatarUrl,
  }) : super(
          id: id,
          bookingId: bookingId,
          customerId: customerId,
          technicianId: technicianId,
          serviceId: serviceId,
          ratingValue: ratingValue,
          feedbackText: feedbackText,
          status: status,
          createdAt: createdAt,
          approvedBy: approvedBy,
          approvedAt: approvedAt,
          serviceTitle: serviceTitle,
          serviceImage: serviceImage,
          technicianFirstName: technicianFirstName,
          technicianLastName: technicianLastName,
          technicianAvatarUrl: technicianAvatarUrl,
          customerFirstName: customerFirstName,
          customerLastName: customerLastName,
          customerAvatarUrl: customerAvatarUrl,
        );

  factory ReviewModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewModelToJson(this);
}
