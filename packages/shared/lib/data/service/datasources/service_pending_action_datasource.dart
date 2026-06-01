import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/data/service/models/local/pending_action_hive_model.dart';

abstract class ServicePendingActionDataSource {
  /// Append a new pending action to the queue.
  Future<void> enqueue(PendingActionHiveModel action);

  /// Return all pending actions sorted by createdAt (FIFO).
  Future<List<PendingActionHiveModel>> getAll();

  /// Remove a successfully processed action.
  Future<void> remove(String actionId);

  /// Increment the retry counter for a failed action.
  Future<void> incrementRetry(String actionId);

  /// Remove all pending actions (for reset/testing).
  Future<void> clearAll();
}

class ServicePendingActionDataSourceImpl
    implements ServicePendingActionDataSource {
  Future<Box<PendingActionHiveModel>> _openBox() async {
    if (!Hive.isBoxOpen(HiveBoxNames.pendingActionsBox)) {
      return await Hive.openBox<PendingActionHiveModel>(
        HiveBoxNames.pendingActionsBox,
      );
    }
    return Hive.box<PendingActionHiveModel>(HiveBoxNames.pendingActionsBox);
  }

  @override
  Future<void> enqueue(PendingActionHiveModel action) async {
    final box = await _openBox();
    await box.put(action.id, action);
    print('========= 📥 [PendingQueue] Enqueued ${action.actionType} ${action.entityType} id:${action.entityId}');
  }

  @override
  Future<List<PendingActionHiveModel>> getAll() async {
    final box = await _openBox();
    final actions = box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return actions;
  }

  @override
  Future<void> remove(String actionId) async {
    final box = await _openBox();
    await box.delete(actionId);
    print('========= ✅ [PendingQueue] Removed action id:$actionId');
  }

  @override
  Future<void> incrementRetry(String actionId) async {
    final box = await _openBox();
    final action = box.get(actionId);
    if (action != null) {
      action.retryCount++;
      await box.put(actionId, action);
    }
  }

  @override
  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
    print('========= 🧹 [PendingQueue] Cleared all pending actions');
  }
}
