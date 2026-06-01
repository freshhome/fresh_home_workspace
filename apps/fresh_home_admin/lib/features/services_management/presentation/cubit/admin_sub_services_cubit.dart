import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared/shared.dart';



part 'admin_sub_services_state.dart';

class AdminSubServicesCubit extends Cubit<AdminSubServicesState> {
  final GetChildrenUseCase getChildrenUseCase;
  final AddServiceUseCase addServiceUseCase;
  final UpdateServiceUseCase updateServiceUseCase;

  AdminSubServicesCubit({
    required this.getChildrenUseCase,
    required this.addServiceUseCase,
    required this.updateServiceUseCase,
  }) : super(AdminSubServicesInitial());

  Future<void> loadSubServices(String categoryId) async {
    emit(AdminSubServicesLoading());
    final result = await getChildrenUseCase.call(categoryId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(AdminSubServicesError(failure.message)),
      (services) {
        final subServices = services.map((s) => ServiceMapper.serviceToSubServiceEntity(s)).toList();
        emit(AdminSubServicesLoaded(subServices));
      },
    );
  }

  Future<void> addSubService(String categoryId, SubServiceEntity data) async {
    emit(AdminSubServicesLoading());
    final entity = data.copyWith(
      parentId: data.parentId ?? categoryId,
    );
    final result = await addServiceUseCase(entity);
    if (isClosed) return;
    result.fold(
      (failure) => emit(AdminSubServicesError(failure.message)),
      (_) => loadSubServices(categoryId),
    );
  }

  Future<void> updateSubService(
    String categoryId,
    String subServiceId,
    SubServiceEntity data,
  ) async {
    emit(AdminSubServicesLoading());
    final result = await updateServiceUseCase(data);
    if (isClosed) return;
    result.fold(
      (failure) => emit(AdminSubServicesError(failure.message)),
      (_) => loadSubServices(categoryId),
    );
  }

  Future<void> deleteSubService(String categoryId, String subServiceId) async {
    emit(AdminSubServicesLoading());
    
    ServiceEntity? targetEntity;
    final currentState = state;
    if (currentState is AdminSubServicesLoaded) {
      try {
        targetEntity = currentState.subServices.firstWhere((s) => s.id == subServiceId);
      } catch (_) {}
    }

    targetEntity ??= SubServiceEntity(
      id: subServiceId,
      parentId: categoryId,
      isBookable: true,
      title: const {},
      description: const {},
      status: ServiceStatus.archived,
      updatedAt: DateTime.now(),
      order: 0,
      price: const PriceEntity(type: PricingMethod.fixed, value: 0, unit: '', options: []),
      details: const [],
      notIncluded: const NotIncludedEntity(
        ar: LanguageContentEntity(title: '', icon: '', points: []),
        en: LanguageContentEntity(title: '', icon: '', points: []),
      ),
    );

    final archivedEntity = targetEntity.copyWith(status: ServiceStatus.archived);
    final result = await updateServiceUseCase(archivedEntity);
    
    if (isClosed) return;
    result.fold(
      (failure) => emit(AdminSubServicesError(failure.message)),
      (_) => loadSubServices(categoryId),
    );
  }

  Future<List<ServiceEntity>> _collectAllDescendants(String nodeId) async {
    final List<ServiceEntity> descendants = [];
    await _collectRecursive(nodeId, descendants);
    return descendants;
  }

  Future<void> _collectRecursive(String nodeId, List<ServiceEntity> descendants) async {
    final result = await getChildrenUseCase(nodeId);
    await result.fold(
      (failure) async {},
      (children) async {
        for (final child in children) {
          descendants.add(child);
          await _collectRecursive(child.id, descendants);
        }
      },
    );
  }

  Future<void> cascadeDeleteSubService(String categoryId, String subServiceId) async {
    emit(AdminSubServicesLoading());

    final descendants = await _collectAllDescendants(subServiceId);
    final List<Future<dynamic>> futures = [];

    for (final desc in descendants) {
      futures.add(updateServiceUseCase(desc.copyWith(status: ServiceStatus.archived)));
    }

    ServiceEntity? targetEntity;
    final currentState = state;
    if (currentState is AdminSubServicesLoaded) {
      try {
        targetEntity = currentState.subServices.firstWhere((s) => s.id == subServiceId);
      } catch (_) {}
    }

    targetEntity ??= SubServiceEntity(
      id: subServiceId,
      parentId: categoryId,
      isBookable: true,
      title: const {},
      description: const {},
      status: ServiceStatus.archived,
      updatedAt: DateTime.now(),
      order: 0,
      price: const PriceEntity(type: PricingMethod.fixed, value: 0, unit: '', options: []),
      details: const [],
      notIncluded: const NotIncludedEntity(
        ar: LanguageContentEntity(title: '', icon: '', points: []),
        en: LanguageContentEntity(title: '', icon: '', points: []),
      ),
    );

    futures.add(updateServiceUseCase(targetEntity.copyWith(status: ServiceStatus.archived)));

    final results = await Future.wait(futures);
    Failure? firstFailure;
    for (final res in results) {
      res.fold((failure) => firstFailure = failure, (_) {});
    }

    if (isClosed) return;
    if (firstFailure != null) {
      emit(AdminSubServicesError(firstFailure!.message));
    } else {
      loadSubServices(categoryId);
    }
  }

  Future<void> reassignAndDeleteSubService(
    String categoryId,
    String subServiceId,
    String newParentId,
  ) async {
    emit(AdminSubServicesLoading());

    final childrenResult = await getChildrenUseCase(subServiceId);
    final List<Future<dynamic>> futures = [];
    
    await childrenResult.fold(
      (failure) async {
        emit(AdminSubServicesError(failure.message));
      },
      (children) async {
        for (final child in children) {
          futures.add(updateServiceUseCase(child.copyWith(parentId: newParentId == 'root' ? null : newParentId)));
        }
      },
    );

    if (state is AdminSubServicesError) return;

    ServiceEntity? targetEntity;
    final currentState = state;
    if (currentState is AdminSubServicesLoaded) {
      try {
        targetEntity = currentState.subServices.firstWhere((s) => s.id == subServiceId);
      } catch (_) {}
    }

    targetEntity ??= SubServiceEntity(
      id: subServiceId,
      parentId: categoryId,
      isBookable: true,
      title: const {},
      description: const {},
      status: ServiceStatus.archived,
      updatedAt: DateTime.now(),
      order: 0,
      price: const PriceEntity(type: PricingMethod.fixed, value: 0, unit: '', options: []),
      details: const [],
      notIncluded: const NotIncludedEntity(
        ar: LanguageContentEntity(title: '', icon: '', points: []),
        en: LanguageContentEntity(title: '', icon: '', points: []),
      ),
    );

    futures.add(updateServiceUseCase(targetEntity.copyWith(status: ServiceStatus.archived)));

    final results = await Future.wait(futures);
    Failure? firstFailure;
    for (final res in results) {
      res.fold((failure) => firstFailure = failure, (_) {});
    }

    if (isClosed) return;
    if (firstFailure != null) {
      emit(AdminSubServicesError(firstFailure!.message));
    } else {
      loadSubServices(categoryId);
    }
  }
}

