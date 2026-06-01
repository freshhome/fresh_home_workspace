part of 'supabase_services_cubit.dart';

abstract class SupabaseServicesState extends Equatable {
  const SupabaseServicesState();

  @override
  List<Object?> get props => [];
}

class SupabaseServicesInitial extends SupabaseServicesState {}

class SupabaseServicesLoading extends SupabaseServicesState {}

class SupabaseServicesLoaded extends SupabaseServicesState {
  final List<MainServiceEntity> mainServices;
  final List<SubServiceEntity>? subServices;
  final SubServiceEntity? selectedSubService;

  const SupabaseServicesLoaded({
    required this.mainServices,
    this.subServices,
    this.selectedSubService,
  });

  SupabaseServicesLoaded copyWith({
    List<MainServiceEntity>? mainServices,
    List<SubServiceEntity>? subServices,
    SubServiceEntity? selectedSubService,
  }) {
    return SupabaseServicesLoaded(
      mainServices: mainServices ?? this.mainServices,
      subServices: subServices ?? this.subServices,
      selectedSubService: selectedSubService ?? this.selectedSubService,
    );
  }

  @override
  List<Object?> get props => [mainServices, subServices, selectedSubService];
}

class SupabaseServicesError extends SupabaseServicesState {
  final String message;

  const SupabaseServicesError(this.message);

  @override
  List<Object?> get props => [message];
}
