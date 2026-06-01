import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';

/// Repository interface for managing app locale
abstract class LocaleRepository {
  /// Get the saved locale code (e.g., 'ar', 'en')
  /// Returns null if no locale has been saved
  Future<Either<Failure, String?>> getSavedLocale();
  
  /// Change and persist the app locale
  Future<Either<Failure, void>> changeLocale(String localeCode);
}
