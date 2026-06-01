import 'package:get_it/get_it.dart';
import 'package:shared_features/shared_features.dart';
import 'package:shared_features/src/features/settings/data/settings_data.dart';

Future<void> initSettingsDI(GetIt getIt) async {
  // Data Sources
  getIt.registerLazySingleton<ThemeLocalDataSource>(
    () => ThemeLocalDataSourceImpl(),
  );
  getIt.registerLazySingleton<LocaleLocalDataSource>(
    () => LocaleLocalDataSourceImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      themeLocalDataSource: getIt<ThemeLocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton<LocaleRepository>(
    () => LocaleRepositoryImpl(
      localeLocalDataSource: getIt<LocaleLocalDataSource>(),
    ),
  );

  // Use Cases
  getIt.registerLazySingleton<GetThemeUseCase>(
    () => GetThemeUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<SetThemeUseCase>(
    () => SetThemeUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<GetSavedLocaleUseCase>(
    () => GetSavedLocaleUseCase(getIt<LocaleRepository>()),
  );
  getIt.registerLazySingleton<ChangeLocaleUseCase>(
    () => ChangeLocaleUseCase(getIt<LocaleRepository>()),
  );

  // Cubits
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(getIt<GetThemeUseCase>(), getIt<SetThemeUseCase>()),
  );
  getIt.registerLazySingleton<LocaleCubit>(
    () => LocaleCubit(
      getIt<GetSavedLocaleUseCase>(),
      getIt<ChangeLocaleUseCase>(),
    ),
  );
  getIt.registerFactory<SignOutCubit>(
    () => SignOutCubit(getIt<SignOutUseCase>()),
  );
}
