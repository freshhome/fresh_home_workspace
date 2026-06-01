import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import 'package:shared/data/user/models/remote/user_remote_model.dart';
import 'package:shared/data/user/models/remote/technician_profile_remote_model.dart';
import 'package:shared/data/user/models/remote/audit_log_remote_model.dart';
import 'package:shared/domain/user/enums/user_status.dart';
import 'package:shared/data/technician/models/remote/capacity_pool_remote_model.dart';
import 'package:shared/data/technician/models/remote/technician_skill_remote_model.dart';
import '../cubit/user_detail_cubit.dart';
import '../widgets/user_status_badge.dart';

class UserDetailScreen extends StatefulWidget {
  final UserRemoteModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final bool isTechnician = widget.user.roles.contains(UserRole.technician);
    _tabController = TabController(length: isTechnician ? 5 : 4, vsync: this);
    context.read<UserDetailCubit>().fetchUserDetail(widget.user.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: themeColor.background,
        appBar: AppBar(
          title: const Text(
            'تفاصيل المستخدم',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: themeColor.primary,
            labelColor: themeColor.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
            tabs: [
              const Tab(text: 'نظرة عامة', icon: Icon(Icons.dashboard_rounded)),
              const Tab(text: 'الاتصال والعناوين', icon: Icon(Icons.contact_phone_rounded)),
              const Tab(text: 'الأدوار والأمان', icon: Icon(Icons.admin_panel_settings_rounded)),
              if (widget.user.roles.contains(UserRole.technician))
                const Tab(text: 'التخصصات (فني)', icon: Icon(Icons.build_circle_rounded)),
              const Tab(text: 'النشاط والسجلات', icon: Icon(Icons.history_rounded)),
            ],
          ),
        ),
        body: BlocConsumer<UserDetailCubit, UserDetailState>(
          listener: (context, state) {
            if (state is UserDetailSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is UserDetailError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is UserDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is UserDetailLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(user: state.user),
                  _ContactTab(user: state.user),
                  _SecurityTab(user: state.user, mainServices: state.mainServices),
                  if (state.user.roles.contains(UserRole.technician))
                    _TechnicianTab(
                      user: state.user,
                      technicianProfile: state.technicianProfile,
                      capacityPools: state.capacityPools,
                      technicianSkills: state.technicianSkills,
                      availableSubServices: state.availableSubServices,
                      mainServices: state.mainServices,
                    ),
                  _ActivityTab(logs: state.auditLogs),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final UserRemoteModel user;
  const _OverviewTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileCard(context),
          const SizedBox(height: 16),
          _buildStatsGrid(context),
          const SizedBox(height: 16),
          _buildStatusQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Hero(
              tag: 'user_avatar_${user.id}',
              child: CircleAvatar(
                radius: 50,
                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null ? const Icon(Icons.person, size: 50) : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${user.firstName} ${user.lastName}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            Text(user.email, style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
            const SizedBox(height: 12),
            UserStatusBadge(status: user.accountStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statItem(context, 'تاريخ التسجيل', user.createdAt.toLocal().toString().split(' ').first, Icons.calendar_today_rounded),
        _statItem(context, 'الجنس', user.gender == 'male' ? 'ذكر' : (user.gender == 'female' ? 'أنثى' : 'غير محدد'), Icons.person_outline_rounded),
        _statItem(context, 'الأدوار', user.roles.length.toString(), Icons.badge_rounded),
        _statItem(context, 'العناوين', (user.addresses?.length ?? 0).toString(), Icons.location_on_rounded),
      ],
    );
  }

  Widget _statItem(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: context.themeColor.primary),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo')),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  Widget _buildStatusQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إجراءات سريعة للحساب', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionBtn(context, 'تفعيل', Icons.check_circle_outline, Colors.green, () {
                context.read<UserDetailCubit>().updateUserStatus(user.id, UserStatus.active);
              }),
              _actionBtn(context, 'تعليق', Icons.pause_circle_outline, Colors.orange, () {
                context.read<UserDetailCubit>().updateUserStatus(user.id, UserStatus.suspended);
              }),
              _actionBtn(context, 'حظر', Icons.block_flipped, Colors.red, () {
                context.read<UserDetailCubit>().updateUserStatus(user.id, UserStatus.banned);
              }),
            ],
          )
        ],
      ),
    );
  }

  Widget _actionBtn(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}

