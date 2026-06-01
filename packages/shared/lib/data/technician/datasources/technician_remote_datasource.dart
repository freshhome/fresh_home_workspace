import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/smart_schedule_model.dart';
import '../models/technician_pool_status_model.dart';

abstract class TechnicianRemoteDataSource {
  Future<List<SmartScheduleModel>> getSmartSchedule(String technicianId, int days);
  Future<void> updateDailyCapacity({
    required String technicianId,
    required DateTime date,
    required int newCapacity,
    required bool isBlocked,
    String? poolId,
    String? reason,
    String? slotMask,
  });
  Future<void> resetDailyCapacity({
    required String technicianId,
    required DateTime date,
  });
  Future<List<TechnicianPoolStatusModel>> getDailyPoolBreakdown({
    required String technicianId,
    required DateTime date,
  });
  Future<bool> reassignAndBlockCapacity({
    required String technicianId,
    required DateTime date,
    String? poolId,
    int? slotIndex,
  });
}

class TechnicianRemoteDataSourceImpl implements TechnicianRemoteDataSource {
  final SupabaseClient _supabase;

  TechnicianRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<TechnicianPoolStatusModel>> getDailyPoolBreakdown({
    required String technicianId,
    required DateTime date,
  }) async {
    // 1. Fetch breakdown from RPC (provides capacity and load)
    final response = await _supabase.rpc(
      'get_technician_daily_pool_breakdown',
      params: {
        'p_technician_id': technicianId,
        'p_date': date.toIso8601String().split('T')[0],
      },
    );

    final List<TechnicianPoolStatusModel> pools = (response as List)
        .map((e) => TechnicianPoolStatusModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // 2. Fetch skills to get the service names for each pool
    try {
      final skillsResponse = await _supabase
          .from('technician_skills')
          .select('capacity_pool_id, sub_services(title)')
          .eq('technician_id', technicianId);

      if (skillsResponse.isNotEmpty) {
        final Map<String, List<String>> poolServices = {};
        
        for (final skill in skillsResponse) {
          final String? poolId = skill['capacity_pool_id'];
          final dynamic subService = skill['sub_services'];
          
          if (poolId != null && subService != null) {
            final String? arTitle = subService['title']?['ar'];
            final String? enTitle = subService['title']?['en'];
            final String serviceName = arTitle ?? enTitle ?? 'خدمة غير معروفة';
            
            poolServices.putIfAbsent(poolId, () => []).add(serviceName);
          }
        }

        // 3. Attach services to the pool models
        return pools.map((pool) {
          final services = poolServices[pool.poolId] ?? [];
          return TechnicianPoolStatusModel(
            poolId: pool.poolId,
            title: pool.title,
            maxCapacity: pool.maxCapacity,
            currentLoad: pool.currentLoad,
            isBlocked: pool.isBlocked,
            overrideCapacity: pool.overrideCapacity,
            isOverride: pool.isOverride,
            slotMask: pool.slotMask,
            services: services,
          );
        }).toList();
      }
    } catch (e) {
      // log error or handle silently as we fallback to pools
    }

    return pools;
  }

  @override
  Future<void> resetDailyCapacity({
    required String technicianId,
    required DateTime date,
  }) async {
    // Delete overrides for ALL pools of this technician on this date
    // This ensures the total daily capacity reverts to the sum of all default pool capacities.
    await _supabase
        .from('capacity_overrides')
        .delete()
        .eq('technician_id', technicianId)
        .eq('override_date', date.toIso8601String().split('T')[0]);
  }

  @override
  Future<void> updateDailyCapacity({
    required String technicianId,
    required DateTime date,
    required int newCapacity,
    required bool isBlocked,
    String? poolId,
    String? reason,
    String? slotMask,
  }) async {
    String? resolvedPoolId = poolId;

    // 1. If poolId was NOT provided, find the primary/first pool
    if (resolvedPoolId == null) {
      final poolResponse = await _supabase
          .from('capacity_pools')
          .select('id')
          .eq('technician_id', technicianId)
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();

      if (poolResponse == null) return;
      resolvedPoolId = poolResponse['id'];
    }

    if (resolvedPoolId == null) return;

    // 2. Upsert the override
    await _supabase.from('capacity_overrides').upsert({
      'pool_id': resolvedPoolId,
      'technician_id': technicianId,
      'override_date': date.toIso8601String().split('T')[0],
      'new_capacity': isBlocked ? null : newCapacity,
      'is_blocked': isBlocked,
      'reason': reason ?? 'Technician update via app',
      'slot_mask': slotMask,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'technician_id, pool_id, override_date');
  }

  @override
  Future<bool> reassignAndBlockCapacity({
    required String technicianId,
    required DateTime date,
    String? poolId,
    int? slotIndex,
  }) async {
    try {
      final response = await _supabase.rpc(
        'reassign_and_block_technician_capacity',
        params: {
          'p_technician_id': technicianId,
          'p_date': date.toIso8601String().split('T')[0],
          'p_pool_id': poolId,
          'p_slot_index': slotIndex,
        },
      );
      
      // Assume RPC returns a boolean success flag
      return response as bool;
    } catch (e) {
      // If RPC fails, we return false to trigger the "Contact management" UI flow
      return false;
    }
  }

  @override
  Future<List<SmartScheduleModel>> getSmartSchedule(String technicianId, int days) async {
    final response = await _supabase.rpc(
      'get_technician_smart_schedule',
      params: {
        'p_technician_id': technicianId,
        'p_days_ahead': days,
      },
    );

    if (response is List) {
      return response
          .map((json) => SmartScheduleModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Failed to fetch smart schedule');
  }
}
