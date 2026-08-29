import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';
import 'package:shared_features/shared_features.dart';

class FreshHomeAdminApp extends StatelessWidget {
  const FreshHomeAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final routerConfig = GetIt.instance<AppRouterConfig>();

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: GetIt.instance<ThemeCubit>()..loadTheme()),
        BlocProvider.value(
          value: GetIt.instance<LocaleCubit>()..loadSavedLocale(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          final isDark = themeState is ThemeLoaded ? themeState.isDark : false;
          return BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              final locale = localeState is LocaleLoaded
                  ? localeState.locale
                  : const Locale('ar');
              return BlocProvider.value(
                value: GetIt.instance<AuthCubit>(),
                child: AuthListener(
                  appRole: 'admin',
                  child: Builder(
                    builder: (context) {
                      // Initialize foreground notification handling
                      GetIt.instance<FirebaseMessagingHandler>()
                          .initializeForegroundHandling();

                      return MaterialApp.router(
                        scaffoldMessengerKey:
                            GetIt.instance<NavigationService>()
                                .scaffoldMessengerKey,
                        title: 'فريش - الإدارة',
                        debugShowCheckedModeBanner: false,
                        routerConfig: routerConfig.router,
                        localizationsDelegates:
                            AppLocalizations.localizationsDelegates,
                        supportedLocales: AppLocalizations.supportedLocales,
                        locale: locale,
                        theme: isDark ? AppTheme.dark : AppTheme.light,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
