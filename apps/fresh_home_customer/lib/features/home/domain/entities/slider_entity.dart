import 'package:equatable/equatable.dart';

class SliderEntity extends Equatable {
  final String image;
  final String serviceId;
  final int order;

  const SliderEntity({
    required this.image,
    required this.serviceId,
    required this.order,
  });

  @override
  List<Object?> get props => [image, serviceId, order];
}
