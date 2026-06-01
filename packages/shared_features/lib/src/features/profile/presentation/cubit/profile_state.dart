part of 'profile_cubit.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserWithProfile profile;
  ProfileLoaded(this.profile);
}

class ProfileError extends ProfileState {
  final Failure failure;
  final UserWithProfile? profile;
  ProfileError(this.failure, {this.profile});
}
