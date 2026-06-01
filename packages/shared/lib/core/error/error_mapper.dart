// core/errors/error_mapper.dart

import 'exceptions.dart';
import 'failures.dart';

/// الهدف من الكلاس ده: يحوّل Exceptions إلى Failures
/// علشان الطبقات العليا (domain/presentation) تتعامل مع Failure فقط.
class ErrorMapper {
  /// بيحوّل Exception ل Failure بناءً على نوعه أو الكود بتاعه
  static Failure mapExceptionToFailure(AppException exception) {
    if (exception is AppAuthException) {
      return AuthFailure(message: exception.message, code: exception.code);
    } else if (exception is ServerException) {
      return ServerFailure(message: exception.message, code: exception.code);
    } else if (exception is NetworkException) {
      return NetworkFailure(message: exception.message, code: exception.code);
    } else {
      return UnknownFailure(
        message: 'unexpected_error',
        code: 'unexpected_error',
      );
    }
  }

  /// ✅ تحويل أخطاء الخدمات الخارجية (Supabase)
  static Failure mapExternalServiceError(AppException exception) {
    final code = exception.code ?? 'unknown_error';
    
    // Supabase specifically uses some common codes
    switch (code) {
      // --- Auth Errors ---
      case 'invalid_email':
      case 'invalid-email':
        return AuthFailure(message: 'بريد إلكتروني غير صحيح', code: code);
      case 'user_not_found':
      case 'user-not-found':
        return AuthFailure(message: 'المستخدم غير موجود', code: code);
      case 'invalid_credentials':
        return AuthFailure(message: 'بيانات الدخول غير صحيحة', code: code);
      case 'email_not_confirmed':
        return AuthFailure(message: 'يجب تأكيد البريد الإلكتروني أولاً', code: code);
      case 'too_many_requests':
        return AuthFailure(message: 'محاولات كثيرة جداً، يرجى المحاولة لاحقاً', code: code);
      case 'network_request_failed':
        return NetworkFailure(message: 'فشل في الاتصال بالشبكة', code: code);
      
      // --- Postgrest (Database) Errors ---
      case '23505': // Unique violation (e.g. duplicate email/username)
        return ServerFailure(message: 'هذه البيانات مسجلة مسبقاً', code: code);
      case '42501': // RLS violation (Permission denied)
        return ServerFailure(message: 'ليس لديك الصلاحية لإتمام هذه العملية', code: code);
      case '23503': // Foreign key violation
        return ServerFailure(message: 'فشل الارتباط ببيانات أخرى', code: code);
      case 'PGRST116': // JSON object requested, but no rows returned
        return ServerFailure(message: 'البيانات المطلوبة غير موجودة', code: code);
      case 'PGRST102': // Invalid query / column does not exist
        return ServerFailure(message: 'خطأ في معالجة الطلب البرمحي', code: code);
      
      default:
        // Handle generic supabase error messages if no specific code is found
        if (exception.message.contains('JWTErrors')) {
          return AuthFailure(message: 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً', code: 'session_expired');
        }
        return UnknownFailure(message: exception.message, code: code);
    }
  }
}
