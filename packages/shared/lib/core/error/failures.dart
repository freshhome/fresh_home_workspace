
// اخطاء
abstract class Failure {
  final String message;
  final String? code;
  const Failure({required this.message, this.code});
}

//اخطاء سيرفر
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

// اخطاء مصادقة
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

// اخطاء شبكة
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

// اخطاء غير معروف
class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, super.code});
}

// اخطاء تحقق
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

// اخطاء كاش
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}
