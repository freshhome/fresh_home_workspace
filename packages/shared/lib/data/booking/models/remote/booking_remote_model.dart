import 'package:shared/core/converters/timestamp_converter.dart';
import 'package:shared/data/booking/models/remote/sub_models/booking_snapshots.dart';
import 'package:shared/data/booking/models/remote/sub_models/booking_components_remote_model.dart';

@TimestampConverter()
class BookingRemoteModel {
  final String id;
  final String userId;
  final String? technicianId;
  final ServiceSnapshotModel service;
  final AddressSnapshotModel address;
  final PriceSnapshotModel price;
  final String status;
  final DateTime scheduledAt;
  final String startTimeSlot;
  final ContactModel contact;
  final String? addressId;
  final String? serviceId;
  final String? readableId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? dispatchedAt; 
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReasonCode;
  final String? cancelledByRole;
  final bool isCritical;
  final String? criticalReason;
  final Map<String, dynamic>? pricingInputs;

  const BookingRemoteModel({
    required this.id,
    required this.userId,
    this.technicianId,
    required this.service,
    required this.address,
    required this.price,
    required this.status,
    required this.scheduledAt,
    required this.startTimeSlot,
    required this.contact,
    required this.createdAt,
    required this.updatedAt,
    this.addressId,
    this.serviceId,
    this.readableId,
    this.assignedAt,
    this.acceptedAt,
    this.dispatchedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReasonCode,
    this.cancelledByRole,
    this.isCritical = false,
    this.criticalReason,
    this.pricingInputs,
  });

  factory BookingRemoteModel.fromJson(Map<String, dynamic> json) {
    return BookingRemoteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      technicianId: json['technician_id'] as String?,
      service: ServiceSnapshotModel.fromJson(json['service_snapshot'] as Map<String, dynamic>),
      address: AddressSnapshotModel.fromJson(json['address_snapshot'] as Map<String, dynamic>),
      price: PriceSnapshotModel.fromJson(json['price_snapshot'] as Map<String, dynamic>),
      status: json['status'] as String,
      scheduledAt: DateTime.parse(json['scheduled_day'] as String),
      startTimeSlot: json['start_time_slot'] as String? ?? '09:00',
      contact: ContactModel(
        name: json['contact_name'] as String? ?? 'Client',
        phone: List<String>.from(json['contact_phones'] as List? ?? []),
      ),
      addressId: json['address_id'] as String?,
      serviceId: json['service_id'] as String?,
      readableId: json['readable_id'] as String?,
      createdAt: const TimestampConverter().fromJson(json['created_at']),
      updatedAt: const TimestampConverter().fromJson(json['updated_at']),
      assignedAt: json['assigned_at'] != null ? const TimestampConverter().fromJson(json['assigned_at']) : null,
      acceptedAt: json['accepted_at'] != null ? const TimestampConverter().fromJson(json['accepted_at']) : null,
      dispatchedAt: json['dispatched_at'] != null ? const TimestampConverter().fromJson(json['dispatched_at']) : null,
      arrivedAt: json['arrived_at'] != null ? const TimestampConverter().fromJson(json['arrived_at']) : null,
      startedAt: json['started_at'] != null ? const TimestampConverter().fromJson(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? const TimestampConverter().fromJson(json['completed_at']) : null,
      cancelledAt: json['cancelled_at'] != null ? const TimestampConverter().fromJson(json['cancelled_at']) : null,
      cancellationReasonCode: json['cancellation_reason_code'] as String?,
      cancelledByRole: json['cancelled_by_role'] as String?,
      isCritical: json['is_critical'] as bool? ?? false,
      criticalReason: json['critical_reason'] as String?,
      pricingInputs: json['pricing_inputs'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'technician_id': technicianId,
      'service_snapshot': service.toJson(),
      'address_snapshot': address.toJson(),
      'price_snapshot': price.toJson(),
      'status': status,
      'scheduled_day': scheduledAt.toIso8601String().split('T').first,
      'start_time_slot': startTimeSlot,
      'contact_name': contact.name,
      'contact_phones': contact.phone,
      if (addressId != null) 'address_id': addressId,
      if (serviceId != null) 'service_id': serviceId,
      if (readableId != null) 'readable_id': readableId,
      'created_at': const TimestampConverter().toJson(createdAt),
      'updated_at': const TimestampConverter().toJson(updatedAt),
      if (assignedAt != null) 'assigned_at': const TimestampConverter().toJson(assignedAt!),
      if (acceptedAt != null) 'accepted_at': const TimestampConverter().toJson(acceptedAt!),
      if (dispatchedAt != null) 'dispatched_at': const TimestampConverter().toJson(dispatchedAt!),
      if (arrivedAt != null) 'arrived_at': const TimestampConverter().toJson(arrivedAt!),
      if (startedAt != null) 'started_at': const TimestampConverter().toJson(startedAt!),
      if (completedAt != null) 'completed_at': const TimestampConverter().toJson(completedAt!),
      if (cancelledAt != null) 'cancelled_at': const TimestampConverter().toJson(cancelledAt!),
      if (cancellationReasonCode != null) 'cancellation_reason_code': cancellationReasonCode,
      if (cancelledByRole != null) 'cancelled_by_role': cancelledByRole,
      'is_critical': isCritical,
      if (criticalReason != null) 'critical_reason': criticalReason,
      if (pricingInputs != null) 'pricing_inputs': pricingInputs,
    };
  }
}
