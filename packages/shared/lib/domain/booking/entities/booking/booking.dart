import 'package:equatable/equatable.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/user/entities/user/address.dart';

class Booking extends Equatable {
  final String id;
  final String userId;
  final String? technicianId;
  final BookedService service;
  final Address address;
  final DateTime scheduledAt;
  final String startTimeSlot;
  final BookingPricing price;
  final OrderStatus status;
  final Contact contact;
  final String? addressId;
  final String? serviceId;
  final String? readableId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isWhatsappConfirmed;

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

  String get displayId => readableId ?? id.split('-').first;

  const Booking({
    required this.id,
    required this.userId,
    this.technicianId,
    required this.service,
    required this.address,
    required this.scheduledAt,
    required this.startTimeSlot,
    required this.price,
    required this.status,
    required this.contact,
    required this.createdAt,
    required this.updatedAt,
    this.isWhatsappConfirmed = true,
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

  Booking copyWith({
    String? id,
    String? userId,
    String? technicianId,
    BookedService? service,
    Address? address,
    DateTime? scheduledAt,
    String? startTimeSlot,
    BookingPricing? price,
    OrderStatus? status,
    Contact? contact,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isWhatsappConfirmed,
    String? addressId,
    String? serviceId,
    String? readableId,
    // Nullable lifecycle timestamps — pass a non-null value to set, omit to keep existing
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? dispatchedAt,
    DateTime? arrivedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReasonCode,
    String? cancelledByRole,
    bool? isCritical,
    String? criticalReason,
    Map<String, dynamic>? pricingInputs,
    // Flags to explicitly clear nullable fields to null
    bool clearAssignedAt = false,
    bool clearAcceptedAt = false,
    bool clearDispatchedAt = false,
    bool clearArrivedAt = false,
    bool clearStartedAt = false,
    bool clearCompletedAt = false,
    bool clearCancelledAt = false,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      technicianId: technicianId ?? this.technicianId,
      service: service ?? this.service,
      address: address ?? this.address,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startTimeSlot: startTimeSlot ?? this.startTimeSlot,
      price: price ?? this.price,
      status: status ?? this.status,
      contact: contact ?? this.contact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isWhatsappConfirmed: isWhatsappConfirmed ?? this.isWhatsappConfirmed,
      addressId: addressId ?? this.addressId,
      serviceId: serviceId ?? this.serviceId,
      readableId: readableId ?? this.readableId,
      assignedAt: clearAssignedAt ? null : (assignedAt ?? this.assignedAt),
      acceptedAt: clearAcceptedAt ? null : (acceptedAt ?? this.acceptedAt),
      dispatchedAt: clearDispatchedAt ? null : (dispatchedAt ?? this.dispatchedAt),
      arrivedAt: clearArrivedAt ? null : (arrivedAt ?? this.arrivedAt),
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      cancelledAt: clearCancelledAt ? null : (cancelledAt ?? this.cancelledAt),
      cancellationReasonCode: cancellationReasonCode ?? this.cancellationReasonCode,
      cancelledByRole: cancelledByRole ?? this.cancelledByRole,
      isCritical: isCritical ?? this.isCritical,
      criticalReason: criticalReason ?? this.criticalReason,
      pricingInputs: pricingInputs ?? this.pricingInputs,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    technicianId,
    service,
    address,
    scheduledAt,
    startTimeSlot,
    price,
    status,
    contact,
    addressId,
    serviceId,
    readableId,
    createdAt,
    updatedAt,
    isWhatsappConfirmed,
    assignedAt,
    acceptedAt,
    dispatchedAt,
    arrivedAt,
    startedAt,
    completedAt,
    cancelledAt,
    cancellationReasonCode,
    cancelledByRole,
    isCritical,
    criticalReason,
    pricingInputs,
  ];
}
