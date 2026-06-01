abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException($code): $message';
}

// اخطاء سيرفر
class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}

// اخطاء مصادقة
class AppAuthException extends AppException {
  const AppAuthException(super.message, {super.code});
}

// اخطاء من سوبا بيز
class SupabaseExceptionApp extends AppException {
  const SupabaseExceptionApp(super.message, {super.code});
}

// اخطاء شبكة
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

// اخطاء غير معروف
class UnknownException extends AppException {
  const UnknownException(super.message, {super.code});
}

// اخطاء الكاش
class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}
