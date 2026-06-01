part of 'splash_cubit.dart';

abstract class SplashState {}

class SplashInitial extends SplashState {}

class SplashLoadingState extends SplashState {}

class SplashUserLoggedInState extends SplashState {}

class SplashUserPendingApprovalState extends SplashState {}

class SplashUserNotLoggedInState extends SplashState {}

class SplashOnboardingState extends SplashState {}

class SplashErrorState extends SplashState {
  final Failure failure;
  SplashErrorState(this.failure);
}
