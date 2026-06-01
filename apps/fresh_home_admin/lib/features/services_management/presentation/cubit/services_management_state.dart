part of 'services_management_cubit.dart';

abstract class ServicesManagementState extends Equatable {
  const ServicesManagementState();

  @override
  List<Object> get props => [];
}

class ServicesManagementInitial extends ServicesManagementState {}

class ServicesManagementLoading extends ServicesManagementState {}

class ServicesManagementLoaded extends ServicesManagementState {
  final List<ServiceEntity> services;

  const ServicesManagementLoaded(this.services);

  @override
  List<Object> get props => [services];
}

class ServicesManagementError extends ServicesManagementState {
  final String message;

  const ServicesManagementError(this.message);

  @override
  List<Object> get props => [message];
}
