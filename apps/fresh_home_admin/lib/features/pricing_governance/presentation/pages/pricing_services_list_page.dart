import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/di/injection_container.dart';

class PricingServicesListPage extends StatefulWidget {
  const PricingServicesListPage({super.key});

  @override
  State<PricingServicesListPage> createState() => _PricingServicesListPageState();
}

class _PricingServicesListPageState extends State<PricingServicesListPage> {
  Future<List<Map<String, dynamic>>>? _servicesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _servicesFuture = _fetchServices();
  }

  Future<void> _handleRefresh() async {
    final future = _fetchServices();
    setState(() {
      _servicesFuture = future;
    });
    try {
      await future;
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _fetchServices() async {
    // 1. Sync all services in the background so local Hive cache is updated
    try {
      await getIt<SyncServicesUseCase>().call();
    } catch (e) {
      debugPrint('⚠️ [PricingServicesListPage] syncServices failed: $e');
    }

    // 2. Fetch the list directly from Supabase for UI update
    final response = await Supabase.instance.client
        .from('services')
        .select('id, title, image, is_bookable, sort_order')
        .eq('is_bookable', true)
        .order('sort_order');

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _servicesFuture ??= _fetchServices();
    final themeColor = context.themeColor;

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        title: const Text(
          'إدارة أسعار الخدمات',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: themeColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Search Bar Section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: themeColor.cardBackground,
              child: TextFormField(
                controller: _searchController,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: themeColor.textPrimary,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن خدمة...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: themeColor.unselectedItem.withValues(alpha: 0.5),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: themeColor.unselectedItem.withValues(alpha: 0.5),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  fillColor: themeColor.background,
                  filled: true,
                ),
              ),
            ),
            // Services List Section
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _servicesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    debugPrint('❌ [PricingServicesListPage load error]: ${snapshot.error}');
                    return RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      size: 48,
                                      color: Colors.redAccent.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'فشل تحميل قائمة الخدمات.',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: _handleRefresh,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text(
                                        'إعادة المحاولة',
                                        style: TextStyle(fontFamily: 'Cairo'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final allServices = snapshot.data ?? [];
                  final filteredServices = allServices.where((item) {
                    final titleMap = item['title'] as Map<String, dynamic>? ?? {};
                    final String titleAr = (titleMap['ar'] ?? '').toString().toLowerCase();
                    final String titleEn = (titleMap['en'] ?? '').toString().toLowerCase();
                    return titleAr.contains(_searchQuery) || titleEn.contains(_searchQuery);
                  }).toList();

                  if (filteredServices.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 56,
                                      color: themeColor.unselectedItem.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isEmpty ? 'لا توجد خدمات متاحة حالياً.' : 'لا توجد نتائج بحث مطابقة.',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13,
                                        color: themeColor.unselectedItem,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                      final item = filteredServices[index];
                      final id = item['id'] as String;
                      final titleMap = item['title'] as Map<String, dynamic>? ?? {};
                      final String title = titleMap['ar'] ?? titleMap['en'] ?? id;
                      final String? imageUrl = item['image'] as String?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: themeColor.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: themeColor.unselectedItem.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              context.push('/pricing-governance/$id');
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Service Icon Container
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: themeColor.serviceIconBackground,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: themeColor.unselectedItem.withValues(alpha: 0.05),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: imageUrl != null && imageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              fit: BoxFit.contain,
                                              placeholder: (context, url) => const Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                              errorWidget: (context, url, error) =>
                                                  _buildPlaceholderIcon(themeColor),
                                            )
                                          : _buildPlaceholderIcon(themeColor),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Service Title & Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: themeColor.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'تعديل وإدارة الهيكل التسعيري والمحاكاة',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 11,
                                            color: themeColor.unselectedItem,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Edit Action Button (Indicating price modification)
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: themeColor.primary.withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.price_change_rounded,
                                      color: themeColor.primary,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(ThemeColorExtension themeColor) {
    return Center(
      child: Icon(
        Icons.cleaning_services_rounded,
        size: 24,
        color: themeColor.primary.withValues(alpha: 0.4),
      ),
    );
  }
}
