import 'package:json_annotation/json_annotation.dart';

part 'booking_components_remote_model.g.dart';

@JsonSerializable()
class BookedServiceModel {
  final String id;
  final String subServiceId;
  final Map<String, String> name;
  final String image;

  const BookedServiceModel({
    required this.id,
    required this.subServiceId,
    required this.name,
    required this.image,
  });

  factory BookedServiceModel.fromJson(Map<String, dynamic> json) =>
      _$BookedServiceModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookedServiceModelToJson(this);
}

@JsonSerializable()
class BookingPricingModel {
  final double basePrice;
  final double extraFees;
  final double discount;
  final double total;

  const BookingPricingModel({
    required this.basePrice,
    required this.extraFees,
    required this.discount,
    required this.total,
  });

  factory BookingPricingModel.fromJson(Map<String, dynamic> json) =>
      _$BookingPricingModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookingPricingModelToJson(this);
}

@JsonSerializable()
class ContactModel {
  final String name;
  final List<String> phone;

  const ContactModel({
    required this.name,
    required this.phone,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) =>
      _$ContactModelFromJson(json);

  Map<String, dynamic> toJson() => _$ContactModelToJson(this);
}

@JsonSerializable()
class ScheduleModel {
  final String day;
  final String time;

  const ScheduleModel({
    required this.day,
    required this.time,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduleModelFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleModelToJson(this);
}

