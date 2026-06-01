import 'package:equatable/equatable.dart';
import 'package:shared/domain/service/entities/main_service_entity.dart';
import 'package:shared/domain/service/entities/service_entity.dart';
import '../home_domain.dart';

class HomeDataEntity extends Equatable{
  final List<MainServiceEntity> services;
  final List<SliderEntity> sliders;
  final List<ServiceEntity> popularServices;

  const HomeDataEntity({
    required this.services,
    required this.sliders,
    required this.popularServices,
  });

  @override
  List<Object?> get props => [services, sliders, popularServices];
}
