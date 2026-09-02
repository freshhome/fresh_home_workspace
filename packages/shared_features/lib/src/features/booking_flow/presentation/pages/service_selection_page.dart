import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/service/entities/service_entity.dart';
import 'package:shared/domain/service/enums/service_status.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/booking_flow_state.dart';

/// Admin booking flow Step 0:
/// Hierarchical recursive service selection tree matching the customer_web experience.
/// Features:
/// - 2-column square card grid
/// - Smooth animated transition elevating the selected category to a top origin banner
/// - Top banner shows icon, title, description, and "رجوع خطوة" (Back step) button
/// - Recursive navigation for nested categories
/// - Instant transition to next step upon selecting a bookable leaf service
class ServiceSelectionPage extends StatefulWidget {
  const ServiceSelectionPage({super.key});

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {
  final ScrollController _scrollController = ScrollController();
  List<ServiceEntity> _allServices = [];
  final List<ServiceEntity> _selectedPath = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllServices();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllServices() async {
    final cubit = context.read<BookingFlowCubit>();
    if (cubit.serviceRepository == null) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _error = l10n?.error_service_repository_unavailable ?? 'Service repository unavailable';
        _loading = false;
      });
      return;
    }

    final result = await cubit.serviceRepository!.getAllServices();
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _loading = false;
      }),
      (services) => setState(() {
        _allServices = services;
        _loading = false;
      }),
    );
  }

  List<ServiceEntity> _getChildren(String? parentId) {
    return _allServices.where((s) => s.parentId == parentId).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  bool _hasChildren(ServiceEntity node) {
    return _allServices.any((s) => s.parentId == node.id);
  }

  bool _isBookableLeaf(ServiceEntity node) {
    return node.isBookable && !_hasChildren(node);
  }

  void _onServiceNodeTap(ServiceEntity node) {
    if (node.status == ServiceStatus.paused) return;

    if (_isBookableLeaf(node)) {
      // 1. Select service in Cubit
      context.read<BookingFlowCubit>().selectService(node);
      // 2. Automatically advance to next step (Pricing)
      context.read<BookingFlowCubit>().nextStep();
    } else {
      // Branch node: elevate to parent banner and show sub-services
      setState(() {
        _selectedPath.add(node);
      });
      _scrollToTop();
    }
  }

  void _handleBackHierarchy() {
    if (_selectedPath.isNotEmpty) {
      setState(() {
        _selectedPath.removeLast();
      });
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String? _resolveImageUrl(String? image) {
    if (image == null || image.trim().isEmpty) return null;
    final clean = image.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    try {
      return Supabase.instance.client.storage
          .from('service_images')
          .getPublicUrl(clean);
    } catch (_) {
      return null;
    }
  }

  IconData _getServiceFallbackIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('تشطيب') ||
        t.contains('عميق') ||
        t.contains('تنظيف') ||
        t.contains('clean')) {
      return Icons.cleaning_services_rounded;
    }
    if (t.contains('أثاث') ||
        t.contains('كنب') ||
        t.contains('سجاد') ||
        t.contains('مفروشات') ||
        t.contains('مجالس')) {
      return Icons.chair_rounded;
    }
    if (t.contains('زجاج') ||
        t.contains('واجهات') ||
        t.contains('شبابيك') ||
        t.contains('window')) {
      return Icons.window_rounded;
    }
    if (t.contains('تكييف') ||
        t.contains('تبريد') ||
        t.contains('فريون') ||
        t.contains('ac')) {
      return Icons.ac_unit_rounded;
    }
    if (t.contains('سباكة') ||
        t.contains('مواسير') ||
        t.contains('صرف') ||
        t.contains('plumb')) {
      return Icons.plumbing_rounded;
    }
    if (t.contains('كهرباء') ||
        t.contains('إضاءة') ||
        t.contains('صيانة') ||
        t.contains('mainten')) {
      return Icons.electric_bolt_rounded;
    }
    if (t.contains('حشرات') ||
        t.contains('إبادة') ||
        t.contains('مكافحة') ||
        t.contains('pest')) {
      return Icons.pest_control_rounded;
    }
    if (t.contains('دوري') || t.contains('يومي') || t.contains('calendar')) {
      return Icons.calendar_month_rounded;
    }
    return Icons.category_rounded;
  }

  Color _getServiceTint(String title, ThemeColorExtension themeColor) {
    final t = title.toLowerCase();
    if (t.contains('تنظيف') || t.contains('clean')) {
      return const Color(0xFF0284C7); // Sky
    }
    if (t.contains('صيانة') ||
        t.contains('mainten') ||
        t.contains('كهرباء') ||
        t.contains('سباكة') ||
        t.contains('تكييف')) {
      return const Color(0xFFEA580C); // Orange
    }
    if (t.contains('حشرات') || t.contains('pest') || t.contains('تعقيم')) {
      return const Color(0xFF16A34A); // Emerald
    }
    return themeColor.primary;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: themeColor.error),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: themeColor.error, fontFamily: 'Cairo'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadAllServices();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final currentParent = _selectedPath.isNotEmpty ? _selectedPath.last : null;
    final currentLevelNodes = _getChildren(currentParent?.id);

    return PopScope(
      canPop: _selectedPath.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedPath.isNotEmpty) {
          _handleBackHierarchy();
        }
      },
      child: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          return SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_selectedPath.map((s) => s.id).join('-')),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Parent Card (Banner) when drilled into children
                    if (currentParent != null)
                      _buildParentBanner(
                        parent: currentParent,
                        themeColor: themeColor,
                        themeText: themeText,
                        isArabic: isArabic,
                      ),

                    // Section Heading
                    _buildSectionHeader(
                      currentParent: currentParent,
                      themeColor: themeColor,
                      themeText: themeText,
                      l10n: l10n,
                      isArabic: isArabic,
                    ),
                    const SizedBox(height: 16),

                    // 2-Column Square Cards Grid
                    if (currentLevelNodes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Text(
                          'لا توجد خدمات متاحة في هذا القسم حالياً',
                          style: TextStyle(
                            color: themeColor.secondaryText,
                            fontFamily: 'Cairo',
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                        itemCount: currentLevelNodes.length,
                        itemBuilder: (context, index) {
                          final node = currentLevelNodes[index];
                          final children = _getChildren(node.id);
                          final isBookableLeaf = _isBookableLeaf(node);
                          final isPaused = node.status == ServiceStatus.paused;
                          final isSelected =
                              state.service?.subServiceId == node.id;

                          return _buildServiceCard(
                            service: node,
                            isBookableLeaf: isBookableLeaf,
                            childrenCount: children.length,
                            isPaused: isPaused,
                            isSelected: isSelected,
                            themeColor: themeColor,
                            themeText: themeText,
                            isArabic: isArabic,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required ServiceEntity? currentParent,
    required ThemeColorExtension themeColor,
    required AppTextThemeExtension themeText,
    required AppLocalizations l10n,
    required bool isArabic,
  }) {
    if (currentParent == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: themeColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'الخطوة 1: اختيار الخدمة',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: themeColor.primary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'برجاء تحديد نوع الخدمة المطلوبة',
            style: themeText.titleSectionSmall.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'اختر القسم الرئيسي المناسب للبدء في تخصيص طلبك وتحديد السعر النهائي',
            style: TextStyle(
              fontSize: 12.5,
              color: themeColor.secondaryText,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      );
    }

    final parentTitle = currentParent.title[isArabic ? 'ar' : 'en'] ??
        currentParent.title['ar'] ??
        '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'يرجى اختيار الخدمة المناسبة',
          style: themeText.titleSectionSmall.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 17,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'اختر من الخدمات والخيارات التابعة لـ ($parentTitle) أدناه',
          style: TextStyle(
            fontSize: 12.5,
            color: themeColor.secondaryText,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildParentBanner({
    required ServiceEntity parent,
    required ThemeColorExtension themeColor,
    required AppTextThemeExtension themeText,
    required bool isArabic,
  }) {
    final title = parent.title[isArabic ? 'ar' : 'en'] ?? parent.title['ar'] ?? '';
    final description =
        parent.description[isArabic ? 'ar' : 'en'] ?? parent.description['ar'] ?? '';
    final tintColor = _getServiceTint(title, themeColor);
    final imageUrl = _resolveImageUrl(parent.image);
    final fallbackIcon = _getServiceFallbackIcon(title);

    final breadcrumb = _selectedPath
        .map((p) => p.title[isArabic ? 'ar' : 'en'] ?? p.title['ar'] ?? '')
        .join('  >  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tintColor.withValues(alpha: 0.10),
            themeColor.cardBackground,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: tintColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tintColor.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Parent Icon
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeColor.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: tintColor.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Icon(fallbackIcon, color: tintColor, size: 26),
                      )
                    : Icon(fallbackIcon, color: tintColor, size: 26),
              ),
              const SizedBox(width: 12),
              // Title & Ancestry Path
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      breadcrumb,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: tintColor,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: themeText.titleSectionSmall.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 16.5,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // "رجوع خطوة" (Back Step) Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleBackHierarchy,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: themeColor.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: themeColor.unselectedItem.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isArabic
                              ? Icons.chevron_right_rounded
                              : Icons.chevron_left_rounded,
                          size: 18,
                          color: themeColor.textPrimary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'رجوع خطوة',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: themeColor.textPrimary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: themeColor.cardBackground.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: themeColor.secondaryText,
                  height: 1.4,
                  fontFamily: 'Cairo',
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required ServiceEntity service,
    required bool isBookableLeaf,
    required int childrenCount,
    required bool isPaused,
    required bool isSelected,
    required ThemeColorExtension themeColor,
    required AppTextThemeExtension themeText,
    required bool isArabic,
  }) {
    final title =
        service.title[isArabic ? 'ar' : 'en'] ?? service.title['ar'] ?? '';
    final tintColor = _getServiceTint(title, themeColor);
    final imageUrl = _resolveImageUrl(service.image);
    final fallbackIcon = _getServiceFallbackIcon(title);

    return Container(
      decoration: BoxDecoration(
        color: isPaused
            ? themeColor.cardBackground.withValues(alpha: 0.45)
            : isSelected
                ? themeColor.primary.withValues(alpha: 0.05)
                : themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? themeColor.primary
              : isPaused
                  ? Colors.amber.withValues(alpha: 0.3)
                  : themeColor.unselectedItem.withValues(alpha: 0.12),
          width: isSelected ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: tintColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isPaused ? null : () => _onServiceNodeTap(service),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Indicator Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (childrenCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tintColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: tintColor.withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '$childrenCount فروع',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: tintColor,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      )
                    else if (isBookableLeaf)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'حجز مباشر',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                            fontFamily: 'Cairo',
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 24, height: 16),
                    if (isPaused)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'متوقفة',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      )
                    else if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          size: 18, color: themeColor.primary),
                  ],
                ),
                const Spacer(),
                // Icon Container
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tintColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: tintColor.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(fallbackIcon, color: tintColor, size: 26),
                        )
                      : Icon(fallbackIcon, color: tintColor, size: 26),
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: themeText.textBodyPrimary.copyWith(
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                    fontSize: 13,
                    height: 1.25,
                    color: isSelected ? themeColor.primary : themeColor.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
