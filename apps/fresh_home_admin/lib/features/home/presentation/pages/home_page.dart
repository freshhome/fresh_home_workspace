import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/data/service/datasources/service_remote_datasource.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});



  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        title: const Text(
          'الرئيسية (لوحة التحكم)',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: themeColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحباً بك مجدداً!',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'إليك ملخص سريع لإدارة البيانات والخدمات السحابية.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: themeColor.unselectedItem.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),

                //! اداره جدول الحجز
                _buildFeatureCard(
                  context,
                  title: 'إدارة جدول الحجز',
                  description:
                      'متابعة حية لسعة الفريق، إحصائيات الإشغال وإعادة توجيه المهام.',
                  icon: Icons.edit_calendar_rounded,
                  color: Colors.purple,
                  onTap: () =>
                      GoRouter.of(context).pushNamed('admin_dashboard'),
                ),
                const SizedBox(height: 16),

                //! اداره الخدمات
                _buildFeatureCard(
                  context,
                  title: 'إدارة الخدمات',
                  description:
                      'إدارة وتعديل الفئات، الخدمات الفرعية، وتفاصيل الأسعار.',
                  icon: Icons.design_services_rounded,
                  color: themeColor.primary,
                  onTap: () => GoRouter.of(
                    context,
                  ).pushNamed(AppRoutes.servicesManagement),
                ),
                const SizedBox(height: 16),

                //! اداره اسعار الخدمات
                _buildFeatureCard(
                  context,
                  title: "اداره اسعار الخدمات",
                  description:
                      'تعديل قوانين AST الشرطية، إدارة الخصومات التراكمية، ومراجعة سجل التدقيق.',
                  icon: Icons.gavel_rounded,
                  color: Colors.amber.shade800,
                  onTap: () => GoRouter.of(context).push('/pricing-governance'),
                ),
                const SizedBox(height: 16),
                // ! اداره الحجوزات
                _buildFeatureCard(
                  context,
                  title: 'إدارة الحجوزات',
                  description:
                      'تتبع الحجوزات، إعادة التعيين، الجدولة وإلغاء الطلبات.',
                  icon: Icons.calendar_month_rounded,
                  color: Colors.blueAccent,
                  onTap: () => GoRouter.of(context).push('/admin/bookings'),
                ),
                const SizedBox(height: 16),
                // ! اداره المستخدمين
                _buildFeatureCard(
                  context,
                  title: 'إدارة المستخدمين',
                  description:
                      'عرض وإدارة بيانات المستخدمين والأدوار في المنصة.',
                  icon: Icons.people_alt_rounded,
                  color: Colors.orange,
                  onTap: () => GoRouter.of(
                    context,
                  ).pushNamed(AppRoutes.adminUserManagement),
                ),
                const SizedBox(height: 16),

                //! عرض الخدمات (Supabase)
                _buildFeatureCard(
                  context,
                  title: 'عرض الخدمات (Supabase)',
                  description:
                      'استعراض الخدمات المهاجرة وتفاصيل الفروع والأسعار بدقة.',
                  icon: Icons.cloud_done_rounded,
                  color: Colors.teal,
                  onTap: () => GoRouter.of(
                    context,
                  ).pushNamed(AppRoutes.adminSupabaseServices),
                ),
                const SizedBox(height: 16),
                // ! تجربه جلب الخدمات
                _buildFeatureCard(
                  context,
                  title: 'تجربه جلب الخدمات',
                  description: 'تجربه جلب الخدمات',
                  icon: Icons.architecture_rounded,
                  color: const Color.fromARGB(255, 245, 131, 2),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Testpage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildFeatureCard(
  BuildContext context, {
  required String title,
  required String description,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  final themeColor = context.themeColor;

  return Container(
    decoration: BoxDecoration(
      color: themeColor.cardBackground,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: themeColor.unselectedItem.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: themeColor.unselectedItem.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class Testpage extends StatefulWidget {
  const Testpage({super.key});

  @override
  State<Testpage> createState() => _TestpageState();
}

class _TestpageState extends State<Testpage> {
  bool _isLoading = false;
  int? _serviceCount;
  String? _error;

  Future<void> _fetchServicesCount() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dataSource = GetIt.instance<ServiceRemoteDataSource>();
      final services = await dataSource.getServices();
      setState(() {
        _serviceCount = services.length;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [TestPage] Error fetching services: $e');
      debugPrint('📋 StackTrace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        title: const Text(
          'اختبار جلب البيانات مباشرة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: themeColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchServicesCount,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text(
                  'جلب البيانات مباشرة من Supabase',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: themeColor.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading) ...[
                          CircularProgressIndicator(color: themeColor.primary),
                          const SizedBox(height: 16),
                          const Text(
                            'جاري الاتصال بـ Supabase وجلب البيانات...',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ] else if (_error != null) ...[
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.redAccent,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ أثناء الاتصال:',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                          ),
                        ] else if (_serviceCount != null) ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: themeColor.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.home_repair_service_rounded,
                              color: themeColor.primary,
                              size: 72,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'إجمالي عدد الخدمات في الجدول:',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_serviceCount',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: themeColor.primary,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.cloud_download_outlined,
                            color: themeColor.primary.withValues(alpha: 0.5),
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'اضغط على الزر أعلاه لجلب عدد الخدمات مباشرة من قاعدة البيانات.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
