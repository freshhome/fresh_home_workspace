import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/data/user/models/remote/customer_profile_remote_model.dart';

abstract class ClientProfileRemoteDataSource {
  Future<void> saveClientProfile(CustomerProfileRemoteModel profile);
  Future<CustomerProfileRemoteModel?> getClientProfile(String uid);
}

class ClientProfileRemoteDataSourceImpl
    implements ClientProfileRemoteDataSource {
  final SupabaseClient _supabase;
  final String _tableName = 'profiles';

  ClientProfileRemoteDataSourceImpl(this._supabase);

  @override
  Future<void> saveClientProfile(CustomerProfileRemoteModel profile) async {
    try {
      // Execute a single atomic database RPC call to sync_user_profile
      // This synchronizes phones and addresses list atomically inside a single transaction.
      await _supabase.rpc('sync_user_profile', params: {
        'p_user_id': profile.userId,
        'p_phones': profile.phoneNumbers.map((p) => p.toJson()).toList(),
        'p_addresses': profile.addresses.map((a) => a.toJson()).toList(),
      });
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<CustomerProfileRemoteModel?> getClientProfile(String uid) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('id, user_phones(*), user_addresses(*), customer_profiles(*)')
          .eq('id', uid)
          .maybeSingle();

      if (response == null) {
        return null;
      }
      return CustomerProfileRemoteModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }
}
