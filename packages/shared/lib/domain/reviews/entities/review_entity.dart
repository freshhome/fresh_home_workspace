import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final String id;
  final String bookingId;
  final String customerId;
  final String technicianId;
  final String serviceId;
  final int ratingValue;
  final String? feedbackText;
  final String status;
  final DateTime createdAt;
  
  // Auditing / Moderation fields
  final String? approvedBy;
  final DateTime? approvedAt;

  // View-populated fields
  final Map<String, dynamic>? serviceTitle;
  final String? serviceImage;
  final String? technicianFirstName;
  final String? technicianLastName;
  final String? technicianAvatarUrl;
  final String? customerFirstName;
  final String? customerLastName;
  final String? customerAvatarUrl;

  const ReviewEntity({
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
  });

  String get technicianFullName => 
      '${technicianFirstName ?? ''} ${technicianLastName ?? ''}'.trim();
      
  String get customerFullName => 
      '${customerFirstName ?? ''} ${customerLastName ?? ''}'.trim();

  @override
  List<Object?> get props => [
        id,
        bookingId,
        customerId,
        technicianId,
        serviceId,
        ratingValue,
        feedbackText,
        status,
        createdAt,
        approvedBy,
        approvedAt,
        serviceTitle,
        serviceImage,
        technicianFirstName,
        technicianLastName,
        technicianAvatarUrl,
        customerFirstName,
        customerLastName,
        customerAvatarUrl,
      ];
}
