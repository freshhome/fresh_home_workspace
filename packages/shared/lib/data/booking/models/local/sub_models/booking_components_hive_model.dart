import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';

part 'booking_components_hive_model.g.dart';

@HiveType(typeId: HiveTypeIds.bookedService)
class BookedServiceHiveModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String subServiceId;
  @HiveField(2)
  final Map<String, String> name;
  @HiveField(3)
  final String image;

  const BookedServiceHiveModel({
    required this.id,
    required this.subServiceId,
    required this.name,
    required this.image,
  });
}

@HiveType(typeId: HiveTypeIds.bookingPricing)
class BookingPricingHiveModel {
  @HiveField(0)
  final double basePrice;
  @HiveField(1)
  final double extraFees;
  @HiveField(2)
  final double discount;
  @HiveField(3)
  final double total;
  @HiveField(4)
  final Map<dynamic, dynamic>? metadata;

  const BookingPricingHiveModel({
    required this.basePrice,
    required this.extraFees,
    required this.discount,
    required this.total,
    this.metadata,
  });
}

@HiveType(typeId: HiveTypeIds.contact)
class ContactHiveModel {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final List<String> phone;

  const ContactHiveModel({
    required this.name,
    required this.phone,
  });
}
