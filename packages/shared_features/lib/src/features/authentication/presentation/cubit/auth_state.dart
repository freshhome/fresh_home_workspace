part of 'auth_cubit.dart';

sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoadingState extends AuthState {}

// final class AuthSuccessState extends AuthState {}

final class SignUpSuccess extends AuthState {}

final class SignInSuccess extends AuthState {}

final class ResendVerificationSuccess extends AuthState {}

final class ResetPasswordSuccess extends AuthState {}
final class AuthPendingRoleState extends AuthState {}

final class AuthErrorState extends AuthState {
  final Failure failure;
  AuthErrorState(this.failure);
}
