import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/exceptions.dart';

abstract class CounterRemoteDataSource {
  Future<int> getNextId(String collectionName);
}

class CounterRemoteDataSourceImpl implements CounterRemoteDataSource {
  final SupabaseClient _supabase;

  CounterRemoteDataSourceImpl({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<int> getNextId(String collectionName) async {
    try {
      // Strategy: Use a 'counters' table in Supabase.
      // We attempt to get the current value, increment it, and upsert.
      // Note: For high concurrency, a database function (RPC) would be better.
      
      final response = await _supabase
          .from('counters')
          .select('last_value')
          .eq('id', collectionName)
          .maybeSingle();

      int nextValue;
      if (response == null) {
        nextValue = 100001; 
      } else {
        nextValue = (response['last_value'] as int) + 1;
      }

      await _supabase.from('counters').upsert({
        'id': collectionName,
        'last_value': nextValue,
      });

      return nextValue;
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'counter_error');
    }
  }
}
