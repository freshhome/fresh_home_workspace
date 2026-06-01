
import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/data/user/models/address_model.dart';
import 'package:shared/data/booking/models/local/sub_models/booking_components_hive_model.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';

part 'booking_hive_model.g.dart';

@HiveType(typeId: HiveTypeIds.booking)
class BookingHiveModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final BookedServiceHiveModel service;
  @HiveField(3)
  final AddressModel address;
  @HiveField(4)
  final DateTime scheduledAt;
  @HiveField(5)
  final BookingPricingHiveModel price;
  @HiveField(6)
  final OrderStatus status;
  @HiveField(7)
  final ContactHiveModel contact;
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9)
  final DateTime updatedAt;
  @HiveField(10)
  final String? addressId;
  @HiveField(11)
  final String? serviceId;
  @HiveField(12)
  final String? readableId;
  @HiveField(13)
  final String? technicianId;
  @HiveField(14)
  final String startTimeSlot;
  
  // Professional Lifecycle
  @HiveField(15)
  final DateTime? assignedAt;
  @HiveField(16)
  final DateTime? acceptedAt;
  @HiveField(17)
  final DateTime? dispatchedAt;
  @HiveField(18)
  final DateTime? arrivedAt;
  @HiveField(19)
  final DateTime? startedAt;
  @HiveField(20)
  final DateTime? completedAt;
  @HiveField(21)
  final DateTime? cancelledAt;
  @HiveField(22)
  final String? cancellationReasonCode;
  @HiveField(23)
  final String? cancelledByRole;

  const BookingHiveModel({
    required this.id,
    required this.userId,
    required this.service,
    required this.address,
    required this.scheduledAt,
    required this.startTimeSlot,
    required this.price,
    required this.status,
    required this.contact,
    required this.createdAt,
    required this.updatedAt,
    this.addressId,
    this.serviceId,
    this.readableId,
    this.technicianId,
    this.assignedAt,
    this.acceptedAt,
    this.dispatchedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReasonCode,
    this.cancelledByRole,
  });
}
