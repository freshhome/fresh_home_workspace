import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:shared/domain/user/enums/user_status.dart';
import 'package:go_router/go_router.dart';
import '../cubit/user_management_cubit.dart';
import '../widgets/user_status_badge.dart';
import '../widgets/user_role_tag.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<UserManagementCubit>().fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        title: const Text(
          'إدارة المستخدمين',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      extendBodyBehindAppBar: false,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            _buildFilters(context),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<UserManagementCubit, UserManagementState>(
                builder: (context, state) {
                  if (state is UserManagementLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is UserManagementError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
                        ],
                      ),
                    );
                  } else if (state is UserManagementLoaded) {
                    final users = state.users;
                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا يوجد مستخدمين مطابقين للبحث',
                          style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => context.read<UserManagementCubit>().refreshUsers(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          return _buildUserListItem(context, users[index]);
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => context.read<UserManagementCubit>().searchUsers(value),
        style: const TextStyle(fontFamily: 'Cairo'),
        decoration: InputDecoration(
          hintText: 'بحث بالاسم، البريد، أو الهاتف...',
          hintStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
          prefixIcon: const Icon(Icons.search_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterChip(context, 'الكل', null),
          _filterChip(context, UserStatus.active.translatedName(context), UserStatus.active),
          _filterChip(context, UserStatus.pending.translatedName(context), UserStatus.pending),
          _filterChip(context, UserStatus.suspended.translatedName(context), UserStatus.suspended),
          _filterChip(context, UserStatus.banned.translatedName(context), UserStatus.banned),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, UserStatus? value) {
    return BlocBuilder<UserManagementCubit, UserManagementState>(
      builder: (context, state) {
        final currentFilter = (state is UserManagementLoaded) ? state.statusFilter : null;
        final isSelected = currentFilter == value;
        return Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ChoiceChip(
              label: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) context.read<UserManagementCubit>().filterByStatus(value);
              },
              selectedColor: context.themeColor.primary,
              backgroundColor: Colors.white,
              elevation: isSelected ? 4 : 1,
              pressElevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide.none,
              showCheckmark: false,
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserListItem(BuildContext context, UserRemoteModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('${AppRoutes.adminUserManagement}/${user.id}', extra: user),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'user_avatar_${user.id}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.themeColor.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: context.themeColor.primary.withValues(alpha: 0.1),
                      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                      child: user.avatarUrl == null
                          ? Icon(Icons.person_rounded, color: context.themeColor.primary, size: 30)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${user.firstName} ${user.lastName}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          UserStatusBadge(status: user.accountStatus),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: user.roles.map((r) => UserRoleTag(role: r)).toList(),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to help with box shadows in decorations since they are not in constructor
extension InputDecorationShadow on InputDecoration {
  InputDecoration withShadow(List<BoxShadow> shadows) {
    // This is a placeholder since InputDecoration doesn't support shadows directly.
    // In real app we wrap the TextField with a Container.
    return this;
  }
}
