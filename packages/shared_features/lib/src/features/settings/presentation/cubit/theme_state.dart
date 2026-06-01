part of 'theme_cubit.dart';

abstract class ThemeState {}
class ThemeInitial extends ThemeState {}
class ThemeLoading extends ThemeState {}
class ThemeLoaded extends ThemeState { final bool isDark; ThemeLoaded(this.isDark); }
class ThemeError extends ThemeState { final dynamic failure; ThemeError(this.failure); }
