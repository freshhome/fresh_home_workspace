part of 'locale_cubit.dart';

/// States for locale management
abstract class LocaleState {}

/// Initial state
class LocaleInitial extends LocaleState {}

/// Loading locale
class LocaleLoading extends LocaleState {}

/// Locale loaded successfully
class LocaleLoaded extends LocaleState {
  final Locale locale;
  LocaleLoaded(this.locale);
}

/// Error loading or changing locale
class LocaleError extends LocaleState {
  final Failure failure;
  LocaleError(this.failure);
}
