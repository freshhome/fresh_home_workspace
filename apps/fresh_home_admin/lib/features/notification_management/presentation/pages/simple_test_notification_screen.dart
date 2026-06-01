import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// بيانات مستخدم مسجل لديه FCM Token
class _RegisteredUser {
  final String userId;
  final String fcmToken;
  final String firstName;
  final String lastName;
  final String email;
  final List<String> roles;
  final DateTime updatedAt;

  _RegisteredUser({
    required this.userId,
    required this.fcmToken,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.roles,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get primaryRole {
    if (roles.contains('admin')) return 'admin';
    if (roles.contains('technician')) return 'technician';
    return 'client';
  }

  bool get isClient => primaryRole == 'client';
}

class SimpleTestNotificationScreen extends StatefulWidget {
  const SimpleTestNotificationScreen({super.key});

  @override
  State<SimpleTestNotificationScreen> createState() =>
      _SimpleTestNotificationScreenState();
}

class _SimpleTestNotificationScreenState
    extends State<SimpleTestNotificationScreen> {
  final _tokenController = TextEditingController();
  final _titleController = TextEditingController(text: 'تجربة الإشعارات');
  final _bodyController = TextEditingController(text: 'مرحباً، هل وصلك هذا؟');

  bool _isLoading = false;
  bool _isFetchingUsers = false;
  List<_RegisteredUser> _registeredUsers = [];
  List<_RegisteredUser> _filteredUsers = [];
  _RegisteredUser? _selectedUser;
  String _roleFilter = 'client'; // 'all' | 'client' | 'admin' | 'technician'

  @override
  void initState() {
    super.initState();
    _fetchRegisteredUsers();
    _tokenController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _fetchRegisteredUsers() async {
    setState(() => _isFetchingUsers = true);
    debugPrint(
      '🔵 [TestScreen] Fetching via RPC: get_all_fcm_tokens_for_admin...',
    );
    try {
      // ✅ Use a SECURITY DEFINER RPC function — bypasses RLS and join issues.
      // The function validates the caller is an admin on the server side.
      final response = await Supabase.instance.client.rpc(
        'get_all_fcm_tokens_for_admin',
      );

      debugPrint(
        '🟢 [TestScreen] RPC returned ${(response as List).length} token entries.',
      );

      final List<_RegisteredUser> users = [];
      for (final row in response) {
        final rolesRaw = row['roles'];
        List<String> roleNames = [];
        if (rolesRaw is List) {
          roleNames = rolesRaw.map((e) => e.toString()).toList();
        }
        if (roleNames.isEmpty || roleNames.every((r) => r == 'null')) {
          roleNames = ['client'];
        }

        users.add(
          _RegisteredUser(
            userId: row['user_id'] as String,
            fcmToken: row['fcm_token'] as String,
            firstName: row['first_name'] as String? ?? '',
            lastName: row['last_name'] as String? ?? '',
            email: row['email'] as String? ?? '',
            roles: roleNames,
            updatedAt: DateTime.parse(row['updated_at'] as String),
          ),
        );
      }

      setState(() {
        _registeredUsers = users;
        _isFetchingUsers = false;
      });
      _applyRoleFilter();
    } catch (e) {
      debugPrint('🔴 [TestScreen] RPC Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب المستخدمين: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isFetchingUsers = false);
    }
  }

  void _applyRoleFilter() {
    setState(() {
      if (_roleFilter == 'all') {
        _filteredUsers = List.from(_registeredUsers);
      } else {
        _filteredUsers = _registeredUsers
            .where((u) => u.primaryRole == _roleFilter)
            .toList();
      }
    });
  }

  void _setRoleFilter(String filter) {
    _roleFilter = filter;
    _applyRoleFilter();
    // Clear selection if selected user no longer matches filter
    if (_selectedUser != null && !_filteredUsers.contains(_selectedUser)) {
      setState(() {
        _selectedUser = null;
        _tokenController.clear();
      });
    }
  }

  void _selectUser(_RegisteredUser user) {
    setState(() {
      _selectedUser = user;
      _tokenController.text = user.fcmToken;
    });
  }

  Future<void> _sendTestPush() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار مستخدم أو إدخال رمز الجهاز يدوياً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final targetName = _selectedUser?.fullName ?? token.substring(0, 8);
    debugPrint('🟡 [TestScreen] Sending to: $targetName ...');

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'test-send-push',
        body: {
          'token': token,
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
        },
      );

      debugPrint('✅ [TestScreen] Status: ${response.status}');
      debugPrint('✅ [TestScreen] Data: ${response.data}');

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Text('تم الإرسال بنجاح'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedUser != null) ...[
                  Text(
                    'المستلم: ${_selectedUser!.fullName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'البريد: ${_selectedUser!.email}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const Divider(height: 20),
                ],
                Text(
                  'الرد من السيرفر:',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  response.data.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } catch (e, stacktrace) {
      debugPrint('🔴 [TestScreen] Exception: $e');
      debugPrint('🔴 STACKTRACE: $stacktrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مختبر الإشعارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث القائمة',
            onPressed: _fetchRegisteredUsers,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Info Banner ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'اختر عميلاً مسجلاً لديه FCM Token لإرسال إشعار تجريبي مباشرةً عبر Firebase.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Role Filter Chips ─────────────────────────────
            _buildRoleFilter(colorScheme),
            const SizedBox(height: 20),

            // ── Registered Users Section ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_roleFilterLabel()} (${_filteredUsers.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isFetchingUsers)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (_isFetchingUsers && _filteredUsers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filteredUsers.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_search,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _registeredUsers.isEmpty
                          ? 'لا يوجد أجهزة مسجلة بعد'
                          : 'لا يوجد ${_roleFilterLabel()} مسجلون',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _registeredUsers.isEmpty
                          ? 'سجّل الدخول من أي تطبيق لظهور الجهاز هنا'
                          : 'جرّب تغيير فلتر الدور للاطلاع على باقي المستخدمين',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredUsers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  final isSelected =
                      _selectedUser?.userId == user.userId &&
                      _selectedUser?.fcmToken == user.fcmToken;
                  return _UserTokenCard(
                    user: user,
                    isSelected: isSelected,
                    onTap: () => _selectUser(user),
                  );
                },
              ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // ── Selected / Manual Token ───────────────────────
            if (_selectedUser != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_pin,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سيتم الإرسال إلى: ${_selectedUser!.fullName}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            _selectedUser!.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _selectedUser = null;
                          _tokenController.clear();
                        });
                      },
                      tooltip: 'إلغاء الاختيار',
                    ),
                  ],
                ),
              ),

            TextFormField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'رمز الجهاز (FCM Token)',
                hintText: 'أو أدخل الرمز يدوياً...',
                border: const OutlineInputBorder(),
                suffixIcon: _tokenController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'نسخ الرمز',
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _tokenController.text),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ الرمز ✅'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      )
                    : null,
              ),
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // ── Message Content ───────────────────────────────
            Text(
              'محتوى الإشعار',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'النص',
                prefixIcon: Icon(Icons.message_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // ── Send Button ───────────────────────────────────
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: _isLoading ? null : _sendTestPush,
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isLoading
                    ? 'جارٍ الإرسال...'
                    : _selectedUser != null
                    ? 'إرسال إلى ${_selectedUser!.fullName} 🚀'
                    : 'إرسال الآن 🚀',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Pipeline Diagnostic Card ──────────────────────
            _buildPipelineCard(colorScheme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Role Filter Helper ─────────────────────────────────────
  String _roleFilterLabel() {
    switch (_roleFilter) {
      case 'client':
        return 'العملاء';
      case 'admin':
        return 'المديرون';
      case 'technician':
        return 'الفنيون';
      default:
        return 'جميع المستخدمين';
    }
  }

  Widget _buildRoleFilter(ColorScheme colorScheme) {
    final filters = [
      ('client', 'عملاء فقط', Icons.person, const Color(0xFF047857)),
      ('technician', 'فنيون', Icons.build, const Color(0xFF0369A1)),
      ('admin', 'مديرون', Icons.admin_panel_settings, const Color(0xFF7C3AED)),
      ('all', 'الكل', Icons.people_alt, Colors.grey),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isActive = _roleFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(
              selected: isActive,
              avatar: Icon(
                f.$3,
                size: 16,
                color: isActive ? Colors.white : f.$4,
              ),
              label: Text(f.$2),
              onSelected: (_) => _setRoleFilter(f.$1),
              selectedColor: f.$4,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : f.$4,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              backgroundColor: f.$4.withValues(alpha: 0.08),
              side: BorderSide(
                color: isActive ? f.$4 : f.$4.withValues(alpha: 0.3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Pipeline Diagnostic Card ────────────────────────────────
  Widget _buildPipelineCard(ColorScheme colorScheme) {
    final steps = [
      _PipelineStep(
        icon: Icons.phone_android,
        title: 'العميل يُسجّل الـ FCM Token',
        detail: 'عند تسجيل الدخول → FcmTokenManager → user_fcm_tokens',
        ok: true,
      ),
      _PipelineStep(
        icon: Icons.storage,
        title: 'Supabase يحفظ الـ Token',
        detail: 'جدول user_fcm_tokens  •  upsert على (user_id, device_id)',
        ok: true,
      ),
      _PipelineStep(
        icon: Icons.cloud_upload,
        title: 'Admin يستدعي Edge Function',
        detail: 'functions.invoke("test-send-push") → {token, title, body}',
        ok: true,
      ),
      _PipelineStep(
        icon: Icons.vpn_key,
        title: 'Edge Function تُصادق مع Google',
        detail: 'FCM_SERVICE_ACCOUNT → OAuth2 Access Token',
        ok: true,
      ),
      _PipelineStep(
        icon: Icons.send,
        title: 'إرسال عبر FCM v1 API',
        detail: 'fcm.googleapis.com/v1/projects/{id}/messages:send',
        ok: true,
      ),
      _PipelineStep(
        icon: Icons.notifications_active,
        title: 'العميل يستقبل الإشعار',
        detail:
            'FirebaseMessagingHandler → foreground / background / terminated',
        ok: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'مسار الإشعار (FCM Pipeline)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((e) {
            final i = e.key;
            final step = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: step.ok
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.red.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          step.ok ? Icons.check : Icons.close,
                          size: 14,
                          color: step.ok ? Colors.green.shade700 : Colors.red,
                        ),
                      ),
                      if (i < steps.length - 1)
                        Container(
                          width: 1,
                          height: 18,
                          color: Colors.grey.shade300,
                          margin: const EdgeInsets.only(top: 2, bottom: 2),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          step.detail,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PipelineStep {
  final IconData icon;
  final String title;
  final String detail;
  final bool ok;
  const _PipelineStep({
    required this.icon,
    required this.title,
    required this.detail,
    required this.ok,
  });
}

// ─────────────────────────────────────────────────────────────
// User Token Card Widget
// ─────────────────────────────────────────────────────────────

class _UserTokenCard extends StatelessWidget {
  final _RegisteredUser user;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserTokenCard({
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  Color get _roleColor {
    switch (user.primaryRole) {
      case 'admin':
        return const Color(0xFF7C3AED); // purple
      case 'technician':
        return const Color(0xFF0369A1); // blue
      default:
        return const Color(0xFF047857); // green
    }
  }

  String get _roleLabel {
    switch (user.primaryRole) {
      case 'admin':
        return 'مدير';
      case 'technician':
        return 'فني';
      default:
        return 'عميل';
    }
  }

  IconData get _roleIcon {
    switch (user.primaryRole) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'technician':
        return Icons.build;
      default:
        return Icons.person;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected ? color.withValues(alpha: 0.06) : Colors.white,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Avatar / Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(_roleIcon, color: color, size: 22),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.fullName.isEmpty
                                ? 'مستخدم بدون اسم'
                                : user.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _roleLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email.isEmpty ? 'لا يوجد بريد إلكتروني' : user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 11,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'سجّل Token ${_formatTime(user.updatedAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Selected Checkmark or Arrow
              if (isSelected)
                Icon(Icons.check_circle, color: color, size: 22)
              else
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade300,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
