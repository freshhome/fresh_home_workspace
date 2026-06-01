import 'package:equatable/equatable.dart';
import 'package:shared/domain/service/entities/sub_service_entity.dart';
import 'package:shared/core/error/failures.dart';

sealed class ServicesState extends Equatable {
  const ServicesState();

  @override
  List<Object?> get props => [];
}

final class ServicesInitial extends ServicesState {}

// States for Services List
final class ServicesListLoading extends ServicesState {}

final class ServicesListSuccess extends ServicesState {
  final List<SubServiceEntity> services;
  const ServicesListSuccess({required this.services});

  @override
  List<Object?> get props => [services];
}

final class ServicesListError extends ServicesState {
  final Failure failure;
  const ServicesListError({required this.failure});

  @override
  List<Object?> get props => [failure];
}

// States for Service Details
final class ServiceDetailsLoading extends ServicesState {}

final class ServiceDetailsSuccess extends ServicesState {
  final SubServiceEntity service;
  const ServiceDetailsSuccess({required this.service});

  @override
  List<Object?> get props => [service];
}

final class ServiceDetailsError extends ServicesState {
  final Failure failure;
  const ServiceDetailsError({required this.failure});

  @override
  List<Object?> get props => [failure];
}
