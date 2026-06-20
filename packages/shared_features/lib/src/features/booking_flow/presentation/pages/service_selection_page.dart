import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/service/entities/main_service_entity.dart';
import 'package:shared/domain/service/entities/sub_service_entity.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/booking_flow_state.dart';

/// Admin-only first step: loads all main services and sub-services,
/// then calls [BookingFlowCubit.selectService] when the admin picks one.
class ServiceSelectionPage extends StatefulWidget {
  const ServiceSelectionPage({super.key});

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _subServicesKey = GlobalKey();
  List<MainServiceEntity> _mainServices = [];
  bool _loading = true;
  String? _error;
  MainServiceEntity? _selectedMain;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    final cubit = context.read<BookingFlowCubit>();
    if (cubit.serviceRepository == null) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = l10n.error_service_repository_unavailable;
        _loading = false;
      });
      return;
    }

    cubit.serviceRepository!.getMainServices().listen(
      (result) {
        if (!mounted) return;
        result.fold(
          (failure) => setState(() {
            _error = failure.message;
            _loading = false;
          }),
          (services) => setState(() {
            _mainServices = services;
            _loading = false;
          }),
        );
      },
    );
  }

  void _onMainServiceSelected(MainServiceEntity service) {
    setState(() {
      _selectedMain = service;
    });
    
    // Smooth scroll to sub-services section
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_subServicesKey.currentContext != null) {
        Scrollable.ensureVisible(
          _subServicesKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
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
        child: Text(_error!,
            style: TextStyle(color: themeColor.error),
            textAlign: TextAlign.center),
      );
    }

    return BlocBuilder<BookingFlowCubit, BookingFlowState>(
      builder: (context, state) {
        final selectedMainTitle = _selectedMain != null
            ? (_selectedMain!.title[isArabic ? 'ar' : 'en'] ?? _selectedMain!.title['ar'] ?? '')
            : '';

        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text(l10n.booking_select_main_service,
                style: themeText.titleSectionSmall.copyWith(
                    fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 20),
            ..._mainServices
                .map((s) => _buildMainServiceCard(s, themeColor, themeText, isArabic)),

            if (_selectedMain != null) ...[
              const SizedBox(height: 40),
              Text(
                l10n.booking_services_of(selectedMainTitle),
                key: _subServicesKey,
                style: themeText.titleSectionSmall.copyWith(
                    fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 20),
              ..._selectedMain!.subServices
                  .map((sub) =>
                      _buildSubServiceCard(sub, themeColor, themeText, state, isArabic, l10n)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMainServiceCard(MainServiceEntity service,
      ThemeColorExtension themeColor, AppTextThemeExtension themeText, bool isArabic) {
    final isSelected = _selectedMain?.id == service.id;
    final title = service.title[isArabic ? 'ar' : 'en'] ?? service.title['ar'] ?? '';

    return GestureDetector(
      onTap: () => _onMainServiceSelected(service),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.cardBackground : themeColor.nestedCardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? themeColor.primary : Colors.transparent,
              width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeColor.primary.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
              : [],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? themeColor.primary.withValues(alpha: 0.1)
                  : themeColor.unselectedItem.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.category_rounded,
                color: isSelected ? themeColor.primary : themeColor.secondaryText,
                size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: themeText.textBodyPrimary.copyWith(
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle_rounded, color: themeColor.primary, size: 24),
        ]),
      ),
    );
  }

  Widget _buildSubServiceCard(SubServiceEntity sub,
      ThemeColorExtension themeColor, AppTextThemeExtension themeText,
      BookingFlowState state, bool isArabic, AppLocalizations l10n) {
    final isSelected = state.service?.subServiceId == sub.id;
    final title = sub.title[isArabic ? 'ar' : 'en'] ?? sub.title['ar'] ?? '';

    return GestureDetector(
      onTap: () {
        context.read<BookingFlowCubit>().selectService(sub);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.cardBackground : themeColor.cardBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? themeColor.primary : themeColor.unselectedItem.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeColor.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: themeText.textBodyPrimary.copyWith(
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    )),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${sub.price} ${l10n.pricing_currency_short}',
                    style: themeText.textCaption.copyWith(
                        color: themeColor.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.arrow_forward_ios_rounded,
            size: isSelected ? 24 : 16,
            color: isSelected
                ? themeColor.primary
                : themeColor.secondaryText.withValues(alpha: 0.5),
          ),
        ]),
      ),
    );
  }
}
