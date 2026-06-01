import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/exceptions.dart';

abstract class SplashDataSources {
  Future<bool> isUserLoggedIn();
}

class SplashDataSourcesImpl implements SplashDataSources {
  final SupabaseClient supabaseClient;

  SplashDataSourcesImpl(this.supabaseClient);

  @override
  Future<bool> isUserLoggedIn() async {
    try {
      final session = supabaseClient.auth.currentSession;
      return session != null;
    } catch (e) {
      throw UnknownException(e.toString(), code: 'unexpected_error');
    }
  }
}
