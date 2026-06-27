import 'package:shared/data/booking/models/local/booking_hive_model.dart';
import 'package:shared/data/booking/models/local/sub_models/booking_components_hive_model.dart';
import 'package:shared/data/booking/models/remote/booking_remote_model.dart';
import 'package:shared/data/booking/models/remote/sub_models/booking_snapshots.dart';
import 'package:shared/data/booking/models/remote/sub_models/booking_components_remote_model.dart';
import 'package:shared/data/user/models/address_model.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/data/booking/models/remote/order_status_model.dart';

class BookingMapper {
  // --- Service Snapshot ---
  static BookedService serviceSnapshotToEntity(ServiceSnapshotModel model) {
    return BookedService(
      id: model.id,
      subServiceId: model.subServiceId,
      name: model.name,
      image: model.image,
    );
  }

  static ServiceSnapshotModel serviceToSnapshot(BookedService entity) {
    return ServiceSnapshotModel(
      id: entity.id,
      subServiceId: entity.subServiceId,
      name: entity.name,
      image: entity.image,
    );
  }

  // --- Address Snapshot ---
  static Address addressSnapshotToEntity(AddressSnapshotModel model) {
    return Address(
      governorate: model.governorate,
      city: model.city,
      street: model.street,
      buildingNumber: model.buildingNumber,
      apartmentNumber: model.apartmentNumber,
      floorNumber: model.floorNumber,
      latitude: model.latitude,
      longitude: model.longitude,
    );
  }

