import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/core/network/network_info.dart';
import 'package:shared/core/models/sync/sync_metadata_hive_model.dart';
import 'package:shared/data/service/models/local/service_hive_model.dart';
import 'package:shared/domain/service/entities/service_entity.dart';
import 'package:shared/domain/service/entities/main_service_entity.dart';
import 'package:shared/domain/service/entities/sub_service_entity.dart';
import 'package:shared/domain/service/entities/service.dart';
import 'package:shared/domain/service/enums/service_status.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';
import 'package:shared/domain/technician/entities/technician.dart';
import '../../../domain/service/entities/sub_entities/shared_icon_entity.dart';
import '../models/remote/sub_models/shared_icon_remote_model.dart';
import '../datasources/service_local_datasource.dart';
import '../datasources/service_pending_action_datasource.dart';
import '../datasources/service_realtime_sync_datasource.dart';
import '../datasources/service_remote_datasource.dart';
import '../mappers/service_mapper.dart';
import '../models/remote/service_remote_model.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource remoteDataSource;
  final ServiceLocalDataSource localDataSource;
  final ServicePendingActionDataSource pendingActionDataSource;
  final ServiceRealtimeSyncDataSource realtimeSyncDataSource;
  final NetworkInfo networkInfo;

  // In-memory Tree Cache
  List<ServiceEntity> _allServices = [];
  final Map<String?, List<ServiceEntity>> _adjacencyList = {};
  final List<ServiceEntity> _bookableServices = [];

  Timer? _watcherDebounce;

  ServiceRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.pendingActionDataSource,
    required this.realtimeSyncDataSource,
    required this.networkInfo,
  }) {
    // Listen to changes in local box to keep in-memory cache synchronized reactively
    Hive.box<ServiceHiveModel>(HiveBoxNames.servicesBox).watch().listen((_) {
      _watcherDebounce?.cancel();
      _watcherDebounce = Timer(const Duration(milliseconds: 100), () {
        _reloadCacheAndRebuildTree();
      });
    });
  }

  Future<void> _reloadCacheAndRebuildTree() async {
    try {
      final localModels = await localDataSource.getAllServices();
      _allServices = localModels
          .map((m) => ServiceMapper.hiveToEntity(m))
          .toList();
      _buildTreeCache();
    } catch (e) {
      print('❌ [ServiceRepository] Reactive cache reload error: $e');
    }
  }

  Future<void> _loadCacheIfNeeded() async {
    if (_allServices.isNotEmpty) return;
    try {
      final localModels = await localDataSource.getAllServices();
      _allServices = localModels
          .map((m) => ServiceMapper.hiveToEntity(m))
          .toList();
      _buildTreeCache();
    } catch (e) {
      print(
        '⚠️ Local cache read failed (possible corruption): $e. Attempting self-healing...',
      );
      await _healCorruptedCache();
    }
  }

  Future<void> _healCorruptedCache() async {
    try {
      await localDataSource.clearAndReopenServicesBox();
      // Wipe last sync metadata
      await localDataSource.updateSyncMetadata(
        SyncMetadataHiveModel(
          collectionName: 'services',
          lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
      _allServices = [];
      _buildTreeCache();
      // Trigger full sync
      await syncAllServices(forceFull: true);
    } catch (e) {
      print('❌ Self-healing failed: $e');
    }
  }

  void _buildTreeCache() {
    _adjacencyList.clear();
    _bookableServices.clear();

    // Sort all services by order
    _allServices.sort((a, b) => a.order.compareTo(b.order));

    for (final service in _allServices) {
      // Local Filtering: Ensure ALL app logic only uses services where status == 'active'
      if (service.status != ServiceStatus.active) {
        continue;
      }

      if (service.isBookable) {
        _bookableServices.add(service);
      }

      final parentId = service.parentId;
      if (!_adjacencyList.containsKey(parentId)) {
        _adjacencyList[parentId] = [];
      }
      _adjacencyList[parentId]!.add(service);
    }
  }

  // --- Legacy Queries Implementation ---
  @override
  Stream<Either<Failure, List<MainServiceEntity>>> getMainServices() async* {
    try {
      await _loadCacheIfNeeded();
      final roots = (_adjacencyList[null] ?? []).where((root) => !root.isBookable).toList();
      final mainServices = roots.map((root) {
        final children = _adjacencyList[root.id] ?? [];
        return ServiceMapper.serviceToMainServiceEntity(root, children);
      }).toList();
      yield Right(mainServices);

      // Attempt background sync if online, then yield updated roots
      if (await networkInfo.isConnected) {
        try {
          await syncAllServices();
          final updatedRoots = (_adjacencyList[null] ?? []).where((root) => !root.isBookable).toList();
          final updatedMainServices = updatedRoots.map((root) {
            final children = _adjacencyList[root.id] ?? [];
            return ServiceMapper.serviceToMainServiceEntity(root, children);
          }).toList();
          yield Right(updatedMainServices);
        } catch (_) {}
      }
    } catch (e) {
      yield Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MainServiceEntity>> getMainServiceById(
    String id,
  ) async {
    try {
      await _loadCacheIfNeeded();
      final service = _allServices.firstWhere((s) => s.id == id);
      final children = _adjacencyList[id] ?? [];
      return Right(ServiceMapper.serviceToMainServiceEntity(service, children));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SubServiceEntity>>> getSubServices(
    String mainServiceId,
  ) async {
    try {
      await _loadCacheIfNeeded();
      final children = _adjacencyList[mainServiceId] ?? [];
      return Right(
        children
            .map((c) => ServiceMapper.serviceToSubServiceEntity(c))
            .toList(),
      );
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SubServiceEntity>> getSubServiceById(
    String id, {
    required bool forceRemote,
    required String mainServiceId,
    required String subServiceId,
  }) async {
    final result = await getServiceById(id, forceRefresh: forceRemote);
    return result.map((s) => ServiceMapper.serviceToSubServiceEntity(s));
  }

  @override
  Future<Either<Failure, List<MainServiceEntity>>> searchServices(
    String query,
  ) async {
    try {
      await _loadCacheIfNeeded();
      final roots = _adjacencyList[null] ?? [];
      final filtered = roots
          .where(
            (s) => s.title.values.any(
              (v) => v.toLowerCase().contains(query.toLowerCase()),
            ),
          )
          .toList();
      return Right(
        filtered
            .map(
              (r) => ServiceMapper.serviceToMainServiceEntity(
                r,
                _adjacencyList[r.id] ?? [],
              ),
            )
            .toList(),
      );
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceEntity>>> getRootServices({
    bool forceRefresh = false,
  }) async {
    try {
      if (forceRefresh) {
        await syncAllServices(forceFull: true);
      } else {
        await _loadCacheIfNeeded();
        final hasConnection = await networkInfo.isConnected;
        print('🌐 [ServiceRepository] getRootServices: cache size is ${_allServices.length}, hasConnection: $hasConnection');
        if (_allServices.isEmpty && hasConnection) {
          print('🌐 [ServiceRepository] Local cache is empty on load. Triggering automatic background sync...');
          final syncResult = await syncAllServices();
          syncResult.fold(
            (failure) => print('⚠️ [ServiceRepository] Automatic sync failed: ${failure.message}'),
            (_) => print('✅ [ServiceRepository] Automatic sync completed successfully.'),
          );
        }
      }
      return Right(_adjacencyList[null] ?? []);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceEntity>>> getChildren(
    String parentId, {
    bool forceRefresh = false,
  }) async {
    try {
      if (forceRefresh) {
        await syncAllServices(forceFull: true);
      } else {
        await _loadCacheIfNeeded();
      }
      return Right(_adjacencyList[parentId] ?? []);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceEntity>>> getBookableServices({
    bool forceRefresh = false,
  }) async {
    try {
      if (forceRefresh) {
        await syncAllServices(forceFull: true);
      } else {
        await _loadCacheIfNeeded();
      }
      return Right(_bookableServices);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceEntity>> getServiceById(
    String id, {
    bool forceRefresh = false,
  }) async {
    try {
      if (forceRefresh && await networkInfo.isConnected) {
        final remoteModel = await remoteDataSource.getServiceById(id);
        final hiveModel = ServiceMapper.remoteToHive(remoteModel);
        await localDataSource.cacheService(hiveModel);

        final entity = ServiceMapper.remoteToEntity(remoteModel);

        await _loadCacheIfNeeded();
        _allServices.removeWhere((s) => s.id == id);
        _allServices.add(entity);
        _buildTreeCache();

        return Right(entity);
      } else {
        await _loadCacheIfNeeded();
      }

      final service = _allServices.firstWhere(
        (s) => s.id == id,
        orElse: () => throw Exception('Service not found in cache'),
      );
      return Right(service);
    } catch (e) {
      // Fallback: try remote fetch directly if online
      try {
        if (await networkInfo.isConnected) {
          final remoteModel = await remoteDataSource.getServiceById(id);
          final hiveModel = ServiceMapper.remoteToHive(remoteModel);
          await localDataSource.cacheService(hiveModel);

          final entity = ServiceMapper.remoteToEntity(remoteModel);

          _allServices.removeWhere((s) => s.id == id);
          _allServices.add(entity);
          _buildTreeCache();

          return Right(entity);
        }
      } catch (_) {}
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceEntity>> addService(
    ServiceEntity service,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteModel = ServiceMapper.entityToRemote(service);
        final resultModel = await remoteDataSource.insertService(remoteModel);
        final hiveModel = ServiceMapper.remoteToHive(resultModel);
        await localDataSource.cacheService(hiveModel);

        final entity = ServiceMapper.remoteToEntity(resultModel);

        // Update in-memory cache
        _allServices.removeWhere((s) => s.id == entity.id);
        _allServices.add(entity);
        _buildTreeCache();

        return Right(entity);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ServiceEntity>> updateService(
    ServiceEntity service,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteModel = ServiceMapper.entityToRemote(service);
        final resultModel = await remoteDataSource.updateService(remoteModel);
        final hiveModel = ServiceMapper.remoteToHive(resultModel);
        await localDataSource.cacheService(hiveModel);

        final entity = ServiceMapper.remoteToEntity(resultModel);

        // Update in-memory cache
        _allServices.removeWhere((s) => s.id == entity.id);
        _allServices.add(entity);
        _buildTreeCache();

        return Right(entity);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  // ! مزامنة كل الخدمات
  @override
  Future<Either<Failure, bool>> syncAllServices({
    bool forceFull = false,
  }) async {
    final hasConnection = await networkInfo.isConnected;
    print('🌐 [ServiceRepository] syncAllServices: forceFull: $forceFull, hasConnection: $hasConnection');
    if (hasConnection) {
      try {
        final syncMetadata = await localDataSource.getSyncMetadata('services');
        final localServices = await localDataSource.getAllServices();
        final isLocalCacheEmpty = localServices.isEmpty;
        final lastSync = (forceFull || isLocalCacheEmpty) ? null : syncMetadata?.lastUpdatedAt;

        List<ServiceRemoteModel> remoteModels;
        if (lastSync == null) {
          print('🌐 [ServiceRepository] Doing FULL fetch from services (forceFull: $forceFull, isLocalCacheEmpty: $isLocalCacheEmpty)...');
          if (forceFull || isLocalCacheEmpty) {
            await localDataSource.clearAndReopenServicesBox();
          }
          remoteModels = await remoteDataSource.getServices();
        } else {
          print(
            '🌐 [ServiceRepository] Doing INCREMENTAL fetch since $lastSync...',
          );
          remoteModels = await remoteDataSource.getServicesUpdatedSince(
            lastSync,
          );
        }

        print(
          '✅ [ServiceRepository] Fetched ${remoteModels.length} services from remote.',
        );

        if (remoteModels.isNotEmpty) {
          final List<ServiceHiveModel> toCache = [];
          final List<String> toDelete = [];

          for (final m in remoteModels) {
            if (m.status == ServiceStatus.archived) {
              toDelete.add(m.id);
            } else {
              toCache.add(ServiceMapper.remoteToHive(m));
            }
          }

          if (toCache.isNotEmpty) {
            await localDataSource.cacheServices(toCache);
          }
          for (final id in toDelete) {
            await localDataSource.deleteService(id);
          }

          // Calculate max(updated_at) from fetched records to avoid client clock skew
          final maxUpdatedAt = remoteModels
              .map((m) => m.updatedAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);

          await localDataSource.updateSyncMetadata(
            SyncMetadataHiveModel(
              collectionName: 'services',
              lastUpdatedAt: maxUpdatedAt.toUtc(),
            ),
          );
        }

        // --- LAYER 2: Lightweight Active-ID Integrity Check ---
        // Run periodic active ID validation to detect hard deletions or missed status updates.
        // We only run this if not doing a full fetch and if the 24-hour interval has passed.
        if (lastSync != null) {
          final integrityMetadata = await localDataSource.getSyncMetadata(
            'services_integrity_check',
          );
          final lastIntegrityCheck = integrityMetadata?.lastUpdatedAt;
          final now = DateTime.now();

          if (lastIntegrityCheck == null ||
              now.difference(lastIntegrityCheck).inHours >= 24) {
            print(
              '🌐 [ServiceRepository] Running periodic Lightweight Active-ID Integrity Check...',
            );
            try {
              final remoteActiveIds = await remoteDataSource
                  .getActiveServiceIds();
              final localServices = await localDataSource.getAllServices();
              final localIds = localServices.map((s) => s.id).toSet();
              final remoteActiveIdsSet = remoteActiveIds.toSet();

              // Find orphaned local IDs (cached locally but not active/present on the server)
              final orphanedIds = localIds.difference(remoteActiveIdsSet);
              if (orphanedIds.isNotEmpty) {
                print(
                  '🗑️ [ServiceRepository] Purging ${orphanedIds.length} orphaned/deleted service IDs from local cache.',
                );
                for (final id in orphanedIds) {
                  await localDataSource.deleteService(id);
                }
              }

              // Find missing local IDs (active on server but not cached locally)
              final missingIds = remoteActiveIdsSet.difference(localIds);
              if (missingIds.isNotEmpty) {
                print(
                  '🌐 [ServiceRepository] Missing ${missingIds.length} active service IDs locally. Requesting full resync next run.',
                );
                await localDataSource.updateSyncMetadata(
                  SyncMetadataHiveModel(
                    collectionName: 'services',
                    lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(0),
                  ),
                );
              }

              // Update integrity check timestamp
              await localDataSource.updateSyncMetadata(
                SyncMetadataHiveModel(
                  collectionName: 'services_integrity_check',
                  lastUpdatedAt: now,
                ),
              );
            } catch (e) {
              print(
                '⚠️ [ServiceRepository] Lightweight Integrity Check failed: $e',
              );
            }
          }
        }

        // Re-load cache into memory
        final localModels = await localDataSource.getAllServices();
        _allServices = localModels
            .map((m) => ServiceMapper.hiveToEntity(m))
            .toList();
        _buildTreeCache();

        return const Right(true);
      } catch (e) {
        print('❌ [ServiceRepository] syncAllServices Error: $e');
        return Left(ServerFailure(message: e.toString()));
      }
    }
    return Left(NetworkFailure(message: 'No internet connection'));
  }

  @override
  Future<Either<Failure, Unit>> startRealtimeSync() async {
    realtimeSyncDataSource.startSync();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> stopRealtimeSync() async {
    realtimeSyncDataSource.stopSync();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<ServiceAvailability>>> getAvailability(
    String subServiceId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final availability = await remoteDataSource.getAvailability(
          subServiceId,
        );
        return Right(availability);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    }
    return Left(NetworkFailure(message: 'No internet connection'));
  }

  @override
  Future<Either<Failure, List<Technician>>> getTechnicians() async {
    if (await networkInfo.isConnected) {
      try {
        final technicians = await remoteDataSource.getTechnicians();
        return Right(technicians);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    }
    return Left(NetworkFailure(message: 'No internet connection'));
  }

  @override
  Future<Either<Failure, List<Technician>>> getTechniciansForService(
    String subServiceId,
  ) async {
    try {
      final technicians = await remoteDataSource.getTechniciansForService(
        subServiceId,
      );
      return Right(technicians);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> calculatePrice({
    required String subServiceId,
    required Map<String, dynamic> formValues,
    required List<String> selectedOptions,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final price = await remoteDataSource.calculatePrice(
          subServiceId: subServiceId,
          formValues: formValues,
          selectedOptions: selectedOptions,
        );
        return Right(price);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    }
    return Left(NetworkFailure(message: 'No internet connection'));
  }

  @override
  Future<Either<Failure, MainServiceEntity>> addMainService(
    MainServiceEntity service,
  ) async {
    final result = await addService(service);
    return result.map((s) => ServiceMapper.serviceToMainServiceEntity(s, []));
  }

  @override
  Future<Either<Failure, MainServiceEntity>> updateMainService(
    MainServiceEntity service,
  ) async {
    final result = await updateService(service);
    return result.map((s) => ServiceMapper.serviceToMainServiceEntity(s, []));
  }

  @override
  Future<Either<Failure, Unit>> deleteMainService(
    String id, {
    required MainServiceEntity mainService,
  }) async {
    return const Right(unit);
  }

  @override
  Future<Either<Failure, SubServiceEntity>> addSubService(
    SubServiceEntity subService,
    String mainServiceId,
  ) async {
    final service = subService.copyWith(parentId: mainServiceId);
    final result = await addService(service);
    return result.map((s) => ServiceMapper.serviceToSubServiceEntity(s));
  }

  @override
  Future<Either<Failure, SubServiceEntity>> updateSubService(
    SubServiceEntity service,
  ) async {
    final result = await updateService(service);
    return result.map((s) => ServiceMapper.serviceToSubServiceEntity(s));
  }

  @override
  Future<Either<Failure, Unit>> deleteSubService(String id) async {
    return const Right(unit);
  }

  @override
  Future<Either<Failure, String>> uploadServiceImage({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    String? serviceId,
    bool isTemp = false,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final url = await remoteDataSource.uploadServiceImage(
          bytes: bytes,
          fileName: fileName,
          mimeType: mimeType,
          serviceId: serviceId,
          isTemp: isTemp,
        );
        return Right(url);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    }
    return Left(NetworkFailure(message: 'لا يوجد اتصال بالإنترنت'));
  }

  @override
  Future<Either<Failure, void>> deleteServiceImage(String imageUrl) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteServiceImage(imageUrl);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    }
    return Left(NetworkFailure(message: 'لا يوجد اتصال بالإنترنت'));
  }

  @override
  Future<Either<Failure, List<SharedIconEntity>>> getSharedIcons() async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getSharedIcons();
        final entities = models.map((m) => m.toEntity()).toList();
        return Right(entities);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    }
    return Left(NetworkFailure(message: 'لا يوجد اتصال بالإنترنت'));
  }

  @override
  Future<Either<Failure, SharedIconEntity>> insertSharedIcon(SharedIconEntity icon) async {
    if (await networkInfo.isConnected) {
      try {
        final model = SharedIconRemoteModel.fromEntity(icon);
        final resultModel = await remoteDataSource.insertSharedIcon(model);
        return Right(resultModel.toEntity());
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    }
    return Left(NetworkFailure(message: 'لا يوجد اتصال بالإنترنت'));
  }

  @override
  Future<Either<Failure, void>> deleteSharedIcon(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteSharedIcon(id);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    }
    return Left(NetworkFailure(message: 'لا يوجد اتصال بالإنترنت'));
  }
}