class _ContactTab extends StatelessWidget {
  final UserRemoteModel user;
  const _ContactTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('أرقام الهاتف'),
        if (user.phones == null || user.phones!.isEmpty)
          const Center(child: Text('لا توجد أرقام مسجلة', style: TextStyle(fontFamily: 'Cairo')))
        else
          ...user.phones!.map((p) => ListTile(
                leading: Icon(Icons.phone_rounded, color: p.isPrimary ? Colors.green : Colors.grey),
                title: Text(p.phoneNumber),
                trailing: p.isPrimary ? const Text('رئيسي', style: TextStyle(color: Colors.green, fontSize: 12, fontFamily: 'Cairo')) : null,
              )),
        const SizedBox(height: 24),
        _buildSectionTitle('العناوين'),
        if (user.addresses == null || user.addresses!.isEmpty)
          const Center(child: Text('لا توجد عناوين مسجلة', style: TextStyle(fontFamily: 'Cairo')))
        else
          ...user.addresses!.map((a) => Card(
                child: ListTile(
                  leading: Icon(Icons.location_on_rounded, color: a.isPrimary ? Colors.green : Colors.grey),
                  title: Text(a.fullAddress, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
                  subtitle: Text(a.isPrimary ? 'العنوان الرئيسي' : 'عنوان إضافي', style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
                ),
              )),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
    );
  }
}

class _SecurityTab extends StatelessWidget {
  final UserRemoteModel user;
  final List<Map<String, dynamic>> mainServices;
  const _SecurityTab({required this.user, this.mainServices = const []});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('الأدوار والصلاحيات'),
        Wrap(
          spacing: 8,
          children: user.roles
              .map((r) => Chip(
                    label: Text(r.translatedName(context), style: const TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: context.themeColor.primary.withValues(alpha: 0.1),
                    onDeleted: () => _confirmRoleRemoval(context, r),
                  ))
              .toList(),
        ),
        TextButton.icon(
          onPressed: () => _showAddRoleDialog(context),
          icon: const Icon(Icons.add_moderator_rounded),
          label: const Text('إضافة دور جديد', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
    );
  }

  void _confirmRoleRemoval(BuildContext context, UserRole role) {
    final cubit = context.read<UserDetailCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد سحب الصلاحية', style: TextStyle(fontFamily: 'Cairo')),
        content: Text('هل أنت متأكد من سحب دور ${role.translatedName(context)} من المستخدم؟', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.removeRole(user.id, role);
            },
            child: const Text('نعم، سحب الصلاحية', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddRoleDialog(BuildContext context) {
    final cubit = context.read<UserDetailCubit>();
    final availableRoles = UserRole.values.where((r) => !user.roles.contains(r)).toList();
    if (availableRoles.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) => BlocProvider.value(
        value: cubit,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر الدور لإضافته', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              ...availableRoles.map((role) => ListTile(
                    title: Text(role.translatedName(modalContext), style: const TextStyle(fontFamily: 'Cairo')),
                    onTap: () {
                      Navigator.pop(modalContext);
                      if (role == UserRole.technician) {
                        _showMainServiceDialog(context, cubit);
                      } else {
                        cubit.assignRole(user.id, role);
                      }
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showMainServiceDialog(BuildContext context, UserDetailCubit cubit) {
    if (mainServices.isEmpty) {
      cubit.assignRole(user.id, UserRole.technician);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الخدمة الأساسية للفني', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text(
          'يجب أن ينتمي الفني لخدمة أساسية واحدة (مثال: تنظيف، صيانة). اختر الخدمة:',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
        ),
        actions: [
          ...mainServices.map((ms) => TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  cubit.assignRole(user.id, UserRole.technician, mainServiceId: ms['id']);
                },
                child: Text(ms['title']?['ar'] ?? ms['id'], style: const TextStyle(fontFamily: 'Cairo')),
              )),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.assignRole(user.id, UserRole.technician);
            },
            child: const Text('تعيين كفني عام (لا ينصح)', style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        ],
      ),
    );
  }
}

class _TechnicianTab extends StatelessWidget {
  final UserRemoteModel user;
  final TechnicianProfileRemoteModel? technicianProfile;
  final List<CapacityPoolRemoteModel> capacityPools;
  final List<TechnicianSkillRemoteModel> technicianSkills;
  final List<Map<String, dynamic>> availableSubServices;
  final List<Map<String, dynamic>> mainServices;

  const _TechnicianTab({
    required this.user,
    required this.technicianProfile,
    required this.capacityPools,
    required this.technicianSkills,
    required this.availableSubServices,
    required this.mainServices,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (technicianProfile != null) ...[
          _buildTechnicianSummary(context),
          const SizedBox(height: 24),
        ],
        
        // 1. Main Service Selection
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('الخدمة الأساسية للفني'),
            if (technicianProfile?.mainServiceId == null)
              TextButton.icon(
                onPressed: () => _updateMainService(context),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('تعيين'),
              )
            else
               TextButton.icon(
                onPressed: () => _updateMainService(context),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('تغيير'),
              )
          ],
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.home_repair_service_rounded)),
            title: Text(
              _getMainServiceName(technicianProfile?.mainServiceId),
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('تحدد هذه الخدمة الخدمات الفرعية التي يمكن إسنادها للفني.', style: TextStyle(fontSize: 11)),
          ),
        ),
        const SizedBox(height: 24),

