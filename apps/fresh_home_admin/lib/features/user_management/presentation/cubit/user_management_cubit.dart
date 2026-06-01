import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/domain/user/enums/user_status.dart';
import '../../domain/repositories/user_management_repository.dart';

abstract class UserManagementState extends Equatable {
  const UserManagementState();
  @override
  List<Object?> get props => [];
}

class UserManagementInitial extends UserManagementState {}
class UserManagementLoading extends UserManagementState {}
class UserManagementLoaded extends UserManagementState {
  final List<UserRemoteModel> users;
  final String? searchQuery;
  final UserRole? roleFilter;
  final UserStatus? statusFilter;

  const UserManagementLoaded({
    required this.users,
    this.searchQuery,
    this.roleFilter,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [users, searchQuery, roleFilter, statusFilter];
}
class UserManagementError extends UserManagementState {
  final String message;
  const UserManagementError(this.message);
  @override
  List<Object?> get props => [message];
}

class UserManagementCubit extends Cubit<UserManagementState> {
  final UserManagementRepository _repository;

  UserManagementCubit(this._repository) : super(UserManagementInitial());

  Future<void> fetchUsers({
    String? searchQuery,
    UserRole? roleFilter,
    UserStatus? statusFilter,
  }) async {
    emit(UserManagementLoading());
    try {
      final users = await _repository.getUsers(
        searchQuery: searchQuery,
        roleFilter: roleFilter,
        statusFilter: statusFilter,
      );
      emit(UserManagementLoaded(
        users: users,
        searchQuery: searchQuery,
        roleFilter: roleFilter,
        statusFilter: statusFilter,
      ));
    } catch (e) {
      emit(UserManagementError(e.toString()));
    }
  }

  Future<void> refreshUsers() async {
    final currentState = state;
    String? searchQuery;
    UserRole? roleFilter;
    UserStatus? statusFilter;

    if (currentState is UserManagementLoaded) {
      searchQuery = currentState.searchQuery;
      roleFilter = currentState.roleFilter;
      statusFilter = currentState.statusFilter;
    }

    try {
      final users = await _repository.getUsers(
        searchQuery: searchQuery,
        roleFilter: roleFilter,
        statusFilter: statusFilter,
      );
      emit(UserManagementLoaded(
        users: users,
        searchQuery: searchQuery,
        roleFilter: roleFilter,
        statusFilter: statusFilter,
      ));
    } catch (e) {
      emit(UserManagementError(e.toString()));
    }
  }

  void searchUsers(String query) {
    if (state is UserManagementLoaded) {
      final currentState = state as UserManagementLoaded;
      fetchUsers(
        searchQuery: query,
        roleFilter: currentState.roleFilter,
        statusFilter: currentState.statusFilter,
      );
    } else {
      fetchUsers(searchQuery: query);
    }
  }

  void filterByRole(UserRole? role) {
    if (state is UserManagementLoaded) {
      final currentState = state as UserManagementLoaded;
      fetchUsers(
        searchQuery: currentState.searchQuery,
        roleFilter: role,
        statusFilter: currentState.statusFilter,
      );
    } else {
      fetchUsers(roleFilter: role);
    }
  }

  void filterByStatus(UserStatus? status) {
    if (state is UserManagementLoaded) {
      final currentState = state as UserManagementLoaded;
      fetchUsers(
        searchQuery: currentState.searchQuery,
        roleFilter: currentState.roleFilter,
        statusFilter: status,
      );
    } else {
      fetchUsers(statusFilter: status);
    }
  }
}
