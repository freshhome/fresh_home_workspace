import 'package:shared/data/service/models/local/services_updated_hive_model.dart';
import 'package:shared/data/service/models/remote/services_updated_remote_model.dart';
import 'package:shared/domain/service/entities/services_updated/services_updated_entity.dart';

class ServicesUpdatedMapper {
  // Remote to Entity
  static ServicesUpdatedEntity remoteToEntity(
    ServicesUpdatedRemoteModel model,
  ) {
    return ServicesUpdatedEntity(
      lastUpdatedAt: model.lastUpdatedAt,
      services: model.services,
      subServices: model.subServices,
    );
  }

  // Hive to Entity
  static ServicesUpdatedEntity hiveToEntity(
    ServicesUpdatedHiveModel model,
  ) {
    return ServicesUpdatedEntity(
      lastUpdatedAt: model.lastUpdatedAt,
      services: model.services,
      subServices: model.subServices,
    );
  }

  // Entity to Remote
  static ServicesUpdatedRemoteModel entityToRemote(
    ServicesUpdatedEntity entity,
  ) {
    return ServicesUpdatedRemoteModel(
      lastUpdatedAt: entity.lastUpdatedAt,
      services: entity.services,
      subServices: entity.subServices,
    );
  }

  // Entity to Hive
  static ServicesUpdatedHiveModel entityToHive(
    ServicesUpdatedEntity entity,
  ) {
    return ServicesUpdatedHiveModel(
      lastUpdatedAt: entity.lastUpdatedAt,
      services: entity.services,
      subServices: entity.subServices,
    );
  }

  // Remote to Hive (for caching)
  static ServicesUpdatedHiveModel remoteToHive(
    ServicesUpdatedRemoteModel model,
  ) {
    return entityToHive(remoteToEntity(model));
  }
}
