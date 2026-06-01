import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/data/service/models/local/service_hive_model.dart';
import 'package:shared/data/service/models/local/services_updated_hive_model.dart';
import 'package:shared/core/models/sync/sync_metadata_hive_model.dart';
import 'package:shared/core/error/exceptions.dart';

abstract class ServiceLocalDataSource {
  // Services
  Future<List<ServiceHiveModel>> getAllServices();
  Future<void> cacheServices(List<ServiceHiveModel> services);
  Future<void> cacheService(ServiceHiveModel service);
  Future<ServiceHiveModel?> getServiceById(String id);
  Future<void> deleteService(String id);
  Future<void> clearAndReopenServicesBox();

  // Sync Metadata
  Future<SyncMetadataHiveModel?> getSyncMetadata(String collectionName);
  Future<void> updateSyncMetadata(SyncMetadataHiveModel metadata);

  // Services Updated
  Future<void> cacheServicesUpdated(ServicesUpdatedHiveModel model);
  Future<ServicesUpdatedHiveModel?> getServicesUpdated();
}

class ServiceLocalDataSourceImpl implements ServiceLocalDataSource {
  Future<Box<ServiceHiveModel>> _openServiceBox() async {
    if (!Hive.isBoxOpen(HiveBoxNames.servicesBox)) {
      return await Hive.openBox<ServiceHiveModel>(HiveBoxNames.servicesBox);
    }
    return Hive.box<ServiceHiveModel>(HiveBoxNames.servicesBox);
  }

  Future<Box<SyncMetadataHiveModel>> _openSyncMetadataBox() async {
    if (!Hive.isBoxOpen(HiveBoxNames.syncMetadataBox)) {
      return await Hive.openBox<SyncMetadataHiveModel>(HiveBoxNames.syncMetadataBox);
    }
    return Hive.box<SyncMetadataHiveModel>(HiveBoxNames.syncMetadataBox);
  }

  Future<Box<ServicesUpdatedHiveModel>> _openServicesUpdatedBox() async {
    if (!Hive.isBoxOpen(HiveBoxNames.servicesUpdatedBox)) {
      return await Hive.openBox<ServicesUpdatedHiveModel>(HiveBoxNames.servicesUpdatedBox);
    }
    return Hive.box<ServicesUpdatedHiveModel>(HiveBoxNames.servicesUpdatedBox);
  }

  @override
  Future<List<ServiceHiveModel>> getAllServices() async {
    try {
      final box = await _openServiceBox();
      return box.values.toList();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheServices(List<ServiceHiveModel> services) async {
    print("=======🤍🤍🤍Hive 🟢🟢🟢 [ServiceLocalDataSourceImpl] ➔ Executing: cacheServices()");
    try {
      final box = await _openServiceBox();
      final Map<dynamic, ServiceHiveModel> entries = {
        for (var s in services) s.id: s,
      };
      await box.putAll(entries);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheService(ServiceHiveModel service) async {
    try {
      final box = await _openServiceBox();
      await box.put(service.id, service);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<ServiceHiveModel?> getServiceById(String id) async {
    try {
      final box = await _openServiceBox();
      return box.get(id);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> deleteService(String id) async {
    try {
      final box = await _openServiceBox();
      await box.delete(id);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> clearAndReopenServicesBox() async {
    try {
      if (Hive.isBoxOpen(HiveBoxNames.servicesBox)) {
        await Hive.box<ServiceHiveModel>(HiveBoxNames.servicesBox).close();
      }
      await Hive.deleteBoxFromDisk(HiveBoxNames.servicesBox);
      await Hive.openBox<ServiceHiveModel>(HiveBoxNames.servicesBox);
    } catch (e) {
      throw CacheException('Failed to clear and reopen servicesBox: $e');
    }
  }

  @override
  Future<SyncMetadataHiveModel?> getSyncMetadata(String collectionName) async {
    try {
      final box = await _openSyncMetadataBox();
      return box.get(collectionName);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> updateSyncMetadata(SyncMetadataHiveModel metadata) async {
    try {
      final box = await _openSyncMetadataBox();
      await box.put(metadata.collectionName, metadata);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheServicesUpdated(ServicesUpdatedHiveModel model) async {
    try {
      final box = await _openServicesUpdatedBox();
      await box.put('updates', model);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<ServicesUpdatedHiveModel?> getServicesUpdated() async {
    try {
      final box = await _openServicesUpdatedBox();
      return box.get('updates');
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
