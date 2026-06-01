import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_features/src/features/settings/domain/settings_domain.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final GetThemeUseCase getThemeUseCase;
  final SetThemeUseCase setThemeUseCase;
  ThemeCubit(this.getThemeUseCase, this.setThemeUseCase) : super(ThemeInitial());

  Future<void> loadTheme() async {
    final res = await getThemeUseCase();
    res.fold((l) => emit(ThemeError(l)), (isDark) => emit(ThemeLoaded(isDark)));
  }

  Future<void> toggle() async {
    final current = state is ThemeLoaded ? (state as ThemeLoaded).isDark : false;
    final res = await setThemeUseCase(!current);
    res.fold((l) => emit(ThemeError(l)), (_) => emit(ThemeLoaded(!current)));
  }

  Future<void> setTheme(bool isDark) async {
    final res = await setThemeUseCase(isDark);
    res.fold((l) => emit(ThemeError(l)), (_) => emit(ThemeLoaded(isDark)));
  }
}
