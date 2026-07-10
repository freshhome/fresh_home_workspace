import 'package:shared/core/converters/timestamp_converter.dart';
import 'package:shared/data/booking/models/remote/sub_models/booking_snapshots.dart';
import 'package:shared/data/booking/models/remote/sub_models/booking_components_remote_model.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/dynamic_field_snapshot.dart';

@TimestampConverter()
class BookingRemoteModel {
  final String id;
  final String? userId;
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
  final DynamicFieldSnapshot? fieldSnapshot;
  final bool isWhatsappConfirmed;
  final String? paymentMethod;
  final String? paymentStatus;

  const BookingRemoteModel({
    required this.id,
    this.userId,
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
    this.isWhatsappConfirmed = true,
    this.addressId,
    this.serviceId,
    this.readableId,
    this.paymentMethod,
    this.paymentStatus,
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
    this.fieldSnapshot,
  });

  factory BookingRemoteModel.fromJson(Map<String, dynamic> json) {
    return BookingRemoteModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String?,
      technicianId: json['technician_id'] as String?,
      service: json['service_snapshot'] != null
          ? ServiceSnapshotModel.fromJson(json['service_snapshot'] as Map<String, dynamic>)
          : const ServiceSnapshotModel(id: '', subServiceId: '', name: {}, image: ''),
      address: json['address_snapshot'] != null
          ? AddressSnapshotModel.fromJson(json['address_snapshot'] as Map<String, dynamic>)
          : const AddressSnapshotModel(governorate: '', city: '', street: '', buildingNumber: ''),
      price: json['price_snapshot'] != null
          ? PriceSnapshotModel.fromJson(json['price_snapshot'] as Map<String, dynamic>)
          : const PriceSnapshotModel(basePrice: 0.0, extraFees: 0.0, discount: 0.0, total: 0.0),
      status: json['status'] as String? ?? 'pending',
      scheduledAt: json['scheduled_day'] != null
          ? DateTime.parse(json['scheduled_day'] as String)
          : DateTime.now(),
      startTimeSlot: json['start_time_slot'] as String? ?? '09:00',
      contact: ContactModel(
        name: json['contact_name'] as String? ?? 'Client',
        phone: List<String>.from(json['contact_phones'] as List? ?? []),
      ),
      addressId: json['address_id'] as String?,
      serviceId: json['service_id'] as String?,
      readableId: json['readable_id'] as String?,
      createdAt: json['created_at'] != null ? const TimestampConverter().fromJson(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? const TimestampConverter().fromJson(json['updated_at']) : DateTime.now(),
      isWhatsappConfirmed: json['is_whatsapp_confirmed'] as bool? ?? true,
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String?,
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
      fieldSnapshot: json['pricing_inputs']?['__field_snapshot'] != null
          ? DynamicFieldSnapshot.fromJson(
              Map<String, dynamic>.from(json['pricing_inputs']['__field_snapshot'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic>? resolvedPricingInputs;
    if (pricingInputs != null || fieldSnapshot != null) {
      resolvedPricingInputs = pricingInputs != null
          ? Map<String, dynamic>.from(pricingInputs!)
          : <String, dynamic>{};
      if (fieldSnapshot != null) {
        resolvedPricingInputs['__field_snapshot'] = fieldSnapshot!.toJson();
      }
    }

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
      'is_whatsapp_confirmed': isWhatsappConfirmed,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (paymentStatus != null) 'payment_status': paymentStatus,
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
      if (resolvedPricingInputs != null) 'pricing_inputs': resolvedPricingInputs,
    };
  }
}