        // 2. Capacity Pools
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             _buildSectionTitle('خزانات القدرة (Capacity Pools)'),
             IconButton(
               onPressed: () => _showUpsertPoolDialog(context),
               icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
             ),
          ],
        ),
        if (capacityPools.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('لا توجد خزانات سعة معرفة', style: TextStyle(color: Colors.grey))),
          )
        else
          ...capacityPools.map((pool) => _buildPoolItem(context, pool)),

        const SizedBox(height: 24),

        // 3. Skills (Mapped Services)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             _buildSectionTitle('الخدمات المسندة (Skills)'),
             if (capacityPools.isNotEmpty)
               IconButton(
                 onPressed: () => _showAddSkillDialog(context),
                 icon: const Icon(Icons.add_circle_outline, color: Colors.green),
               ),
          ],
        ),
        if (capacityPools.isEmpty)
           const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('يجب إضافة خزان سعة أولاً لربط الخدمات به', style: TextStyle(color: Colors.red, fontSize: 13)),
          ),
        if (technicianSkills.isEmpty && capacityPools.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('لم يتم إسناد أي خدمات بعد', style: TextStyle(color: Colors.grey))),
          )
        else
          ...technicianSkills.map((skill) => _buildSkillItem(context, skill)),
      ],
    );
  }

  String _getMainServiceName(String? id) {
    if (id == null) return 'غير محددة';
    final ms = mainServices.firstWhere((e) => e['id'] == id, orElse: () => <String, dynamic>{});
    if (ms.isEmpty) return id;
    return ms['title']?['ar'] ?? id;
  }
  
  String _getPoolName(String poolId) {
    final pool = capacityPools.firstWhere((e) => e.id == poolId);
    return pool.title;
  }

  Widget _buildTechnicianSummary(BuildContext context) {
    final tech = technicianProfile!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSimpleStat('التقييم', tech.rating.toStringAsFixed(1), Icons.star_rounded, Colors.amber),
          _buildDivider(),
          _buildSimpleStat('الطلبات', tech.completedJobs.toString(), Icons.check_circle_rounded, context.themeColor.primary),
          _buildDivider(),
          _buildSimpleStat('التوثيق', tech.isVerified ? 'موثق' : 'غير موثق', tech.isVerified ? Icons.verified_user_rounded : Icons.info_outline_rounded, tech.isVerified ? Colors.green : Colors.grey),
        ],
      ),
    );
  }

  Widget _buildPoolItem(BuildContext context, CapacityPoolRemoteModel pool) {
    final linkedSkillsCount = technicianSkills.where((s) => s.capacityPoolId == pool.id).length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.bubble_chart_rounded, color: Colors.blue),
        ),
        title: Text(pool.title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('القدرة: ${pool.maxDailyCapacity}', style: const TextStyle(fontSize: 12)),
            if (linkedSkillsCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: technicianSkills
                      .where((s) => s.capacityPoolId == pool.id)
                      .take(3)
                      .map((s) {
                        final title = availableSubServices.firstWhere(
                          (sub) => sub['id'] == s.subServiceId,
                          orElse: () => {'title': {'ar': s.subServiceId}},
                        )['title']?['ar'] ?? s.subServiceId;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(title, style: const TextStyle(fontSize: 9, fontFamily: 'Cairo', color: Colors.blue)),
                        );
                      })
                      .toList(),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
              onPressed: () => _showUpsertPoolDialog(context, pool: pool),
            ),
             IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: () => _confirmPoolRemoval(context, pool, linkedSkillsCount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillItem(BuildContext context, TechnicianSkillRemoteModel skill) {
    final subServiceTitle = availableSubServices.firstWhere(
      (s) => s['id'] == skill.subServiceId, 
      orElse: () => {'title': {'ar': skill.subServiceId}}
    )['title']?['ar'] ?? skill.subServiceId;

    return Card(
       margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_outline, color: Colors.green),
        ),
        title: Text(subServiceTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        subtitle: Text('خزان السعة: ${_getPoolName(skill.capacityPoolId)}', style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: skill.isActive,
              onChanged: (val) {
                context.read<UserDetailCubit>().toggleSkillActive(
                  technicianId: user.id, skillId: skill.id, isActive: val);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: () => _confirmSkillRemoval(context, skill, subServiceTitle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.2));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
    );
  }

  void _updateMainService(BuildContext context) {
    final cubit = context.read<UserDetailCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعيين الخدمة الأساسية', style: TextStyle(fontFamily: 'Cairo')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: mainServices.map((ms) => ListTile(
            title: Text(ms['title']?['ar'] ?? ms['id'], style: const TextStyle(fontFamily: 'Cairo')),
            onTap: () {
              Navigator.pop(dialogContext);
              cubit.setMainService(user.id, ms['id']);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showUpsertPoolDialog(BuildContext context, {CapacityPoolRemoteModel? pool}) {
    final cubit = context.read<UserDetailCubit>();
    String title = pool?.title ?? '${user.firstName} ${user.lastName} - ';
    int capacity = pool?.maxDailyCapacity ?? 5;
    final themeColor = context.themeColor;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: themeColor.cardBackground,
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeColor.primary.withValues(alpha:0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          pool == null ? Icons.add_business_rounded : Icons.edit_note_rounded,
                          color: themeColor.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        pool == null ? 'إضافة خزان سعة' : 'تعديل الخزان',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                          color: themeColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'اسم الخزان',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: themeColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BaseTextFormField(
                    controller: TextEditingController(text: title),
                    hint: 'أدخل اسم الخزان...',
                    fillColor: themeColor.background,
                    radius: 12,
                    onChanged: (val) => title = val,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'القدرة اليومية القصوى',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: themeColor.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColor.primary.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$capacity طلبات',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: themeColor.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 10, // 0 to 9
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final isSelected = capacity == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() => capacity = index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 55,
                            decoration: BoxDecoration(
                              color: isSelected ? themeColor.primary : themeColor.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? themeColor.primary : themeColor.unselectedItem.withValues(alpha:0.2),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: themeColor.primary.withValues(alpha:0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                index.toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                  color: isSelected ? Colors.white : themeColor.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              color: themeColor.secondaryText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (title.trim().isEmpty) return;
                            Navigator.pop(dialogContext);
                            cubit.upsertPool(
                              technicianId: user.id,
                              poolId: pool?.id,
                              title: title.trim(),
                              maxDailyCapacity: capacity,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'حفظ الخزان',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _confirmPoolRemoval(BuildContext context, CapacityPoolRemoteModel pool, int linkedSkills) {
    if (linkedSkills > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن حذف الخزان لارتباطه بخدمات. احذف الخدمات أولاً.', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }
    
    final cubit = context.read<UserDetailCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الخزان', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')),
        content: Text('هل أنت متأكد من حذف خزان السعة "${pool.title}"؟', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.deletePool(user.id, pool.id);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddSkillDialog(BuildContext context) {
    final cubit = context.read<UserDetailCubit>();
    final assignedSubServiceIds = technicianSkills.map((e) => e.subServiceId).toSet();
    final filteredAvailable = availableSubServices.where((e) => !assignedSubServiceIds.contains(e['id'])).toList();

    if (filteredAvailable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جميع الخدمات مسندة بالفعل لهذا الفني', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    final Set<String> selectedSubServiceIds = {};
    String? selectedPoolId = capacityPools.isNotEmpty ? capacityPools.first.id : null;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة خدمات للفني', style: TextStyle(fontFamily: 'Cairo')),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (capacityPools.isNotEmpty)
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: selectedPoolId,
                    items: capacityPools
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => selectedPoolId = val),
                    decoration: const InputDecoration(labelText: 'الربط بخزان السعة'),
                  ),
                const SizedBox(height: 16),
                const Text('اختر الخدمات الفرعية:', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredAvailable.length,
                      itemBuilder: (context, index) {
                        final item = filteredAvailable[index];
                        final id = item['id'] as String;
                        final isSelected = selectedSubServiceIds.contains(id);
                        return CheckboxListTile(
                          title: Text(item['title']?['ar'] ?? id, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedSubServiceIds.add(id);
                              } else {
                                selectedSubServiceIds.remove(id);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: selectedSubServiceIds.isEmpty || selectedPoolId == null
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                      cubit.assignSkills(
                        technicianId: user.id,
                        subServiceIds: selectedSubServiceIds.toList(),
                        capacityPoolId: selectedPoolId!,
                      );
                    },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSkillRemoval(BuildContext context, TechnicianSkillRemoteModel skill, String title) {
    final cubit = context.read<UserDetailCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الخدمة', style: TextStyle(fontFamily: 'Cairo')),
        content: Text('هل أنت متأكد من حذف خدمة $title من قائمة خدمات الفني؟', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.removeSkill(technicianId: user.id, skillId: skill.id);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final List<AuditLogRemoteModel> logs;
  const _ActivityTab({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(child: Text('لا توجد سجلات نشاط حالياً', style: TextStyle(fontFamily: 'Cairo')));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: context.themeColor.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.history_rounded, size: 20),
            ),
            title: Text(
              log.newStatus != null ? 'تغيير الحالة إلى: ${log.newStatus}' : 'عملية على الحساب',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'التاريخ: ${log.createdAt.toLocal().toString().split('.')[0]}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
