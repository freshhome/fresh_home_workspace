import 'package:equatable/equatable.dart';

enum OrderStatus {
  created,
  pending,
  assigned,
  accepted,
  ready,
  onTheWay,
  arrived,
  inProgress,
  pendingInspection,
  completed,
  cancelled,
  failed,
  failedNoShow,
  expired,
}

class BookedService extends Equatable {
  final String id;
  final String subServiceId;
  final Map<String, String> name;
  final String image;

  const BookedService({
    required this.id,
    required this.subServiceId,
    required this.name,
    required this.image,
  });

  @override
  List<Object?> get props => [id, subServiceId, name, image];
}

class BookingPricing extends Equatable {
  final double basePrice;
  final double extraFees;
  final double discount;
  final double total;
  final Map<String, dynamic>? metadata;
  
  const BookingPricing({
    required this.basePrice,
    required this.extraFees,
    required this.discount,
    required this.total,
    this.metadata,
  });

  @override
  List<Object?> get props => [basePrice, extraFees, discount, total, metadata];
}

class Contact extends Equatable {
  final String name;
  final List<String> phone;

  const Contact({required this.name, required this.phone});

  @override
  List<Object?> get props => [name, phone];
}

class Schedule extends Equatable {
  final String day;
  final String time;

  const Schedule({
    required this.day,
    required this.time,
  });

  @override
  List<Object?> get props => [day, time];
}

class WindowDimension extends Equatable {
  final double width;
  final double height;
  final int quantity;
  final bool isBothSides;

  const WindowDimension({
    required this.width,
    required this.height,
    required this.quantity,
    this.isBothSides = false,
  });

  double get perimeter => 2 * (width + height) * quantity;
  double get multiplier => isBothSides ? 2.0 : 1.0;
  double get effectiveLinearMeters => perimeter * multiplier;

  WindowDimension copyWith({
    double? width,
    double? height,
    int? quantity,
    bool? isBothSides,
  }) {
    return WindowDimension(
      width: width ?? this.width,
      height: height ?? this.height,
      quantity: quantity ?? this.quantity,
      isBothSides: isBothSides ?? this.isBothSides,
    );
  }

  @override
  List<Object?> get props => [width, height, quantity, isBothSides];
}
