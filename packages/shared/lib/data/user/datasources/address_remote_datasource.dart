import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/data/user/models/address_model.dart';

abstract class AddressRemoteDataSource {
  Future<List<AddressModel>> getAddresses(String userId);
  Future<AddressModel> getAddressById(String addressId);
  Future<AddressModel?> getPrimaryAddress(String userId);
  Future<AddressModel> createAddress(AddressModel addressModel);
  Future<AddressModel> updateAddress(AddressModel addressModel);
  Future<void> deleteAddress(String addressId);
  Future<void> setPrimaryAddress({required String userId, required String addressId});
}

class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  final SupabaseClient supabaseClient;

  AddressRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<AddressModel>> getAddresses(String userId) async {
    try {
      final List<dynamic> response = await supabaseClient
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: false);

      return response.map((json) => AddressModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerFailure(message: 'Failed to fetch user addresses: ${e.toString()}');
    }
  }

  @override
  Future<AddressModel> getAddressById(String addressId) async {
    try {
      final Map<String, dynamic> response = await supabaseClient
          .from('user_addresses')
          .select()
          .eq('id', addressId)
          .single();

      return AddressModel.fromJson(response);
    } catch (e) {
      throw ServerFailure(message: 'Failed to fetch address by ID: ${e.toString()}');
    }
  }

  @override
  Future<AddressModel?> getPrimaryAddress(String userId) async {
    try {
      final Map<String, dynamic>? response = await supabaseClient
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .eq('is_primary', true)
          .filter('deleted_at', 'is', null)
          .maybeSingle();

      if (response == null) return null;
      return AddressModel.fromJson(response);
    } catch (e) {
      throw ServerFailure(message: 'Failed to fetch primary address: ${e.toString()}');
    }
  }

  @override
  Future<AddressModel> createAddress(AddressModel addressModel) async {
    try {
      final jsonPayload = addressModel.toJson();
      jsonPayload.remove('id'); // Allow DB gen_random_uuid()

      final Map<String, dynamic> response = await supabaseClient
          .from('user_addresses')
          .insert(jsonPayload)
          .select()
          .single();

      return AddressModel.fromJson(response);
    } catch (e) {
      throw ServerFailure(message: 'Failed to create address: ${e.toString()}');
    }
  }

  @override
  Future<AddressModel> updateAddress(AddressModel addressModel) async {
    try {
      final jsonPayload = addressModel.toJson();
      final Map<String, dynamic> response = await supabaseClient
          .from('user_addresses')
          .update(jsonPayload)
          .eq('id', addressModel.id)
          .select()
          .single();

      return AddressModel.fromJson(response);
    } catch (e) {
      throw ServerFailure(message: 'Failed to update address: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    try {
      // Check if address is referenced in any bookings
      final List<dynamic> bookingCheck = await supabaseClient
          .from('bookings')
          .select('id')
          .eq('address_id', addressId)
          .limit(1);

      final hasBookings = bookingCheck.isNotEmpty;

      if (hasBookings) {
        // Execute Soft Delete to preserve historical integrity
        await supabaseClient
            .from('user_addresses')
            .update({'deleted_at': DateTime.now().toIso8601String(), 'is_primary': false})
            .eq('id', addressId);
      } else {
        // Hard delete if completely unused
        await supabaseClient
            .from('user_addresses')
            .delete()
            .eq('id', addressId);
      }
    } catch (e) {
      throw ServerFailure(message: 'Failed to delete address: ${e.toString()}');
    }
  }

  @override
  Future<void> setPrimaryAddress({required String userId, required String addressId}) async {
    try {
      // Set target address to primary (Trigger fn_handle_primary_address_switch will atomically unset others)
      await supabaseClient
          .from('user_addresses')
          .update({'is_primary': true})
          .eq('id', addressId)
          .eq('user_id', userId);
    } catch (e) {
      throw ServerFailure(message: 'Failed to set primary address: ${e.toString()}');
    }
  }
}