  static AddressSnapshotModel addressToSnapshot(Address entity) {
    return AddressSnapshotModel(
      governorate: entity.governorate,
      city: entity.city,
      street: entity.street,
      buildingNumber: entity.buildingNumber,
      apartmentNumber: entity.apartmentNumber,
      floorNumber: entity.floorNumber,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }

  // --- Price Snapshot ---
  static BookingPricing priceSnapshotToEntity(PriceSnapshotModel model) {
    return BookingPricing(
      basePrice: model.basePrice,
      extraFees: model.extraFees,
      discount: model.discount,
      total: model.total,
      metadata: model.metadata,
    );
  }

  static PriceSnapshotModel priceToSnapshot(BookingPricing entity) {
    return PriceSnapshotModel(
      basePrice: entity.basePrice,
      extraFees: entity.extraFees,
      discount: entity.discount,
      total: entity.total,
      metadata: entity.metadata,
    );
  }

  // --- Contact Snapshot ---
  static ContactModel contactToSnapshot(Contact entity) {
    return ContactModel(
      name: entity.name,
      phone: entity.phone,
    );
  }

  static DateTime _mergeDateTime(DateTime date, String timeString) {
    try {
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return date;
    }
  }

  // --- Booking ---
  static Booking remoteToEntity(BookingRemoteModel model) {
    return Booking(
      id: model.id,
      readableId: model.readableId,
      userId: model.userId,
      technicianId: model.technicianId,
      service: serviceSnapshotToEntity(model.service),
      address: addressSnapshotToEntity(model.address),
      scheduledAt: _mergeDateTime(model.scheduledAt, model.startTimeSlot),
      startTimeSlot: model.startTimeSlot,
      price: priceSnapshotToEntity(model.price),
      status: OrderStatusModel.fromJson(model.status),
      contact: Contact(
        name: model.contact.name,
        phone: model.contact.phone,
      ),
      addressId: model.addressId,
      serviceId: model.serviceId,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      isWhatsappConfirmed: model.isWhatsappConfirmed,
      paymentMethod: model.paymentMethod,
      paymentStatus: model.paymentStatus,
      assignedAt: model.assignedAt,
      acceptedAt: model.acceptedAt,
      dispatchedAt: model.dispatchedAt,
      arrivedAt: model.arrivedAt,
      startedAt: model.startedAt,
      completedAt: model.completedAt,
      cancelledAt: model.cancelledAt,
      cancellationReasonCode: model.cancellationReasonCode,
      cancelledByRole: model.cancelledByRole,
      isCritical: model.isCritical,
      criticalReason: model.criticalReason,
      pricingInputs: model.pricingInputs,
    );
  }

  static BookingRemoteModel entityToRemote(Booking entity) {
    return BookingRemoteModel(
      id: entity.id,
      readableId: entity.readableId,
      userId: entity.userId,
      technicianId: entity.technicianId,
      service: serviceToSnapshot(entity.service),
      address: addressToSnapshot(entity.address),
      scheduledAt: entity.scheduledAt,
      startTimeSlot: entity.startTimeSlot,
      price: priceToSnapshot(entity.price),
      status: OrderStatusModel.toJson(entity.status),
      contact: contactToSnapshot(entity.contact),
      addressId: entity.addressId,
      serviceId: entity.serviceId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isWhatsappConfirmed: entity.isWhatsappConfirmed,
      paymentMethod: entity.paymentMethod,
      paymentStatus: entity.paymentStatus,
      assignedAt: entity.assignedAt,
      acceptedAt: entity.acceptedAt,
      dispatchedAt: entity.dispatchedAt,
      arrivedAt: entity.arrivedAt,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      cancelledAt: entity.cancelledAt,
      cancellationReasonCode: entity.cancellationReasonCode,
      cancelledByRole: entity.cancelledByRole,
      isCritical: entity.isCritical,
      criticalReason: entity.criticalReason,
      pricingInputs: entity.pricingInputs,
    );
  }

  // --- Hive Mappings ---
  static Booking hiveToEntity(BookingHiveModel model) {
    return Booking(
      id: model.id,
      readableId: model.readableId,
      userId: model.userId,
      technicianId: model.technicianId,
      service: BookedService(
        id: model.service.id,
        subServiceId: model.service.subServiceId,
        name: model.service.name,
        image: model.service.image,
      ),
      address: Address(
        governorate: model.address.governorate,
        city: model.address.city,
        street: model.address.street,
        buildingNumber: model.address.buildingNumber,
        apartmentNumber: model.address.apartmentNumber,
        floorNumber: model.address.floorNumber,
        latitude: model.address.latitude,
        longitude: model.address.longitude,
      ),
      scheduledAt: model.scheduledAt,
      startTimeSlot: model.startTimeSlot,
      price: BookingPricing(
        basePrice: model.price.basePrice,
        extraFees: model.price.extraFees,
        discount: model.price.discount,
        total: model.price.total,
        metadata: model.price.metadata != null ? Map<String, dynamic>.from(model.price.metadata!) : null,
      ),
      status: model.status,
      contact: Contact(
        name: model.contact.name,
        phone: model.contact.phone,
      ),
      addressId: model.addressId,
      serviceId: model.serviceId,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      isWhatsappConfirmed: true, // Defaults to true for local cache
      paymentMethod: model.paymentMethod,
      paymentStatus: model.paymentStatus,
      assignedAt: model.assignedAt,
      acceptedAt: model.acceptedAt,
      dispatchedAt: model.dispatchedAt,
      arrivedAt: model.arrivedAt,
      startedAt: model.startedAt,
      completedAt: model.completedAt,
      cancelledAt: model.cancelledAt,
      cancellationReasonCode: model.cancellationReasonCode,
      cancelledByRole: model.cancelledByRole,
    );
  }

  static BookingHiveModel entityToHive(Booking entity) {
    return BookingHiveModel(
      id: entity.id,
      readableId: entity.readableId,
      userId: entity.userId,
      technicianId: entity.technicianId,
      service: BookedServiceHiveModel(
        id: entity.service.id,
        subServiceId: entity.service.subServiceId,
        name: entity.service.name,
        image: entity.service.image,
      ),
      address: AddressModel(
        governorate: entity.address.governorate,
        city: entity.address.city,
        street: entity.address.street,
        buildingNumber: entity.address.buildingNumber,
        apartmentNumber: entity.address.apartmentNumber,
        floorNumber: entity.address.floorNumber,
        latitude: entity.address.latitude,
        longitude: entity.address.longitude,
      ),
      scheduledAt: entity.scheduledAt,
      startTimeSlot: entity.startTimeSlot,
      price: BookingPricingHiveModel(
        basePrice: entity.price.basePrice,
        extraFees: entity.price.extraFees,
        discount: entity.price.discount,
        total: entity.price.total,
        metadata: entity.price.metadata,
      ),
      status: entity.status,
      contact: ContactHiveModel(
        name: entity.contact.name,
        phone: entity.contact.phone,
      ),
      addressId: entity.addressId,
      serviceId: entity.serviceId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      assignedAt: entity.assignedAt,
      acceptedAt: entity.acceptedAt,
      dispatchedAt: entity.dispatchedAt,
      arrivedAt: entity.arrivedAt,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      cancelledAt: entity.cancelledAt,
      cancellationReasonCode: entity.cancellationReasonCode,
      cancelledByRole: entity.cancelledByRole,
      paymentMethod: entity.paymentMethod,
      paymentStatus: entity.paymentStatus,
    );
  }

  static BookingHiveModel remoteToHive(BookingRemoteModel model) {
    return entityToHive(remoteToEntity(model));
  }
}
