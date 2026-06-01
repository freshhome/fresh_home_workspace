part of 'admin_sub_services_cubit.dart';

abstract class AdminSubServicesState extends Equatable {
  const AdminSubServicesState();

  @override
  List<Object> get props => [];
}

class AdminSubServicesInitial extends AdminSubServicesState {}

class AdminSubServicesLoading extends AdminSubServicesState {}

class AdminSubServicesLoaded extends AdminSubServicesState {
  final List<SubServiceEntity> subServices;

  const AdminSubServicesLoaded(this.subServices);

  @override
  List<Object> get props => [subServices];
}

class AdminSubServicesError extends AdminSubServicesState {
  final String message;

  const AdminSubServicesError(this.message);

  @override
  List<Object> get props => [message];
}
