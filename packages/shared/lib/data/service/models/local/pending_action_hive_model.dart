import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';

part 'pending_action_hive_model.g.dart';

/// Represents the type of operation pending sync to the remote.
class PendingActionType {
  static const String create = 'create';
  static const String update = 'update';
  static const String delete = 'delete';
}

/// Represents the type of entity the action targets.
class PendingEntityType {
  static const String mainService = 'mainService';
  static const String subService = 'subService';
}

@HiveType(typeId: HiveTypeIds.pendingAction)
class PendingActionHiveModel extends HiveObject {
  /// Unique identifier for this pending action (UUID).
  @HiveField(0)
  final String id;

  /// Type of operation: 'create', 'update', or 'delete'.
  @HiveField(1)
  final String actionType;

  /// Target entity: 'mainService' or 'subService'.
  @HiveField(2)
  final String entityType;

  /// JSON-encoded entity payload. Used for create/update.
  /// For delete, only the [entityId] is required.
  @HiveField(3)
  final String payload;

  /// The ID of the entity being acted upon.
  @HiveField(4)
  final String entityId;

  /// Required for subService operations — the parent main service ID.
  @HiveField(5)
  final String? mainServiceId;

  /// When the action was originally created (used for conflict checking).
  @HiveField(6)
  final DateTime createdAt;

  /// Number of failed sync attempts. Actions exceeding max retries are skipped.
  @HiveField(7)
  int retryCount;

  PendingActionHiveModel({
    required this.id,
    required this.actionType,
    required this.entityType,
    required this.payload,
    required this.entityId,
    required this.createdAt,
    this.mainServiceId,
    this.retryCount = 0,
  });
}
