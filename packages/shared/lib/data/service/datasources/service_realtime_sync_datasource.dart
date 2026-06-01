import 'dart:async';

import 'package:shared/data/service/datasources/service_local_datasource.dart';
import 'package:shared/data/service/datasources/service_pending_action_datasource.dart';
import 'package:shared/data/service/mappers/service_mapper.dart';
import 'package:shared/data/service/models/remote/service_remote_model.dart';
import 'package:shared/domain/service/enums/service_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages Supabase realtime subscriptions for the unified services table.
///
/// **Prerequisites (run once in Supabase SQL editor):**
/// ```sql
/// ALTER TABLE public.services REPLICA IDENTITY FULL;
/// ```
/// Also enable Realtime for the table in:
/// Dashboard → Database → Replication → Supabase Realtime.
abstract class ServiceRealtimeSyncDataSource {
  /// Start listening to live database changes.
  void startSync();

  /// Unsubscribe from all realtime channels and dispose resources.
  void stopSync();
}

class ServiceRealtimeSyncDataSourceImpl
    implements ServiceRealtimeSyncDataSource {
  final SupabaseClient _supabase;
  final ServiceLocalDataSource _localDataSource;
  final ServicePendingActionDataSource _pendingActionDataSource;

  RealtimeChannel? _channel;

  /// Debounce timers keyed by entity ID to collapse rapid bursts.
  final Map<String, Timer> _debounceTimers = {};

  /// Debounce window for rapid update bursts.
  static const _debounceDuration = Duration(milliseconds: 300);

  ServiceRealtimeSyncDataSourceImpl({
    required SupabaseClient supabase,
    required ServiceLocalDataSource localDataSource,
    required ServicePendingActionDataSource pendingActionDataSource,
  })  : _supabase = supabase,
        _localDataSource = localDataSource,
        _pendingActionDataSource = pendingActionDataSource;

  @override
  void startSync() {
    stopSync(); // ensure clean state

    _channel = _supabase
        .channel('services_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'services',
          callback: _handleServiceEvent,
        )
        .subscribe((status, [error]) {
      if (error != null) {
        print('========= 🔴 [Realtime] Subscription error: $error');
      } else {
        print('========= 📡 [Realtime] Channel status: $status');
      }
    });

    print('========= 📡 [Realtime] Subscribed to unified services.');
  }

  @override
  void stopSync() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    if (_channel != null) {
      _supabase.removeChannel(_channel!);
      _channel = null;
      print('========= 📡 [Realtime] Channel removed.');
    }
  }

  // ─── Handlers ────────────────────────────────────────────────────────────

  void _handleServiceEvent(PostgresChangePayload payload) {
    _debounce(
      entityId: _extractId(payload),
      action: () => _applyServiceEvent(payload),
    );
  }

  Future<void> _applyServiceEvent(PostgresChangePayload payload) async {
    final event = payload.eventType;
    final id = _extractId(payload);
    if (id.isEmpty) return;

    print('========= 📡 [Realtime] services $event id:$id');

    if (event == PostgresChangeEvent.delete) {
      try {
        await _localDataSource.deleteService(id);
        print('========= ✅ [Realtime] Deleted service $id');
      } catch (e) {
        print('========= 🔴 [Realtime] Failed applying service delete event: $e');
      }
      return;
    }

    // INSERT or UPDATE — map payload to Hive model
    final rawData = payload.newRecord;
    if (rawData.isEmpty) return;

    // Conflict guard: if a local pending action exists, skip remote event
    if (await _hasPendingNewerThan(id, rawData['updated_at'])) {
      print('========= ⚔️ [Realtime] Skipping service $id — local pending change is newer.');
      return;
    }

    try {
      final normalizedData = _normalizeRawPayload(rawData);
      final model = ServiceRemoteModel.fromJson(normalizedData);
      if (model.status == ServiceStatus.archived) {
        await _localDataSource.deleteService(model.id);
        print('========= ✅ [Realtime] Deleted archived service $id');
      } else {
        final hiveModel = ServiceMapper.remoteToHive(model);
        await _localDataSource.cacheServices([hiveModel]);
        print('========= ✅ [Realtime] Applied $event to service $id');
      }
    } catch (e) {
      print('========= 🔴 [Realtime] Failed applying service event: $e');
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Returns true if there is a pending local action for [entityId] with a
  /// [createdAt] that is equal to or after the remote [updatedAtStr].
  Future<bool> _hasPendingNewerThan(String entityId, dynamic updatedAtStr) async {
    if (updatedAtStr == null) return false;
    final remoteUpdatedAt = DateTime.tryParse(updatedAtStr.toString());
    if (remoteUpdatedAt == null) return false;

    final pending = await _pendingActionDataSource.getAll();
    return pending.any((a) =>
        a.entityId == entityId &&
        !a.createdAt.isBefore(remoteUpdatedAt));
  }

  void _debounce({required String entityId, required Future<void> Function() action}) {
    _debounceTimers[entityId]?.cancel();
    _debounceTimers[entityId] = Timer(_debounceDuration, () {
      action();
      _debounceTimers.remove(entityId);
    });
  }

  String _extractId(PostgresChangePayload payload) {
    final record = payload.eventType == PostgresChangeEvent.delete
        ? payload.oldRecord
        : payload.newRecord;
    return record['id']?.toString() ?? '';
  }

  /// Normalizes and cleans raw Supabase payload into a map that matches the types in ServiceRemoteModel.
  Map<String, dynamic> _normalizeRawPayload(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    
    // Ensure lists and maps have correct types or defaults
    if (map['title'] == null) map['title'] = {'ar': '', 'en': ''};
    if (map['description'] == null) map['description'] = {'ar': '', 'en': ''};
    
    // Normalize nested arrays/maps if they are present in JSON but potentially returned differently
    final details = map['details'];
    if (details is! List) {
      map['details'] = [];
    }

    final notIncluded = map['not_included'];
    if (notIncluded is! Map) {
      map['not_included'] = null;
    }

    return map;
  }
}
