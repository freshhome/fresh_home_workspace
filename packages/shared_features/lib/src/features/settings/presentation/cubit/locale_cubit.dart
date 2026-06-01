import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/settings/domain/settings_domain.dart';

part 'locale_state.dart';

/// Cubit for managing app locale/language
class LocaleCubit extends Cubit<LocaleState> {
  final GetSavedLocaleUseCase getSavedLocaleUseCase;
  final ChangeLocaleUseCase changeLocaleUseCase;

  LocaleCubit(this.getSavedLocaleUseCase, this.changeLocaleUseCase) 
      : super(LocaleInitial());

  /// Load the saved locale on app start
  Future<void> loadSavedLocale() async {
    emit(LocaleLoading());
    
    final result = await getSavedLocaleUseCase();
    
    result.fold(
      (failure) {
        // If error loading, default to Arabic
        emit(LocaleLoaded(const Locale('ar')));
      },
      (localeCode) {
        // If no saved locale, default to Arabic
        final locale = localeCode != null 
            ? Locale(localeCode) 
            : const Locale('ar');
        emit(LocaleLoaded(locale));
      },
    );
  }

  /// Change the app locale
  Future<void> changeLocale(String languageCode) async {
    // Avoid redundant changes if the same language is selected
    final current = currentLocale;
    if (current?.languageCode == languageCode) return;

    emit(LocaleLoading());
    
    final result = await changeLocaleUseCase(languageCode);
    
    result.fold(
      (failure) => emit(LocaleError(failure)),
      (_) => emit(LocaleLoaded(Locale(languageCode))),
    );
  }

  /// Get the current locale from state
  Locale? get currentLocale {
    final state = this.state;
    if (state is LocaleLoaded) {
      return state.locale;
    }
    return null;
  }
}
