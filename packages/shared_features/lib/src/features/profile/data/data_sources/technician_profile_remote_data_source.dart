import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/data/user/models/remote/technician_profile_remote_model.dart';

abstract class TechnicianProfileRemoteDataSource {
  Future<void> saveTechnicianProfile(TechnicianProfileRemoteModel profile);
  Future<TechnicianProfileRemoteModel?> getTechnicianProfile(String uid);
}

class TechnicianProfileRemoteDataSourceImpl
    implements TechnicianProfileRemoteDataSource {
  final SupabaseClient _supabase;
  final String _tableName = 'technician_profiles';

  TechnicianProfileRemoteDataSourceImpl(this._supabase);

  @override
  Future<void> saveTechnicianProfile(TechnicianProfileRemoteModel profile) async {
    try {
      await _supabase.from(_tableName).upsert(profile.toJson());
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<TechnicianProfileRemoteModel?> getTechnicianProfile(String uid) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (response == null) {
        return null;
      }
      return TechnicianProfileRemoteModel.fromJson(response);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }
}
