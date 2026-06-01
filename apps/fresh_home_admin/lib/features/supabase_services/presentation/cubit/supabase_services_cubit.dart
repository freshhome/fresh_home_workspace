import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared/shared.dart';
import 'package:shared/data/service/datasources/service_remote_datasource.dart';

part 'supabase_services_state.dart';

class SupabaseServicesCubit extends Cubit<SupabaseServicesState> {
  final ServiceRemoteDataSource _supabaseDataSource;

  SupabaseServicesCubit(this._supabaseDataSource) : super(SupabaseServicesInitial());

  Future<void> loadMainServices() async {
    emit(SupabaseServicesLoading());
    try {
      final remoteModels = await _supabaseDataSource.getMainServices();
      final entities = remoteModels
          .map((m) => ServiceMapper.remoteToEntityMain(m))
          .toList();
      emit(SupabaseServicesLoaded(mainServices: entities));
    } catch (e) {
      emit(SupabaseServicesError(e.toString()));
    }
  }

  Future<void> loadSubServices(String mainServiceId) async {
    if (state is! SupabaseServicesLoaded) return;
    final currentState = state as SupabaseServicesLoaded;
    
    emit(SupabaseServicesLoading());
    try {
      final remoteModels = await _supabaseDataSource.getSubServices(
        mainServiceId: mainServiceId,
      );
      final entities = remoteModels
          .map((m) => ServiceMapper.remoteToEntitySub(m))
          .toList();
      emit(currentState.copyWith(subServices: entities));
    } catch (e) {
      emit(SupabaseServicesError(e.toString()));
    }
  }

  void selectSubService(SubServiceEntity subService) {
    if (state is! SupabaseServicesLoaded) return;
    final currentState = state as SupabaseServicesLoaded;
    emit(currentState.copyWith(selectedSubService: subService));
  }
}
