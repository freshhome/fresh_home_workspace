import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/data/user/models/remote/client_profile_remote_model.dart';

abstract class ClientProfileRemoteDataSource {
  Future<void> saveClientProfile(ClientProfileRemoteModel profile);
  Future<ClientProfileRemoteModel?> getClientProfile(String uid);
}

class ClientProfileRemoteDataSourceImpl
    implements ClientProfileRemoteDataSource {
  final SupabaseClient _supabase;
  final String _tableName = 'profiles';

  ClientProfileRemoteDataSourceImpl(this._supabase);

  @override
  Future<void> saveClientProfile(ClientProfileRemoteModel profile) async {
    try {
      // 1. Handle Phones
      final existingPhones = await _supabase.from('user_phones').select('id').eq('user_id', profile.uid);
      final newPhoneIds = profile.phoneNumbers
          .map((p) => p.id)
          .where((id) => id != null && id.isNotEmpty)
          .toList();
      
      final phonesToDelete = (existingPhones as List)
          .map((p) => p['id'] as String)
          .where((id) => !newPhoneIds.contains(id))
          .toList();

      if (phonesToDelete.isNotEmpty) {
        await _supabase.from('user_phones').delete().inFilter('id', phonesToDelete);
      }

      if (profile.phoneNumbers.isNotEmpty) {
        final List<Map<String, dynamic>> toInsert = [];
        final List<Map<String, dynamic>> toUpdate = [];

        for (var p in profile.phoneNumbers) {
          final json = p.toJson();
          json['user_id'] = profile.uid;
          
          if (json['id'] == null || json['id'] == '') {
            json.remove('id');
            toInsert.add(json);
          } else {
            toUpdate.add(json);
          }
        }

        if (toInsert.isNotEmpty) {
          await _supabase.from('user_phones').insert(toInsert);
        }
        if (toUpdate.isNotEmpty) {
          await _supabase.from('user_phones').upsert(toUpdate);
        }
      }

      // 2. Handle Addresses
      final existingAddresses = await _supabase.from('user_addresses').select('id').eq('user_id', profile.uid);
      final newAddressIds = profile.addresses
          .map((a) => a.id)
          .where((id) => id != null && id.isNotEmpty)
          .toList();

      final addressesToDelete = (existingAddresses as List)
          .map((a) => a['id'] as String)
          .where((id) => !newAddressIds.contains(id))
          .toList();

      if (addressesToDelete.isNotEmpty) {
        await _supabase.from('user_addresses').delete().inFilter('id', addressesToDelete);
      }

      if (profile.addresses.isNotEmpty) {
        final List<Map<String, dynamic>> toInsert = [];
        final List<Map<String, dynamic>> toUpdate = [];

        for (var a in profile.addresses) {
          final json = a.toJson();
          json['user_id'] = profile.uid;
          
          if (json['id'] == null || json['id'] == '') {
            json.remove('id');
            toInsert.add(json);
          } else {
            toUpdate.add(json);
          }
        }

        if (toInsert.isNotEmpty) {
          await _supabase.from('user_addresses').insert(toInsert);
        }
        if (toUpdate.isNotEmpty) {
          await _supabase.from('user_addresses').upsert(toUpdate);
        }
      }
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<ClientProfileRemoteModel?> getClientProfile(String uid) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('id, user_phones(*), user_addresses(*)')
          .eq('id', uid)
          .maybeSingle();

      if (response == null) {
        return null;
      }
      return ClientProfileRemoteModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }
}
