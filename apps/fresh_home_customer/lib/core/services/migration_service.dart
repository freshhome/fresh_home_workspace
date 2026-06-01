import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared/shared.dart';

/// Abstract interface for migration services to ensure scalability.
abstract class MigrationService {
  Future<void> migrate();
}

/// Implementation of [MigrationService] focused on Hive migrations.
class HiveMigrationService implements MigrationService {
  final SharedPreferences _prefs;

  HiveMigrationService(this._prefs);

  @override
  Future<void> migrate() async {
    // Current migration version: v2 (Supabase transition)
    const String migrationKey = 'supabase_migration_cleared_v2';

    try {
      final alreadyCleared = _prefs.getBool(migrationKey) ?? false;

      if (!alreadyCleared) {
        debugPrint('🧹 [MIGRATION] Clearing Hive boxes for Supabase transition...');

        // Ensure Hive is initialized at least for the path provider logic
        await Hive.initFlutter();

        final boxesToClear = [
          HiveBoxNames.servicesBox,
          'sub_services_box',
          HiveBoxNames.servicesUpdatedBox,
          HiveBoxNames.syncMetadataBox,
        ];

        for (final boxName in boxesToClear) {
          try {
            await Hive.deleteBoxFromDisk(boxName);
            debugPrint('🗑️ [MIGRATION] Deleted box: $boxName');
          } catch (e) {
            debugPrint('⚠️ [MIGRATION] Could not delete box $boxName: $e');
          }
        }

        await _prefs.setBool(migrationKey, true);
        debugPrint('✅ [MIGRATION] Hive boxes migration (v2) completed successfully.');
      } else {
        debugPrint('ℹ️ [MIGRATION] No migration needed (v2 already applied).');
      }
    } catch (e) {
      debugPrint('🚨 [MIGRATION] Execution failed: $e');
    }
  }
}
