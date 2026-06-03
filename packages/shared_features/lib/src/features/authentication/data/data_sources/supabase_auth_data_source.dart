import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:flutter/foundation.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> signIn(String email, String password);
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  });
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email, {required String redirectTo});
  Future<void> signInWithGoogle({required String redirectTo});
  Future<void> assignRole(String roleName);
  Future<UserResponse> updatePassword(String newPassword);
}

class SupabaseAuthDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;

  SupabaseAuthDataSourceImpl(this._supabase);

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    try {
      debugPrint('================ AUTH DEBUG ================');
      debugPrint('STARTING AUTH SIGNUP');
      debugPrint('email: $email');
      debugPrint('============================================');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );

      final user = response.user;
      final session = response.session;
      final providers = user?.identities?.map((i) => i.provider).toList();
      final identities = user?.identities?.map((i) => '${i.provider}:${i.identityId}').toList();

      debugPrint('================ AUTH DEBUG ================');
      debugPrint('DEBUG AUTH SIGNUP');
      debugPrint('email=$email');
      debugPrint('userId=${user?.id}');
      debugPrint('returnedEmail=${user?.email}');
      debugPrint('providers=$providers');
      debugPrint('identities=$identities');
      debugPrint('sessionExists=${session != null}');
      debugPrint('============================================');

      return response;
    } on AuthException catch (e, stackTrace) {
      debugPrint('================ AUTH DEBUG ================');
      debugPrint('DEBUG AUTH SIGNUP EXCEPTION');
      debugPrint('message: ${e.message}');
      debugPrint('statusCode: ${e.statusCode}');
      debugPrint('errorCode: ${e.code}');
      debugPrint('stack trace:\n$stackTrace');
      debugPrint('============================================');
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e, stackTrace) {
      debugPrint('================ AUTH DEBUG ================');
      debugPrint('DEBUG AUTH SIGNUP EXCEPTION');
      debugPrint('message: $e');
      debugPrint('statusCode: null');
      debugPrint('errorCode: null');
      debugPrint('stack trace:\n$stackTrace');
      debugPrint('============================================');
      throw SupabaseExceptionApp(e.toString(), code: 'auth_error');
    }
  }

  @override
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      debugPrint('================ AUTH DEBUG ================');
      debugPrint('STARTING AUTH SIGNIN');
      debugPrint('email: $email');
      debugPrint('============================================');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      final session = response.session;
      final providers = user?.identities?.map((i) => i.provider).toList();
      final identities = user?.identities?.map((i) => '${i.provider}:${i.identityId}').toList();

      debugPrint('================ AUTH DEBUG ================');
      debugPrint('DEBUG AUTH SIGNIN');
      debugPrint('email=$email');
      debugPrint('userId=${user?.id}');
      debugPrint('returnedEmail=${user?.email}');
      debugPrint('providers=$providers');
      debugPrint('identities=$identities');
      debugPrint('sessionExists=${session != null}');
      debugPrint('============================================');

      return response;
    } on AuthException catch (e, stackTrace) {
      debugPrint('================ AUTH DEBUG ================');
      debugPrint('DEBUG AUTH SIGNIN EXCEPTION');
      debugPrint('message: ${e.message}');
      debugPrint('statusCode: ${e.statusCode}');
      debugPrint('errorCode: ${e.code}');
      debugPrint('stack trace:\n$stackTrace');
      debugPrint('============================================');
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e, stackTrace) {
      debugPrint('================ AUTH DEBUG ================');
      debugPrint('DEBUG AUTH SIGNIN EXCEPTION');
      debugPrint('message: $e');
      debugPrint('statusCode: null');
      debugPrint('errorCode: null');
      debugPrint('stack trace:\n$stackTrace');
      debugPrint('============================================');
      throw SupabaseExceptionApp(e.toString(), code: 'auth_error');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'auth_error');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email, {required String redirectTo}) async {
    try {
      debugPrint('================ AUTH DEBUG ================');
      debugPrint('STARTING PASSWORD RESET EMAIL');
      debugPrint('email: $email');
      debugPrint('redirectTo: $redirectTo');
      debugPrint('============================================');

      await _supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo);

      debugPrint('================ AUTH DEBUG ================');
      debugPrint('DEBUG AUTH sendPasswordResetEmail SUCCESS');
      debugPrint('============================================');
    } on AuthException catch (e, stackTrace) {
      debugPrint('================ AUTH DEBUG ================');
      debugPrint('DEBUG AUTH sendPasswordResetEmail EXCEPTION');
      debugPrint('message: ${e.message}');
      debugPrint('statusCode: ${e.statusCode}');
      debugPrint('errorCode: ${e.code}');
      debugPrint('stack trace:\n$stackTrace');
      debugPrint('============================================');
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e, stackTrace) {
      debugPrint('================ AUTH DEBUG ================');
      debugPrint('DEBUG AUTH sendPasswordResetEmail EXCEPTION');
      debugPrint('message: $e');
      debugPrint('statusCode: null');
      debugPrint('errorCode: null');
      debugPrint('stack trace:\n$stackTrace');
      debugPrint('============================================');
      throw SupabaseExceptionApp(e.toString(), code: 'auth_error');
    }
  }

  @override
  Future<void> signInWithGoogle({required String redirectTo}) async {
    try {
      debugPrint('================ AUTH DEBUG ================');
      debugPrint('STARTING GOOGLE SIGNIN');
      debugPrint('redirectTo: $redirectTo');
      debugPrint('============================================');

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );

      debugPrint('================ AUTH DEBUG ================');
      debugPrint('DEBUG AUTH GOOGLE SIGNIN COMPLETED (External Redirect Initiated)');
      debugPrint('============================================');
    } on AuthException catch (e, stackTrace) {
      debugPrint('================ AUTH DEBUG ================');
      debugPrint('DEBUG AUTH GOOGLE SIGNIN EXCEPTION');
      debugPrint('message: ${e.message}');
      debugPrint('statusCode: ${e.statusCode}');
      debugPrint('errorCode: ${e.code}');
      debugPrint('stack trace:\n$stackTrace');
      debugPrint('============================================');
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e, stackTrace) {
      debugPrint('================ AUTH DEBUG ================');
      debugPrint('DEBUG AUTH GOOGLE SIGNIN EXCEPTION');
      debugPrint('message: $e');
      debugPrint('statusCode: null');
      debugPrint('errorCode: null');
      debugPrint('stack trace:\n$stackTrace');
      debugPrint('============================================');
      throw SupabaseExceptionApp(e.toString(), code: 'auth_error');
    }
  }

  @override
  Future<void> assignRole(String roleName) async {
    try {
      await _supabase.rpc('assign_role_to_user', params: {
        'role_name': roleName,
      });
    } on PostgrestException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'supabase_error');
    }
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      debugPrint('================ AUTH DEBUG ================');
      debugPrint('STARTING PASSWORD UPDATE');
      debugPrint('============================================');
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } on AuthException catch (e) {
      throw SupabaseExceptionApp(e.message, code: e.code);
    } catch (e) {
      throw SupabaseExceptionApp(e.toString(), code: 'auth_error');
    }
  }
}
