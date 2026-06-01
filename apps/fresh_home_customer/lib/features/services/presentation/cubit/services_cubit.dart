import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/service/use_cases/service/get_main_services_use_case.dart';
import 'package:shared/domain/service/use_cases/service/get_sub_services_use_case.dart';
import 'package:shared/domain/service/use_cases/service/get_sub_service_by_id_use_case.dart';
import 'package:fresh_home_customer/features/services/presentation/cubit/services_state.dart';

class ServicesCubit extends Cubit<ServicesState> {
  final GetMainServicesUseCase getMainServicesUseCase;
  final GetSubServicesUseCase getSubServicesUseCase;
  final GetSubServiceByIdUseCase getSubServiceByIdUseCase;

  ServicesCubit({
    required this.getMainServicesUseCase,
    required this.getSubServicesUseCase,
    required this.getSubServiceByIdUseCase,
  }) : super(ServicesInitial());

  Future<void> getServices(String mainServiceId, {bool forceRemote = false}) async {
    emit(ServicesListLoading());
    final result = await getSubServicesUseCase.call(
      mainServiceId: mainServiceId,
      forceRemote: forceRemote,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(ServicesListError(failure: failure)),
      (services) => emit(ServicesListSuccess(services: services)),
    );
  }

  Future<void> getServiceDetails({
    required String subserviceId,
    required String mainServiceId,
    bool forceRemote = false,
  }) async {
    emit(ServiceDetailsLoading());
    final result = await getSubServiceByIdUseCase(
      subServiceId: subserviceId,
      mainServiceId: mainServiceId,
      forceRemote: forceRemote,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(ServiceDetailsError(failure: failure)),
      (service) => emit(ServiceDetailsSuccess(service: service)),
    );
  }
}
