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
      id: '',
      userId: '',
      governorate: model.governorate,
      city: model.city,
      district: model.district.isNotEmpty ? model.district : model.city,
      governorateId: model.governorateId,
      cityId: model.cityId,
      districtId: model.districtId,
      governorateAr: model.governorateAr,
      governorateEn: model.governorateEn,
      cityAr: model.cityAr,
      cityEn: model.cityEn,
      districtAr: model.districtAr,
      districtEn: model.districtEn,
      streetOrCompound: model.street,
      buildingIdentifier: model.buildingNumber,
      apartmentOrUnit: model.apartmentNumber,
      floor: model.floorNumber,
      landmark: model.landmark,
      propertyType: model.propertyType,
      locationUrl: model.locationUrl,
      latitude: model.latitude,
      longitude: model.longitude,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static AddressSnapshotModel addressToSnapshot(Address entity) {
    return AddressSnapshotModel(
      governorate: entity.governorate,
      city: entity.city,
      district: entity.district,
      governorateId: entity.governorateId,
      cityId: entity.cityId,
      districtId: entity.districtId,
      governorateAr: entity.governorateAr ?? entity.governorate,
      governorateEn: entity.governorateEn ?? entity.governorate,
      cityAr: entity.cityAr ?? entity.city,
      cityEn: entity.cityEn ?? entity.city,
      districtAr: entity.districtAr ?? entity.district,
      districtEn: entity.districtEn ?? entity.district,
      street: entity.streetOrCompound,
      buildingNumber: entity.buildingIdentifier,
      apartmentNumber: entity.apartmentOrUnit,
      floorNumber: entity.floor,
      landmark: entity.landmark,
      propertyType: entity.propertyType,
      locationUrl: entity.locationUrl,
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
      fieldSnapshot: model.fieldSnapshot,
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
      fieldSnapshot: entity.fieldSnapshot,
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
        id: '',
        userId: model.userId ?? '',
        governorate: model.address.governorate,
        city: model.address.city,
        district: model.address.district.isNotEmpty ? model.address.district : model.address.city,
        streetOrCompound: model.address.streetOrCompound,
        buildingIdentifier: model.address.buildingIdentifier,
        floor: model.address.floor,
        apartmentOrUnit: model.address.apartmentOrUnit,
        landmark: model.address.landmark,
        propertyType: model.address.propertyType,
        latitude: model.address.latitude,
        longitude: model.address.longitude,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
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
      isWhatsappConfirmed: true,
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
        id: entity.address.id,
        userId: entity.address.userId,
        governorate: entity.address.governorate,
        city: entity.address.city,
        district: entity.address.district,
        streetOrCompound: entity.address.streetOrCompound,
        buildingIdentifier: entity.address.buildingIdentifier,
        floor: entity.address.floor,
        apartmentOrUnit: entity.address.apartmentOrUnit,
        latitude: entity.address.latitude,
        longitude: entity.address.longitude,
        createdAt: entity.address.createdAt,
        updatedAt: entity.address.updatedAt,
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
