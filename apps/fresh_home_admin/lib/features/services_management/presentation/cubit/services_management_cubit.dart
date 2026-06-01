import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:shared/shared.dart';

part 'services_management_state.dart';

class ServicesManagementCubit extends Cubit<ServicesManagementState> {
  final GetRootServicesUseCase getRootServicesUseCase;
  final GetChildrenUseCase getChildrenUseCase;
  final AddServiceUseCase addServiceUseCase;
  final UpdateServiceUseCase updateServiceUseCase;

  ServicesManagementCubit({
    required this.getRootServicesUseCase,
    required this.getChildrenUseCase,
    required this.addServiceUseCase,
    required this.updateServiceUseCase,
  }) : super(ServicesManagementInitial());
  // ! تحميل الخدمات
  Future<void> loadServices({bool forceRefresh = false}) async {
    debugPrint(
      '🚀🚀🚀🚀 [ الكيوبت بتاع  الخدمات ServicesCubit] loadServices() triggered',
    );
    emit(ServicesManagementLoading());
    final result = await getRootServicesUseCase(forceRefresh: forceRefresh);
    if (isClosed) return;
    result.fold(
      (failure) {
        debugPrint(
          '❌❌❌❌ [ الكيوبت بتاع  الخدمات ServicesCubit] loadServices() فشل في تحميل البيانات: ${failure.message}',
        );
        emit(ServicesManagementError(failure.message));
      },
      (services) {
        debugPrint(
          '✅✅✅✅ [ الكيوبت بتاع  الخدمات ServicesCubit] loadServices() نجح في تحميل البيانات: Services count: ${services.length}',
        );
        emit(ServicesManagementLoaded(services));
      },
    );
  }

  // ! اضافه خدمه رئيسيه
  Future<void> addService(ServiceEntity data) async {
    emit(ServicesManagementLoading());
    final entity = data.copyWith(isBookable: false, parentId: null);
    final result = await addServiceUseCase(entity);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ServicesManagementError(failure.message)),
      (_) => loadServices(),
    );
  }

  // ! تحديث خدمه رئيسيه
  Future<void> updateService(ServiceEntity data) async {
    emit(ServicesManagementLoading());
    final entity = data.copyWith(isBookable: false, parentId: null);
    final result = await updateServiceUseCase(entity);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ServicesManagementError(failure.message)),
      (_) => loadServices(),
    );
  }

  // ! حذف خدمه رئيسيه
  Future<void> deleteService(ServiceEntity data) async {
    emit(ServicesManagementLoading());
    final entity = data.copyWith(status: ServiceStatus.archived);
    final result = await updateServiceUseCase(entity);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ServicesManagementError(failure.message)),
      (_) => loadServices(),
    );
  }

  // !  حذف متسلسل للخدمات
  Future<List<ServiceEntity>> _collectAllDescendants(String nodeId) async {
    final List<ServiceEntity> descendants = [];
    await _collectRecursive(nodeId, descendants);
    return descendants;
  }

  // !  حذف متسلسل للخدمات
  Future<void> _collectRecursive(
    String nodeId,
    List<ServiceEntity> descendants,
  ) async {
    final result = await getChildrenUseCase(nodeId);
    await result.fold((failure) async {}, (children) async {
      for (final child in children) {
        descendants.add(child);
        await _collectRecursive(child.id, descendants);
      }
    });
  }

  // ! حذف متسلسل للخدمات
  Future<void> cascadeDeleteService(String serviceId) async {
    emit(ServicesManagementLoading());

    final descendants = await _collectAllDescendants(serviceId);
    final List<Future<dynamic>> futures = [];

    for (final desc in descendants) {
      futures.add(
        updateServiceUseCase(desc.copyWith(status: ServiceStatus.archived)),
      );
    }

    ServiceEntity? targetEntity;
    final currentState = state;
    if (currentState is ServicesManagementLoaded) {
      try {
        targetEntity = currentState.services.firstWhere(
          (s) => s.id == serviceId,
        );
      } catch (_) {}
    }

    targetEntity ??= ServiceEntity(
      id: serviceId,
      parentId: null,
      isBookable: false,
      title: const {},
      description: const {},
      status: ServiceStatus.archived,
      updatedAt: DateTime.now(),
      order: 0,
    );

    futures.add(
      updateServiceUseCase(
        targetEntity.copyWith(status: ServiceStatus.archived),
      ),
    );

    final results = await Future.wait(futures);
    Failure? firstFailure;
    for (final res in results) {
      res.fold((failure) => firstFailure = failure, (_) {});
    }

    if (isClosed) return;
    if (firstFailure != null) {
      emit(ServicesManagementError(firstFailure!.message));
    } else {
      loadServices();
    }
  }

  // ! حذف مع تحويل المتسلسل
  Future<void> reassignAndDeleteService(
    String serviceId,
    String newParentId,
  ) async {
    emit(ServicesManagementLoading());

    final childrenResult = await getChildrenUseCase(serviceId);
    final List<Future<dynamic>> futures = [];

    await childrenResult.fold(
      (failure) async {
        emit(ServicesManagementError(failure.message));
      },
      (children) async {
        for (final child in children) {
          futures.add(
            updateServiceUseCase(
              child.copyWith(
                parentId: newParentId == 'root' ? null : newParentId,
              ),
            ),
          );
        }
      },
    );

    if (state is ServicesManagementError) return;

    ServiceEntity? targetEntity;
    final currentState = state;
    if (currentState is ServicesManagementLoaded) {
      try {
        targetEntity = currentState.services.firstWhere(
          (s) => s.id == serviceId,
        );
      } catch (_) {}
    }

    targetEntity ??= ServiceEntity(
      id: serviceId,
      parentId: null,
      isBookable: false,
      title: const {},
      description: const {},
      status: ServiceStatus.archived,
      updatedAt: DateTime.now(),
      order: 0,
    );

    futures.add(
      updateServiceUseCase(
        targetEntity.copyWith(status: ServiceStatus.archived),
      ),
    );

    final results = await Future.wait(futures);
    Failure? firstFailure;
    for (final res in results) {
      res.fold((failure) => firstFailure = failure, (_) {});
    }

    if (isClosed) return;
    if (firstFailure != null) {
      emit(ServicesManagementError(firstFailure!.message));
    } else {
      loadServices();
    }
  }
}
