import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/dialogs/dialog_helper.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/dynamic_field.dart';
import 'package:shared_features/shared_features.dart';

import '../cubit/pricing_governance_cubit.dart';
import '../cubit/pricing_governance_state.dart';
import '../../domain/entities/pricing_discount_entity.dart';
import '../../../services_management/presentation/config/pricing_feature_flags.dart';
import '../../../services_management/presentation/services/pricing_simulation_gateway.dart';
import '../../../../core/di/injection_container.dart';

import 'visual_rule_builder_page.dart';
import 'discount_campaign_builder_page.dart';
import 'pricing_version_history_page.dart';

class ServicePricingHubPage extends StatefulWidget {
  final String subServiceId;
  final ServiceEntity? initialService;

  const ServicePricingHubPage({
    super.key,
    required this.subServiceId,
    this.initialService,
  });

  @override
  State<ServicePricingHubPage> createState() => _ServicePricingHubPageState();
}

class _ServicePricingHubPageState extends State<ServicePricingHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PricingGovernanceCubit _cubit;

  // Service Details State
  bool _isLoadingService = false;
  String? _serviceError;
  ServiceEntity? _service;

  // Pricing Config Variables
  late PricingMethod _pricingMethod;
  late double _basePrice;
  late String _unit;
  late List<DynamicFieldEntity> _fields;
  late List<PriceOptionEntity> _options;
  late List<ComputedFieldEntity> _computedFields;
  late TextEditingController _formulaController;
  late TextEditingController _pricingUnitController;
  String? _basePriceFormula;
  double? _minPrice;

  // Simulator Inputs State
  final Map<String, dynamic> _simulatorInputs = {};
  final List<String> _simulatorSelectedOptions = [];
  List<WindowDimension> _simulatorWindows = [];
  bool _simulatorUseWindowsCalculator = false;
  final TextEditingController _simulatorCouponController = TextEditingController();
  bool _simulatorIsCouponFieldExpanded = false;

  // Server Simulation Result
  PricingSimulationResult? _simulationResult;
  bool _isLoadingSimulation = false;
  String? _simulationError;
  final PricingSimulationGateway _simulationGateway =
      PricingSimulationGateway();

  // Configuration Warnings
  String? _validationWarning;
  final Set<String> _expandedFieldIds = {};
  // قائمة مفاتيح ثابتة للحقول لا تتأثر بتغيير field.id أثناء الكتابة
  final List<String> _fieldStableKeys = [];

  // تتبع التعديلات غير المحفوظة
  bool _isDirty = false;

  /// يُعلم النظام بأن هناك تعديلاً لم يُحفظ بعد
  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _cubit = getIt<PricingGovernanceCubit>()
      ..loadPricingGovernanceData(widget.subServiceId);

    if (widget.initialService != null) {
      _service = widget.initialService;
      _initializeServiceState();
    } else {
      _loadServiceDetails();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _formulaController.dispose();
    _pricingUnitController.dispose();
    _simulatorCouponController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _loadServiceDetails() async {
    setState(() {
      _isLoadingService = true;
      _serviceError = null;
    });

    try {
      final result = await getIt<GetServiceByIdUseCase>().call(
        widget.subServiceId,
      );
      result.fold(
        (failure) {
          setState(() {
            _isLoadingService = false;
            _serviceError = 'فشل تحميل تفاصيل الخدمة: ${failure.message}';
          });
        },
        (service) {
          setState(() {
            _service = service;
            _isLoadingService = false;
            _initializeServiceState();
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoadingService = false;
        _serviceError = 'حدث خطأ أثناء الاتصال بالخادم: $e';
      });
    }
  }

  void _initializeServiceState() {
    final price = _service?.price;
    if (price != null) {
      _pricingMethod = price.type;
      _basePrice = price.value.toDouble();
      _unit = price.unit;
      _fields = List.from(price.fields);
      _options = List.from(price.options);
      _basePriceFormula = price.basePriceFormula;
      _formulaController = TextEditingController(text: _basePriceFormula ?? '');
      _pricingUnitController = TextEditingController(text: _unit);
      _minPrice = price.minPrice?.toDouble();
    } else {
      _pricingMethod = PricingMethod.fixed;
      _basePrice = 0.0;
      _unit = 'ج.م';
      _fields = [];
      _options = [];
      _basePriceFormula = null;
      _formulaController = TextEditingController(text: '');
      _pricingUnitController = TextEditingController(text: 'ج.م');
      _minPrice = null;
    }
    _computedFields = List.from(_service?.computedFields ?? const []);

    // تهيئة مفاتيح ثابتة لكل حقل بناءً على وقت التحميل — لا تتغيّر أبداً
    _fieldStableKeys.clear();
    _expandedFieldIds.clear();
    for (int i = 0; i < _fields.length; i++) {
      _fieldStableKeys.add('fk_${DateTime.now().microsecondsSinceEpoch}_$i');
    }

    _initializeSimulatorDefaults();
    _validateConfiguration();
  }

  void _initializeSimulatorDefaults() {
    _simulatorInputs.clear();
    _simulatorSelectedOptions.clear();
    _simulatorWindows = [const WindowDimension(width: 1.0, height: 1.0, quantity: 1, isBothSides: false)];
    _simulatorUseWindowsCalculator = false;
    _simulatorCouponController.clear();
    _simulatorIsCouponFieldExpanded = false;

    // Set default values for built-in/classic fields
    _simulatorInputs['area'] = 100.0;
    _simulatorInputs['total_linear_meters'] = 10.0;

    for (final field in _fields) {
      if (field.type == DynamicFieldType.number) {
        _simulatorInputs[field.id] = field.min?.toDouble() ?? 100.0;
      } else if (field.type == DynamicFieldType.toggle) {
        _simulatorInputs[field.id] = false;
      } else if (field.type == DynamicFieldType.dropdown) {
        _simulatorInputs[field.id] = (field.options != null && field.options!.isNotEmpty)
            ? field.options!.first.id
            : null;
      }
    }
  }

  void _validateConfiguration() {
    setState(() {
      _validationWarning = null;

      final ids = _fields.map((f) => f.id.trim()).toList();
      if (ids.length != ids.toSet().length) {
        _validationWarning = '⚠️ تحذير: توجد حقول مكررة المعرف (IDs).';
        return;
      }

      if (_pricingMethod == PricingMethod.perSquareMeter &&
          !ids.contains('area')) {
        _validationWarning =
            '💡 توصية: يفضل إضافة حقل رقمي بمعرف "area" لحساب تسعير المتر المربع.';
      }

      for (final f in _fields) {
        if (f.id.trim().isEmpty) {
          _validationWarning = '⚠️ تحذير: يوجد حقل فارغ المعرف.';
          return;
        }
      }

      // Cross-validation of active AST rule parameters
      final originalIds =
          _service?.price?.fields.map((f) => f.id.trim()).toSet() ?? {};
      final currentIds = ids.toSet();
      final List<String> deletedAstdeps = [];

      if (originalIds.contains('area') && !currentIds.contains('area')) {
        deletedAstdeps.add('المساحة (area)');
      }
      if (originalIds.contains('furnished') &&
          !currentIds.contains('furnished')) {
        deletedAstdeps.add('مفروش (furnished)');
      }
      if (originalIds.contains('total_linear_meters') &&
          !currentIds.contains('total_linear_meters')) {
        deletedAstdeps.add('المتر الطولي (total_linear_meters)');
      }

      if (deletedAstdeps.isNotEmpty) {
        _validationWarning =
            '⚠️ تحذير حرج: لقد قمت بحذف حقل ${deletedAstdeps.join('، ')} المستخدم في قواعد حوكمة الأسعار النشطة (AST Rules). قد يؤدي هذا إلى تعطل حساب الأسعار سحابياً!';
      }
    });
  }

  Future<void> _runServerSimulation() async {
    if (!PricingFeatureFlags.enableServerSimulation) {
      setState(() {
        _simulationError =
            '⚠️ محاكاة الخادم معطلة عبر الـ Feature Flag حالياً.';
        _simulationResult = null;
      });
      return;
    }

    setState(() {
      _isLoadingSimulation = true;
      _simulationError = null;
    });

    double? calcLinearMeters = (_simulatorInputs['total_linear_meters'] as num?)?.toDouble();
    if (_pricingMethod == PricingMethod.perLinearMeter) {
      if (_simulatorUseWindowsCalculator && _simulatorWindows.isNotEmpty) {
        calcLinearMeters = _simulatorWindows.fold(
          0.0,
          (sum, window) => sum! + window.effectiveLinearMeters,
        );
      }
    }

    try {
      final Map<String, dynamic> priceConfig = {
        'type': _pricingMethod.name,
        'base_price_value': _basePrice,
        'unit': _unit,
        'fields': _fields
            .map(
              (f) => {
                'id': f.id,
                'type': f.type.name,
                'label': f.label,
                'required': f.required,
                if (f.min != null) 'min': f.min,
                if (f.unit != null) 'unit': f.unit,
                if (f.priceModifier != null) 'price_modifier': f.priceModifier,
                if (f.options != null)
                  'options': f.options!
                      .map((o) => {'id': o.id, 'label': o.label})
                      .toList(),
              },
            )
            .toList(),
        'options': _options
            .map((o) => {'key': o.key, 'value': o.value})
            .toList(),
        'computed_fields': _computedFields
            .map(
              (cf) => {'id': cf.id, 'formula': cf.formula, 'label': cf.label},
            )
            .toList(),
        if (_basePriceFormula != null && _basePriceFormula!.trim().isNotEmpty)
          'base_price_formula': _basePriceFormula!.trim(),
        if (_minPrice != null) 'min_price': _minPrice,
      };

      final Map<String, dynamic> pricingInputs = {};
      _simulatorInputs.forEach((key, val) {
        pricingInputs[key] = val;
      });
      pricingInputs['selected_options'] = _simulatorSelectedOptions;

      // Sync special fields to pricing inputs
      if (_pricingMethod == PricingMethod.perSquareMeter) {
        pricingInputs['area'] = _simulatorInputs['area'] ?? 100.0;
      } else if (_pricingMethod == PricingMethod.perLinearMeter) {
        pricingInputs['total_linear_meters'] = calcLinearMeters ?? 10.0;
        if (_simulatorUseWindowsCalculator) {
          pricingInputs['windows'] = _simulatorWindows
              .map((w) => {
                    'width': w.width,
                    'height': w.height,
                    'quantity': w.quantity,
                    'isBothSides': w.isBothSides,
                  })
              .toList();
        } else {
          pricingInputs['windows'] = [];
        }
      }

      if (_simulatorCouponController.text.trim().isNotEmpty) {
        pricingInputs['coupon_code'] =
            _simulatorCouponController.text.trim().toUpperCase();
      }

      final result = await _simulationGateway.simulatePricing(
        subServiceId: widget.subServiceId,
        priceConfig: priceConfig,
        pricingInputs: pricingInputs,
      );

      setState(() {
        _simulationResult = result;
        _isLoadingSimulation = false;
      });
    } catch (e) {
      setState(() {
        _simulationError = e.toString();
        _isLoadingSimulation = false;
        _simulationResult = null;
      });
      debugPrint('❌ [ServicePricingHubPage - Simulation Error]: $e');
    }
  }

  Future<void> _savePriceConfig() async {
    if (_service == null) return;

    final updatedPrice = PriceEntity(
      type: _pricingMethod,
      value: _basePrice,
      unit: _unit,
      options: _options,
      fields: _fields,
      basePriceFormula: _basePriceFormula?.trim().isEmpty == true
          ? null
          : _basePriceFormula?.trim(),
      minPrice: _minPrice,
    );

    final updatedService = _service!.copyWith(
      price: updatedPrice,
      computedFields: _computedFields,
    );

    DialogHelper.showConfirmation(
      context,
      title: "تأكيد تعديل الأسعار",
      desc:
          "هل أنت متأكد من حفظ وتطبيق إعدادات الأسعار والحقول الجديدة للخدمة؟",
      okText: "حفظ وتطبيق",
      cancelText: "إلغاء",
      onConfirm: () async {
        DialogHelper.showLoading(context);
        try {
          final result = await getIt<UpdateServiceUseCase>().call(
            updatedService,
          );

          if (!mounted) return;
          DialogHelper.dismissLoading(context);

          result.fold(
            (failure) {
              DialogHelper.showError(
                context,
                message: "فشل حفظ إعدادات التسعير: ${failure.message}",
              );
            },
            (success) {
              // إعادة تعيين الـ dirty flag بعد الحفظ الناجح
              setState(() => _isDirty = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'تم حفظ وتطبيق إعدادات التسعير بنجاح.',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              _loadServiceDetails();
            },
          );
        } catch (e) {
          if (!mounted) return;
          DialogHelper.dismissLoading(context);
          DialogHelper.showError(context, message: "حدث خطأ غير متوقع: $e");
        }
      },
    );
  }

  double _calculateSimulatedExtras() {
    double extraFees = 0.0;

    for (final field in _fields) {
      final dynamicVal = _simulatorInputs[field.id];
      if (dynamicVal == true && field.type == DynamicFieldType.toggle) {
        if (field.priceModifier != null && field.priceModifier! > 5.0) {
          extraFees += field.priceModifier!;
        }
      }
    }

    for (final optKey in _simulatorSelectedOptions) {
      final matched = _options.firstWhere(
        (opt) => opt.key == optKey,
        orElse: () => const PriceOptionEntity(key: '', value: 0.0),
      );
      if (matched.key != null && matched.key!.isNotEmpty) {
        extraFees += matched.value!.toDouble();
      }
    }

    return extraFees;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1000;

    if (_isLoadingService) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_serviceError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'لوحة التسعير الموحدة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _serviceError!,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadServiceDetails,
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldLeave = await _showUnsavedChangesDialog();
        if (shouldLeave == true && mounted) {
          navigator.pop();
        }
      },
      child: BlocProvider.value(
        value: _cubit,
        child: Scaffold(
          backgroundColor: themeColor.background,
          appBar: AppBar(
            title: Text(
              'لوحة التسعير الموحدة: ${_service?.title['ar'] ?? ''}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            centerTitle: true,
            actions: [
              ElevatedButton.icon(
                onPressed: _savePriceConfig,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text(
                  'حفظ وتطبيق',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: themeColor.secondary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: themeColor.secondary,
              labelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              tabs: [
                const Tab(
                  icon: Icon(Icons.tune_rounded),
                  text: 'بطاقة التسعير والمعادلات',
                ),
                const Tab(
                  icon: Icon(Icons.reorder_rounded),
                  text: 'منسق الحقول والواجهات',
                ),
                const Tab(
                  icon: Icon(Icons.calculate_rounded),
                  text: 'الحقول المحسوبة',
                ),
                const Tab(
                  icon: Icon(Icons.add_shopping_cart_rounded),
                  text: 'الخيارات والإضافات',
                ),
                const Tab(
                  icon: Icon(Icons.rule_folder_rounded),
                  text: 'قواعد الحوكمة (AST)',
                ),
                const Tab(
                  icon: Icon(Icons.local_offer_rounded),
                  text: 'الخصومات والعروض',
                ),
                if (isDesktop)
                  const Tab(
                    icon: Icon(Icons.cloud_sync_rounded),
                    text: 'محاكاة سحابية RPC',
                  )
                else
                  const Tab(
                    icon: Icon(Icons.science_rounded),
                    text: 'محاكي الأسعار المالي',
                  ),
                const Tab(
                  icon: Icon(Icons.history_toggle_off_rounded),
                  text: 'سجل النسخ والتدقيق',
                ),
              ],
            ),
          ),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                if (_validationWarning != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    color: Colors.amber.shade50,
                    child: Text(
                      _validationWarning!,
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left sticky phone emulator for fast interactive testing
                            Expanded(
                              flex: 4,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: themeColor.unselectedItem
                                          .withValues(alpha: 0.1),
                                    ),
                                  ),
                                ),
                                child: _buildPhoneEmulator(
                                  themeColor,
                                  themeText,
                                ),
                              ),
                            ),
                            // Right view: configure tabs
                            Expanded(
                              flex: 6,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildPricingRulesTab(themeColor, themeText),
                                  _buildFieldsTab(themeColor, themeText),
                                  _buildComputedFieldsTab(
                                    themeColor,
                                    themeText,
                                  ),
                                  _buildAddonsTab(themeColor, themeText),
                                  _buildASTGovernanceTab(),
                                  _buildDiscountsTab(),
                                  _buildLiveSimulationTab(
                                    themeColor,
                                    themeText,
                                  ),
                                  _buildAuditTab(),
                                ],
                              ),
                            ),
                          ],
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPricingRulesTab(themeColor, themeText),
                            _buildFieldsTab(themeColor, themeText),
                            _buildComputedFieldsTab(themeColor, themeText),
                            _buildAddonsTab(themeColor, themeText),
                            _buildASTGovernanceTab(),
                            _buildDiscountsTab(),
                            _buildMobileSimulatorTab(themeColor, themeText),
                            _buildAuditTab(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// دايلوج التعديلات غير المحفوظة — يظهر عند محاولة الخروج مع وجود تعديلات
  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final themeColor = ctx.themeColor;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            decoration: BoxDecoration(
              color: themeColor.cardBackground,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeColor.primary,
                        themeColor.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'لديك تعديلات غير محفوظة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'أجريت تعديلات على إعدادات التسعير ولم تحفظها بعد.\nهل تريد حفظ التعديلات قبل الخروج؟',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          height: 1.7,
                          color: themeColor.textPrimary.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop(false);
                            _savePriceConfig();
                          },
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text(
                            'حفظ التعديلات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                          label: const Text(
                            'تجاهل التعديلات والخروج',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(
                          'إلغاء (البقاء في الصفحة)',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: themeColor.unselectedItem,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBar({Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "09:41",
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.signal_cellular_4_bar_rounded,
                color: color,
                size: 10,
              ),
              const SizedBox(width: 4),
              Icon(Icons.wifi_rounded, color: color, size: 10),
              const SizedBox(width: 4),
              Icon(Icons.battery_5_bar_rounded, color: color, size: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNotch() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 100,
        height: 16,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
    );
  }

  // --- Sticky Phone Emulator ---
  Widget _buildPhoneEmulator(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "محاكاة شاشة العميل (Interactive Emulator)",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: themeColor.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _runServerSimulation,
              icon: _isLoadingSimulation
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    )
                  : const Icon(Icons.cloud_done_rounded, size: 16),
              label: const Text(
                "تدقيق سحابي",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor.secondary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: themeColor.primary.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: const Color(0xFF1E293B), width: 6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: Theme(
                data: AppTheme.light,
                child: Builder(
                  builder: (emulatorContext) {
                    final localThemeColor = emulatorContext.themeColor;
                    final localThemeText = Theme.of(emulatorContext)
                        .extension<AppTextThemeExtension>()!;

                    return Stack(
                      children: [
                        Scaffold(
                          backgroundColor: const Color(0xFFF9FAFB),
                          appBar: AppBar(
                            backgroundColor: Colors.white,
                            title: const Text(
                              "حجز الخدمة",
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            centerTitle: true,
                            automaticallyImplyLeading: false,
                            elevation: 0,
                            toolbarHeight: 52,
                          ),
                          body: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 36, 16, 24),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildMockupServiceHeader(
                                localThemeColor,
                                localThemeText,
                              ),
                              const SizedBox(height: 16),
                              _buildMockupInputs(
                                emulatorContext,
                                localThemeColor,
                                localThemeText,
                              ),
                              const SizedBox(height: 24),
                              _buildMockupCouponInput(
                                localThemeColor,
                                localThemeText,
                              ),
                              const SizedBox(height: 24),
                              _buildMockupBreakdown(
                                localThemeColor,
                                localThemeText,
                              ),
                            ],
                          ),
                          bottomNavigationBar: _buildMockupBottomBar(
                            localThemeColor,
                            localThemeText,
                          ),
                        ),
                        // Status bar and Notch Overlay
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.white,
                            height: 24,
                            child: Stack(
                              children: [
                                _buildStatusBar(color: Colors.black87),
                                _buildPhoneNotch(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMockupServiceHeader(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    String pricingMethodText = 'تسعير مخصص';
    IconData pricingIcon = Icons.payments_outlined;
    switch (_pricingMethod) {
      case PricingMethod.fixed:
        pricingMethodText = 'سعر ثابت';
        pricingIcon = Icons.bookmark_added_rounded;
        break;
      case PricingMethod.perSquareMeter:
        pricingMethodText = 'سعر المتر المربع';
        pricingIcon = Icons.square_foot_rounded;
        break;
      case PricingMethod.perLinearMeter:
        pricingMethodText = 'سعر المتر الطولي';
        pricingIcon = Icons.linear_scale_rounded;
        break;
      case PricingMethod.perIssue:
        pricingMethodText = 'سعر المشكلة';
        pricingIcon = Icons.report_problem_rounded;
        break;
      case PricingMethod.unknown:
        pricingMethodText = 'تسعير مخصص';
        pricingIcon = Icons.payments_outlined;
        break;
      case PricingMethod.inspection:
        pricingMethodText = 'تسعير معاينة';
        pricingIcon = Icons.payments_outlined;
        break;
    }

    final String arTitle = _service?.title['ar'] ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColor.primary.withValues(alpha: 0.1),
            themeColor.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeColor.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              pricingIcon,
              color: themeColor.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arTitle,
                  style: themeText.textBodyPrimary.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: themeColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pricingMethodText,
                  style: themeText.textCaption.copyWith(
                    color: themeColor.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupInputs(
    BuildContext context,
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    final computedFieldIds = _computedFields.map((cf) => cf.id).toSet();
    final filteredFields =
        _fields.where((f) => !computedFieldIds.contains(f.id)).toList();
    final isDynamic = filteredFields.isNotEmpty;

    if (isDynamic) {
      return DynamicFormRenderer(
        fields: filteredFields,
        values: _simulatorInputs,
        options: _options,
        selectedOptions: _simulatorSelectedOptions,
        onFieldChanged: (key, val) {
          setState(() {
            _simulatorInputs[key] = val;
          });
        },
        onOptionToggled: (optKey) {
          setState(() {
            if (_simulatorSelectedOptions.contains(optKey)) {
              _simulatorSelectedOptions.remove(optKey);
            } else {
              _simulatorSelectedOptions.add(optKey);
            }
          });
        },
      );
    } else {
      if (_pricingMethod == PricingMethod.perSquareMeter) {
        return _buildMockupAreaInput(themeColor, themeText);
      } else if (_pricingMethod == PricingMethod.perLinearMeter) {
        return _buildMockupLinearPricingSection(themeColor, themeText);
      } else {
        return _buildMockupFixedPriceMessage(themeColor, themeText);
      }
    }
  }

  Widget _buildMockupFixedPriceMessage(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: themeColor.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "هذه الخدمة يتم تقديمها بسعر ثابت ومحدد مسبقاً ولا تتطلب إدخال تفاصيل إضافية.",
              style: themeText.textBodySecondary.copyWith(
                color: themeColor.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupAreaInput(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    final currentArea = (_simulatorInputs['area'] as num?)?.toDouble() ?? 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "المساحة المطلوبة",
              style: themeText.titleSectionSmall.copyWith(
                color: themeColor.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: themeColor.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${currentArea.toStringAsFixed(0)} متر مربع',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: themeColor.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Stepper Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.fromBorderSide(themeColor.cardBorder),
            boxShadow: [themeColor.cardShadow],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    onPressed: currentArea > 50
                        ? () {
                            setState(() {
                              _simulatorInputs['area'] =
                                  (currentArea - 10).clamp(50, 1000).toDouble();
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove, size: 20),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        currentArea.toStringAsFixed(0),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: themeColor.textPrimary,
                        ),
                      ),
                      Text(
                        "متر مربع",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: themeColor.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      setState(() {
                        _simulatorInputs['area'] =
                            (currentArea + 10).clamp(50, 1000).toDouble();
                      });
                    },
                    icon: const Icon(Icons.add, size: 20),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Slider(
                value: currentArea.clamp(50, 500).toDouble(),
                min: 50,
                max: 500,
                divisions: 45,
                activeColor: themeColor.primary,
                inactiveColor: themeColor.primary.withValues(alpha: 0.15),
                onChanged: (val) {
                  setState(() {
                    _simulatorInputs['area'] = val.roundToDouble();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Preset Chips
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [100, 150, 200, 250, 300, 400].map((preset) {
              final isSelected = currentArea.round() == preset;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text('$preset م²'),
                  labelStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : themeColor.secondaryText,
                  ),
                  selected: isSelected,
                  selectedColor: themeColor.primary,
                  backgroundColor: themeColor.nestedCardBackground,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _simulatorInputs['area'] = preset.toDouble();
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: themeColor.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                "الحد الأدنى للاحتساب هو 50 م²",
                style: themeText.textCaption.copyWith(
                  color: themeColor.primary.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMockupLinearPricingSection(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: themeColor.nestedCardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: themeColor.unselectedItem.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _simulatorUseWindowsCalculator = true;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _simulatorUseWindowsCalculator
                          ? themeColor.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        "حساب من قياسات النوافذ",
                        style: themeText.textCaption.copyWith(
                          color: _simulatorUseWindowsCalculator
                              ? Colors.white
                              : themeColor.secondaryText,
                          fontWeight: _simulatorUseWindowsCalculator
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _simulatorUseWindowsCalculator = false;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_simulatorUseWindowsCalculator
                          ? themeColor.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        "إدخال المتر الطولي مباشرة",
                        style: themeText.textCaption.copyWith(
                          color: !_simulatorUseWindowsCalculator
                              ? Colors.white
                              : themeColor.secondaryText,
                          fontWeight: !_simulatorUseWindowsCalculator
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_simulatorUseWindowsCalculator)
          _buildMockupWindowsList(themeColor, themeText)
        else
          _buildMockupDirectLinearMetersInput(themeColor, themeText),
      ],
    );
  }

  Widget _buildMockupDirectLinearMetersInput(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    final currentLinear =
        (_simulatorInputs['total_linear_meters'] as num?)?.toDouble() ?? 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "إجمالي الأمتار الطولية",
              style: themeText.titleSectionSmall.copyWith(
                color: themeColor.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: themeColor.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${currentLinear.toStringAsFixed(1).replaceAll('.0', '')} م',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: themeColor.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.fromBorderSide(themeColor.cardBorder),
            boxShadow: [themeColor.cardShadow],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    onPressed: currentLinear > 1
                        ? () {
                            setState(() {
                              _simulatorInputs['total_linear_meters'] =
                                  (currentLinear - 1).clamp(1, 100).toDouble();
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove, size: 20),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        currentLinear.toStringAsFixed(1).replaceAll('.0', ''),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: themeColor.textPrimary,
                        ),
                      ),
                      Text(
                        "متر طولي",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: themeColor.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      setState(() {
                        _simulatorInputs['total_linear_meters'] =
                            (currentLinear + 1).clamp(1, 100).toDouble();
                      });
                    },
                    icon: const Icon(Icons.add, size: 20),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Slider(
                value: currentLinear.clamp(1, 50).toDouble(),
                min: 1,
                max: 50,
                divisions: 49,
                activeColor: themeColor.primary,
                inactiveColor: themeColor.primary.withValues(alpha: 0.15),
                onChanged: (val) {
                  setState(() {
                    _simulatorInputs['total_linear_meters'] =
                        val.roundToDouble();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [5, 10, 15, 20, 25, 30, 40].map((preset) {
              final isSelected = currentLinear.round() == preset;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text('$preset م'),
                  labelStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : themeColor.secondaryText,
                  ),
                  selected: isSelected,
                  selectedColor: themeColor.primary,
                  backgroundColor: themeColor.nestedCardBackground,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _simulatorInputs['total_linear_meters'] =
                            preset.toDouble();
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMockupWindowsList(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "أبعاد وقياسات النوافذ",
          style: themeText.titleSectionSmall.copyWith(
            color: themeColor.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "قم بإدخال أبعاد النوافذ لحساب إجمالي الأمتار الطولية تلقائياً.",
          style: themeText.textCaption.copyWith(color: themeColor.secondaryText),
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _simulatorWindows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final window = _simulatorWindows[index];
            return _buildMockupWindowItem(index, window, themeColor, themeText);
          },
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            setState(() {
              _simulatorWindows.add(
                const WindowDimension(
                  width: 1.0,
                  height: 1.0,
                  quantity: 1,
                  isBothSides: false,
                ),
              );
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: themeColor.primary, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: themeColor.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  "إضافة نافذة جديدة",
                  style: themeText.textBodyPrimary.copyWith(
                    color: themeColor.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMockupWindowItem(
    int index,
    WindowDimension window,
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(themeColor.cardBorder),
        boxShadow: [themeColor.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "النافذة رقم ${index + 1}",
                style: themeText.textBodySecondary.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeColor.textPrimary,
                ),
              ),
              if (index > 0)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _simulatorWindows.removeAt(index);
                    });
                  },
                  icon: Icon(
                    Icons.delete_outline,
                    color: themeColor.error,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMockupWindowSideSlidingToggle(
            window,
            index,
            themeColor,
            themeText,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMockupWindowDimensionStepper(
                  label: "العرض",
                  value: window.width,
                  onChanged: (w) {
                    setState(() {
                      _simulatorWindows[index] = window.copyWith(width: w);
                    });
                  },
                  themeColor: themeColor,
                  themeText: themeText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMockupWindowDimensionStepper(
                  label: "الارتفاع",
                  value: window.height,
                  onChanged: (h) {
                    setState(() {
                      _simulatorWindows[index] = window.copyWith(height: h);
                    });
                  },
                  themeColor: themeColor,
                  themeText: themeText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMockupWindowQuantityStepper(
                  label: "العدد",
                  value: window.quantity,
                  onChanged: (q) {
                    setState(() {
                      _simulatorWindows[index] = window.copyWith(quantity: q);
                    });
                  },
                  themeColor: themeColor,
                  themeText: themeText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockupWindowSideSlidingToggle(
    WindowDimension window,
    int index,
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: themeColor.nestedCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeColor.unselectedItem.withValues(alpha: 0.1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: window.isBothSides
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Container(
                  width: width,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: themeColor.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.primary.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _simulatorWindows[index] =
                              window.copyWith(isBothSides: false);
                        });
                      },
                      child: Center(
                        child: Text(
                          "جهة واحدة",
                          style: themeText.textCaption.copyWith(
                            color: !window.isBothSides
                                ? Colors.white
                                : themeColor.secondaryText,
                            fontWeight: !window.isBothSides
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _simulatorWindows[index] =
                              window.copyWith(isBothSides: true);
                        });
                      },
                      child: Center(
                        child: Text(
                          "الجهتين",
                          style: themeText.textCaption.copyWith(
                            color: window.isBothSides
                                ? Colors.white
                                : themeColor.secondaryText,
                            fontWeight: window.isBothSides
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMockupWindowDimensionStepper({
    required String label,
    required double value,
    required Function(double) onChanged,
    required ThemeColorExtension themeColor,
    required AppTextThemeExtension themeText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: themeText.textCaption.copyWith(
            fontSize: 12,
            color: themeColor.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: themeColor.nestedCardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeColor.unselectedItem.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: value > 0.1
                    ? () => onChanged(
                          double.parse((value - 0.1).toStringAsFixed(1)),
                        )
                    : null,
                icon: const Icon(Icons.remove, size: 16),
                color: themeColor.primary,
                disabledColor: themeColor.unselectedItem.withValues(alpha: 0.3),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${value.toStringAsFixed(1)}م',
                    style: themeText.textBodyPrimary.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: value < 10.0
                    ? () => onChanged(
                          double.parse((value + 0.1).toStringAsFixed(1)),
                        )
                    : null,
                icon: const Icon(Icons.add, size: 16),
                color: themeColor.primary,
                disabledColor: themeColor.unselectedItem.withValues(alpha: 0.3),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMockupWindowQuantityStepper({
    required String label,
    required int value,
    required Function(int) onChanged,
    required ThemeColorExtension themeColor,
    required AppTextThemeExtension themeText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: themeText.textCaption.copyWith(
            fontSize: 12,
            color: themeColor.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: themeColor.nestedCardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeColor.unselectedItem.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove, size: 16),
                color: themeColor.primary,
                disabledColor: themeColor.unselectedItem.withValues(alpha: 0.3),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$value',
                    style: themeText.textBodyPrimary.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: value < 50 ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add, size: 16),
                color: themeColor.primary,
                disabledColor: themeColor.unselectedItem.withValues(alpha: 0.3),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMockupCouponInput(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    final hasCoupon = _simulatorCouponController.text.trim().isNotEmpty &&
        _simulationResult != null &&
        _simulationResult!.discount > 0;

    if (!_simulatorIsCouponFieldExpanded && !hasCoupon) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _simulatorIsCouponFieldExpanded = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: themeColor.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeColor.primary.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                size: 18,
                color: themeColor.primary,
              ),
              const SizedBox(width: 10),
              Text(
                "هل لديك كوبون خصم؟",
                style: themeText.textCaption.copyWith(
                  color: themeColor.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: themeColor.primary,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(themeColor.cardBorder),
        boxShadow: [themeColor.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          color: themeColor.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "كوبون الخصم",
                          style: themeText.textBodySecondary.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: themeColor.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (!hasCoupon)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _simulatorIsCouponFieldExpanded = false;
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: BaseTextFormField(
                        controller: _simulatorCouponController,
                        hint: "أدخل كود الكوبون",
                        radius: 12,
                        enabled: !hasCoupon,
                        prefixIcon:
                            const Icon(Icons.confirmation_number_outlined),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          if (hasCoupon) {
                            setState(() {
                              _simulatorCouponController.clear();
                            });
                            _runServerSimulation();
                          } else {
                            final code = _simulatorCouponController.text
                                .trim()
                                .toUpperCase();
                            if (code.isNotEmpty) {
                              _runServerSimulation();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasCoupon
                              ? themeColor.error.withValues(alpha: 0.1)
                              : themeColor.primary,
                          foregroundColor:
                              hasCoupon ? themeColor.error : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          hasCoupon ? "إلغاء الكوبون" : "تطبيق",
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasCoupon) ...[
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: DashedLinePainter(
                    color: themeColor.unselectedItem.withValues(alpha: 0.2),
                  ),
                ),
                Positioned(
                  left: -8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: themeColor.background,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: -8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: themeColor.background,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: themeColor.pricingDiscount,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "تم تطبيق الكوبون بنجاح!",
                    style: themeText.textCaption.copyWith(
                      color: themeColor.pricingDiscount,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMockupBreakdown(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    if (_simulationResult == null) {
      return const SizedBox.shrink();
    }

    final BookingPricing bookingPricing = BookingPricing(
      basePrice: _simulationResult!.basePrice,
      extraFees: _simulationResult!.extraFees,
      discount: _simulationResult!.discount,
      total: _simulationResult!.total,
      metadata: {
        'subtotal': _simulationResult!.subtotal,
        'execution_trace': _simulationResult!.executionTrace,
        'options_breakdown': _simulationResult!.metadata['options_breakdown'] ??
            _simulatorSelectedOptions
                .map((optKey) {
                  final matched = _options.firstWhere(
                    (opt) => opt.key == optKey,
                    orElse: () => const PriceOptionEntity(key: '', value: 0.0),
                  );
                  return {
                    'key': optKey,
                    'price': matched.value ?? 0.0,
                  };
                })
                .toList(),
        'applied_rules': _simulationResult!.metadata['applied_rules'] ?? [],
        'applied_discounts':
            _simulationResult!.metadata['applied_discounts'] ?? [],
      },
    );

    return PriceBreakdownCard(
      pricing: bookingPricing,
      showHeader: true,
    );
  }

  Widget _buildMockupBottomBar(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    final bool isCalculated = _simulationResult != null;
    final String buttonText = isCalculated ? "إعادة الحساب" : "احسب التكلفة";

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        boxShadow: [themeColor.cardShadow],
        border: Border(top: themeColor.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: MyCustomButton(
              text: buttonText,
              isLoading: _isLoadingSimulation,
              onPressed: _isLoadingSimulation ? null : _runServerSimulation,
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 1: Rate Card & Formula Config ---
  Widget _buildPricingRulesTab(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        color: themeColor.cardBackground,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubsectionTitle(themeColor, "طريقة التسعير الحاكمة"),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: PricingMethod.values
                    .where((m) => m != PricingMethod.unknown)
                    .map((method) {
                      final isSelected = method == _pricingMethod;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _pricingMethod = method;
                            if (method == PricingMethod.perSquareMeter) {
                              _unit = 'م²';
                              _pricingUnitController.text = 'م²';
                            } else if (method == PricingMethod.perLinearMeter) {
                              _unit = 'م';
                              _pricingUnitController.text = 'م';
                            }
                            _validateConfiguration();
                          });
                          _markDirty();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? themeColor.primary.withValues(alpha: 0.1)
                                : themeColor.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? themeColor.primary
                                  : themeColor.unselectedItem.withValues(
                                      alpha: 0.2,
                                    ),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            _getMethodLabel(method),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? themeColor.primary
                                  : themeColor.textPrimary,
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubsectionTitle(
                          themeColor,
                          "السعر الأساسي للوحدة",
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _basePrice.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: themeColor.textPrimary,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _basePrice = double.tryParse(val) ?? 0.0;
                              _validateConfiguration();
                            });
                            _markDirty();
                          },
                          decoration: InputDecoration(
                            hintText: 'أدخل القيمة الأساسية (مثال: 150)',
                            fillColor: themeColor.background,
                            filled: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubsectionTitle(themeColor, "وحدة القياس"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _pricingUnitController,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: themeColor.textPrimary,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _unit = val.trim();
                            });
                            _markDirty();
                          },
                          decoration: InputDecoration(
                            hintText: 'مثال: م² أو ساعة',
                            fillColor: themeColor.background,
                            filled: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubsectionTitle(
                          themeColor,
                          "الحد الأدنى لقيمة الطلب (الافتراضي: بلا حد أدنى)",
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _minPrice != null
                              ? _minPrice!.toStringAsFixed(0)
                              : '',
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: themeColor.textPrimary,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _minPrice = val.trim().isEmpty
                                  ? null
                                  : double.tryParse(val);
                            });
                            _markDirty();
                          },
                          decoration: InputDecoration(
                            hintText:
                                'مثال: 2000 جنيه (اتركه فارغاً لعدم تحديد حد أدنى)',
                            fillColor: themeColor.background,
                            filled: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),
              _buildFormulaSection(themeColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaSection(ThemeColorExtension themeColor) {
    final hasFormula =
        _basePriceFormula != null && _basePriceFormula!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildSubsectionTitle(
                themeColor,
                "محرك التسعير بالمعادلات الرياضية (Formula Engine)",
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hasFormula
                    ? Colors.purple.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasFormula
                      ? Colors.purple.shade200
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasFormula
                        ? Icons.verified_rounded
                        : Icons.info_outline_rounded,
                    size: 12,
                    color: hasFormula
                        ? Colors.purple.shade700
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasFormula ? 'مُفعّل' : 'غير مُستخدَم',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: hasFormula
                          ? Colors.purple.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'يمكنك صياغة معادلة رياضية لحساب السعر الأساسي للخدمة. كتابة معادلة هنا تتجاوز طرق الحساب التقليدية وتفعل حساب المعادلة سحابياً.',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        // Monospace Console Container
        Container(
          decoration: BoxDecoration(
            color: const Color(
              0xFF0B132B,
            ), // Deep coding environment background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasFormula
                  ? const Color(0xFF8E44AD)
                  : const Color(0xFF1C2541),
              width: 1.5,
            ),
            boxShadow: hasFormula
                ? [
                    BoxShadow(
                      color: const Color(0xFF8E44AD).withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Editor Header Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    // Simulated window controls
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.amberAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      "PRICING_FORMULA_CONSOLE",
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Code Area
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line numbers sidebar
                    Container(
                      width: 32,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFF080E21),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            "1",
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.white24,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          Text(
                            "2",
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.white24,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          Text(
                            "3",
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.white24,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _formulaController,
                        maxLines: 3,
                        minLines: 2,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(
                            0xFF00FFCC,
                          ), // Glowing neon cyan for written code
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: '({area} * {price_per_sqm}) + {setup_fee}',
                          hintStyle: TextStyle(
                            color: Colors.white12,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _basePriceFormula = val.isEmpty ? null : val;
                          });
                          _markDirty();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Variable Chips Header
        const Text(
          'المتغيرات المتوفرة في هذه الخدمة (اضغط للإدراج في الصيغة):',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Base Price (Orange glow)
            _buildGlowingTokenChip(
              'base_price',
              themeColor,
              Colors.orangeAccent,
              Icons.monetization_on_rounded,
            ),
            // Dynamic Fields (Blue/Indigo glow)
            ..._fields.map((f) {
              return _buildGlowingTokenChip(
                f.id,
                themeColor,
                Colors.indigoAccent,
                Icons.input_rounded,
              );
            }),
            // Computed Fields (Green glow)
            ..._computedFields.map((cf) {
              return _buildGlowingTokenChip(
                cf.id,
                themeColor,
                Colors.greenAccent,
                Icons.calculate_rounded,
              );
            }),
          ],
        ),
        if (_fields.any((f) => f.type == DynamicFieldType.dropdown && f.options != null && f.options!.isNotEmpty)) ...[
          const SizedBox(height: 16),
          const Text(
            'قيم خيارات القوائم المنسدلة (اضغط للإدراج كنص مثل \'value\'):',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _fields
                .where((f) => f.type == DynamicFieldType.dropdown && f.options != null)
                .expand((f) => f.options!.map((opt) {
                      return InkWell(
                        onTap: () => _insertToken("'${opt.id}'"),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.purple.withValues(alpha: 0.3), width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.label_outline_rounded, size: 10, color: Colors.purple.shade300),
                              const SizedBox(width: 6),
                              Text(
                                '{${f.id}} == \'${opt.id}\'',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purpleAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildGlowingTokenChip(
    String tokenId,
    ThemeColorExtension themeColor,
    Color color,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => _insertToken('{$tokenId}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
            Text(
              '{$tokenId}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _insertToken(String token) {
    final text = _formulaController.text;
    final selection = _formulaController.selection;

    String newText;
    int newCursorPos;

    if (selection.isValid) {
      newText = text.replaceRange(selection.start, selection.end, token);
      newCursorPos = selection.start + token.length;
    } else {
      newText = text + token;
      newCursorPos = newText.length;
    }

    setState(() {
      _basePriceFormula = newText;
      _formulaController.text = newText;
      _formulaController.selection = TextSelection.fromPosition(
        TextPosition(offset: newCursorPos),
      );
    });
  }

  // --- Tab 2: Fields & Questionnaire Editor ---
  Widget _buildFieldsTab(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'حقول الإدخال الديناميكية المخصصة (${_fields.length})',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: themeColor.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addNewField,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'إضافة حقل جديد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _fields.isEmpty
              ? _buildEmptyStateWidget(
                  themeColor: themeColor,
                  icon: Icons.tune_rounded,
                  title: 'لا توجد حقول إدخال ديناميكية',
                  subtitle:
                      'أضف حقل إدخال مخصص لتهيئة وتخصيص الأسئلة والخيارات لعملائك.',
                  onPressed: _addNewField,
                  buttonText: 'إضافة أول حقل مخصص',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _fields.length,
                  itemBuilder: (context, index) {
                    final field = _fields[index];
                    final stableKey = index < _fieldStableKeys.length
                        ? _fieldStableKeys[index]
                        : 'field_$index';
                    return _FieldCardWidget(
                      key: ValueKey(stableKey),
                      field: field,
                      index: index,
                      themeColor: themeColor,
                      isExpanded: _expandedFieldIds.contains(stableKey),
                      onToggleExpand: () {
                        setState(() {
                          if (_expandedFieldIds.contains(stableKey)) {
                            _expandedFieldIds.remove(stableKey);
                          } else {
                            _expandedFieldIds.add(stableKey);
                          }
                        });
                      },
                      onDelete: () {
                        setState(() {
                          _fields.removeAt(index);
                          if (index < _fieldStableKeys.length) {
                            _expandedFieldIds.remove(_fieldStableKeys[index]);
                            _fieldStableKeys.removeAt(index);
                          }
                          _validateConfiguration();
                          _initializeSimulatorDefaults();
                        });
                      },
                      onFieldChanged: (updatedField) {
                        setState(() {
                          _fields[index] = updatedField;
                          _validateConfiguration();
                          _initializeSimulatorDefaults();
                        });
                        _markDirty();
                      },
                      onOrderChanged: (val) => _updateFieldOrder(index, val),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- Tab 3: Computed Fields Configuration ---
  Widget _buildComputedFieldsTab(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'الحقول المحسوبة سحابياً (${_computedFields.length})',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: themeColor.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addNewComputedField,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'إضافة حقل محسوب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _computedFields.isEmpty
              ? _buildEmptyStateWidget(
                  themeColor: themeColor,
                  icon: Icons.calculate_rounded,
                  title: 'لا توجد حقول محسوبة',
                  subtitle:
                      'تساعدك الحقول المحسوبة على استنتاج أبعاد وقيم جديدة تلقائياً بناءً على إدخالات العميل.',
                  onPressed: _addNewComputedField,
                  buttonText: 'إضافة أول حقل محسوب',
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _computedFields.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final field = _computedFields.removeAt(oldIndex);
                      _computedFields.insert(newIndex, field);
                      _validateConfiguration();
                    });
                  },
                  itemBuilder: (context, index) {
                    final field = _computedFields[index];
                    return _buildComputedFieldCard(
                      field,
                      index,
                      themeColor,
                      themeText,
                      key: ValueKey(field.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildComputedFieldCard(
    ComputedFieldEntity field,
    int index,
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText, {
    required Key key,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeColor.unselectedItem.withValues(
            alpha: isDark ? 0.15 : 0.08,
          ),
          width: 1.2,
        ),
        boxShadow: [themeColor.cardShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Color(
                  0xFF8E44AD,
                ), // Distinct purple accent for computed fields
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.drag_indicator_rounded,
                      color: themeColor.unselectedItem.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(
                        0xFF8E44AD,
                      ).withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF8E44AD),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        field.label['ar']?.isNotEmpty == true
                            ? field.label['ar']!
                            : (field.id.isNotEmpty
                                  ? field.id
                                  : 'حقل محسوب جديد'),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: themeColor.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _computedFields.removeAt(index);
                          _validateConfiguration();
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.redAccent,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: field.id,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: themeColor.textPrimary,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _computedFields[index] = field.copyWith(
                              id: val.trim(),
                            );
                            _validateConfiguration();
                          });
                        },
                        decoration: _buildModernInputDecoration(
                          themeColor,
                          label: 'معرف الحقل (ID Unique - مثل: area)',
                          icon: Icons.tag_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: field.formula,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: themeColor.textPrimary,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _computedFields[index] = field.copyWith(
                              formula: val,
                            );
                            _validateConfiguration();
                          });
                        },
                        decoration: _buildModernInputDecoration(
                          themeColor,
                          label: 'المعادلة الرياضية (مثال: {width} * {height})',
                          icon: Icons.functions_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: field.label['ar'] ?? '',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: themeColor.textPrimary,
                        ),
                        onChanged: (val) {
                          setState(() {
                            final Map<String, String> labels = Map.from(
                              field.label,
                            );
                            labels['ar'] = val;
                            _computedFields[index] = field.copyWith(
                              label: labels,
                            );
                          });
                        },
                        decoration: _buildModernInputDecoration(
                          themeColor,
                          label: 'العنوان بالعربية',
                          icon: Icons.text_fields_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: field.label['en'] ?? '',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: themeColor.textPrimary,
                        ),
                        onChanged: (val) {
                          setState(() {
                            final Map<String, String> labels = Map.from(
                              field.label,
                            );
                            labels['en'] = val;
                            _computedFields[index] = field.copyWith(
                              label: labels,
                            );
                          });
                        },
                        decoration: _buildModernInputDecoration(
                          themeColor,
                          label: 'العنوان بالإنجليزية',
                          icon: Icons.language_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Tab 4: Addons / Options ---
  Widget _buildAddonsTab(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'الميزات والخيارات الإضافية المتوفرة (${_options.length})',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: themeColor.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _options.add(
                      PriceOptionEntity(
                        key: 'addon_${_options.length + 1}',
                        value: 50.0,
                      ),
                    );
                  });
                  _markDirty();
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'إضافة ميزة إضافية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _options.isEmpty
              ? _buildEmptyState(
                  Icons.add_shopping_cart_rounded,
                  'لا توجد خيارات إضافية مضافة حالياً. أضف ميزة جديدة.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    final opt = _options[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: themeColor.cardBackground,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: opt.key,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: themeColor.textPrimary,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _options[index] = PriceOptionEntity(
                                      key: val,
                                      value: opt.value,
                                    );
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'معرف الخيار (Key)',
                                  isDense: true,
                                  labelStyle: TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: opt.value?.toString() ?? '0',
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: themeColor.textPrimary,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _options[index] = PriceOptionEntity(
                                      key: opt.key,
                                      value: num.tryParse(val) ?? 0,
                                    );
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'التكلفة الإضافية',
                                  isDense: true,
                                  labelStyle: TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _options.removeAt(index);
                                });
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- Tab 5: AST Governance Rules ---
  Widget _buildASTGovernanceTab() {
    return BlocBuilder<PricingGovernanceCubit, PricingGovernanceState>(
      builder: (context, state) {
        if (state is PricingGovernanceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PricingGovernanceLoaded) {
          final rules = state.rules;
          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VisualRuleBuilderPage(
                      subServiceId: widget.subServiceId,
                    ),
                  ),
                );
                if (result == true) {
                  _cubit.loadPricingGovernanceData(widget.subServiceId);
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'قاعدة شرطية جديدة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: rules.isEmpty
                ? _buildEmptyState(
                    Icons.rule_rounded,
                    'لا توجد قواعد تسعير شرطية مضافة بعد لهذه الخدمة.\nاضغط على إضافة قاعدة لتبدأ في تصميم الهيكل الشرطي.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rules.length,
                    itemBuilder: (context, index) {
                      final rule = rules[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    rule.ruleName,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Switch(
                                    value: rule.isActive,
                                    onChanged: (val) {
                                      _cubit.toggleRule(
                                        rule.id,
                                        widget.subServiceId,
                                        val,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    rule.actionType == 'multiply'
                                        ? 'معامل الضرب: x${rule.actionValue.toStringAsFixed(2)}'
                                        : 'رسوم إضافية ثابتة: +${rule.actionValue.toStringAsFixed(0)} ج.م',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      color: Colors.blueGrey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      'الأولوية: ${rule.priority}',
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11,
                                      ),
                                    ),
                                    backgroundColor: Colors.grey.shade100,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'شجرة الشروط (AST Cond):',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F0FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.purple.shade100,
                                  ),
                                ),
                                child: _AstReadableRenderer(
                                  astJson: Map<String, dynamic>.from(
                                    rule.conditionAst as Map? ??
                                        const <String, dynamic>{},
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        }

        return const Center(
          child: Text(
            'فشل تحميل قواعد الحوكمة.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        );
      },
    );
  }

  // --- Tab 6: Coupons & Discounts ---
  Widget _buildDiscountsTab() {
    return BlocBuilder<PricingGovernanceCubit, PricingGovernanceState>(
      builder: (context, state) {
        if (state is PricingGovernanceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PricingGovernanceLoaded) {
          final discounts = state.discounts
              .where((d) =>
                  d.subServiceId == null ||
                  d.subServiceId == widget.subServiceId)
              .toList();
          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DiscountCampaignBuilderPage(
                      subServiceId: widget.subServiceId,
                    ),
                  ),
                );
                if (result == true) {
                  _cubit.loadPricingGovernanceData(widget.subServiceId);
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'حملة خصم جديدة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: discounts.isEmpty
                ? _buildEmptyState(
                    Icons.local_offer_rounded,
                    'لا توجد حملات ترويجية أو أكواد خصم متاحة حالياً.\nقم بإنشاء كود خصم جديد لتطبيقه على سلة المشتريات.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: discounts.length,
                    itemBuilder: (context, index) {
                      final discount = discounts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          discount.name,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          discount.code,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF1A7A43),
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          discount.discountType == 'percentage'
                                              ? 'خصم ${discount.discountValue.toStringAsFixed(0)}%'
                                              : 'خصم ثابت ${discount.discountValue.toStringAsFixed(0)} ج.م',
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _DiscountValidityChip(discount: discount),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        discount.isStackable
                                            ? Icons.layers_rounded
                                            : Icons.looks_one_rounded,
                                        size: 14,
                                        color: discount.isStackable
                                            ? Colors.blue.shade700
                                            : Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        discount.isStackable
                                            ? 'قابل للتراكم'
                                            : 'غير متراكم',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11,
                                          color: discount.isStackable
                                              ? Colors.blue.shade700
                                              : Colors.orange.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.confirmation_num_outlined,
                                        size: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'الاستخدام: ${discount.usageCount} / ${discount.usageLimit ?? '∞'}',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (discount.startDate != null ||
                                  discount.endDate != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.date_range_rounded,
                                      size: 13,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'من ${discount.startDate?.toLocal().toString().substring(0, 10) ?? '—'} إلى ${discount.endDate?.toLocal().toString().substring(0, 10) ?? '—'}',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Switch(
                                        value: discount.isActive,
                                        activeThumbColor: const Color(0xFF1A7A43),
                                        onChanged: (val) {
                                          _cubit.toggleDiscountActive(
                                            discount.id,
                                            widget.subServiceId,
                                            val,
                                          );
                                        },
                                      ),
                                      Text(
                                        discount.isActive ? 'نشط' : 'معطل',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: discount.isActive ? const Color(0xFF1A7A43) : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, color: Colors.blueGrey, size: 20),
                                        tooltip: 'تعديل الحملة',
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DiscountCampaignBuilderPage(
                                                subServiceId: widget.subServiceId,
                                                discount: discount,
                                              ),
                                            ),
                                          );
                                          if (result == true) {
                                            _cubit.loadPricingGovernanceData(widget.subServiceId);
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700, size: 20),
                                        tooltip: 'حذف الحملة',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'تأكيد الحذف',
                                                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                              ),
                                              content: Text(
                                                'هل أنت متأكد من رغبتك في حذف حملة الخصم "${discount.name}" نهائياً؟',
                                                style: const TextStyle(fontFamily: 'Cairo'),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            _cubit.deleteDiscount(discount.id, widget.subServiceId);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        }

        return const Center(
          child: Text(
            'فشل تحميل الخصومات.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        );
      },
    );
  }

  // --- Tab 7 (Mobile): Local Emulator Tab ---
  Widget _buildMobileSimulatorTab(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 500,
            child: _buildPhoneEmulator(themeColor, themeText),
          ),
          const SizedBox(height: 24),
          _buildLiveSimulationTab(themeColor, themeText),
        ],
      ),
    );
  }

  // --- Tab 7 (Desktop): RPC Cloud Simulator Trace Logs ---
  Widget _buildLiveSimulationTab(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    final double legacyExtras = _calculateSimulatedExtras();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeColor.primary,
                  themeColor.primary.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_sync_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تتبع العمليات والمحاكاة السحابية RPC',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'الاتصال بقواعد بيانات Supabase RPC لتشغيل خط أنابيب التسعير.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _runServerSimulation,
                  icon: _isLoadingSimulation
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 1.5,
                          ),
                        )
                      : const Icon(Icons.play_circle_fill_rounded, size: 16),
                  label: const Text(
                    'تشغيل المحاكاة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: themeColor.primary,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          if (_simulationError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'خطأ محاكاة RPC سحابياً:\n${_simulationError!}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_simulationResult != null) ...[
            const SizedBox(height: 24),
            Builder(
              builder: (context) {
                final totalVal = _simulationResult!.total;
                final discountVal = _simulationResult!.discount;
                final subtotalVal = _simulationResult!.subtotal;
                final trace = _simulationResult!.executionTrace;

                final baseCommissionableAmount = subtotalVal + legacyExtras;
                final platformCommissionVal = baseCommissionableAmount * 0.20;
                final bonusesVal = 0.0;
                final technicianPayoutVal =
                    (baseCommissionableAmount * 0.80) + bonusesVal;
                final netProfitVal = totalVal - technicianPayoutVal;
                final globalCapHitVal = subtotalVal > 0
                    ? (discountVal / subtotalVal) >= 0.299
                    : false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PricingSummaryCards(
                      customerPrice: totalVal,
                      technicianPayout: technicianPayoutVal,
                      netProfit: netProfitVal,
                      discountImpact: discountVal,
                      globalCapHit: globalCapHitVal,
                    ),
                    const SizedBox(height: 20),
                    if (MediaQuery.of(context).size.width >= 700)
                      Row(
                        children: [
                          Expanded(
                            child: ProfitPreviewCard(
                              customerPrice: totalVal,
                              technicianPayout: technicianPayoutVal,
                              discountImpact: discountVal,
                              netProfit: netProfitVal,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TechnicianPayoutPreviewCard(
                              customerPrice: totalVal,
                              technicianPayout: technicianPayoutVal,
                              platformCommission: platformCommissionVal,
                              bonuses: bonusesVal,
                              promosAbsorbed: discountVal,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      ProfitPreviewCard(
                        customerPrice: totalVal,
                        technicianPayout: technicianPayoutVal,
                        discountImpact: discountVal,
                        netProfit: netProfitVal,
                      ),
                      const SizedBox(height: 16),
                      TechnicianPayoutPreviewCard(
                        customerPrice: totalVal,
                        technicianPayout: technicianPayoutVal,
                        platformCommission: platformCommissionVal,
                        bonuses: bonusesVal,
                        promosAbsorbed: discountVal,
                      ),
                    ],
                    const SizedBox(height: 20),
                    DiscountImpactCard(
                      discountAmount: discountVal,
                      subtotal: subtotalVal,
                      appliedCampaigns: const [],
                      globalCapHit: globalCapHitVal,
                    ),
                    const SizedBox(height: 24),
                    _buildSubsectionTitle(
                      themeColor,
                      'المسار الزمني لمراحل التسعير (Simulation Pipeline)',
                    ),
                    const SizedBox(height: 16),
                    SimulationStageTimeline(executionTrace: trace),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // --- Tab 8: Versions & Auditing Logs ---
  Widget _buildAuditTab() {
    return BlocBuilder<PricingGovernanceCubit, PricingGovernanceState>(
      builder: (context, state) {
        if (state is PricingGovernanceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PricingGovernanceLoaded) {
          final versions = state.versions;
          final auditLogs = state.auditLogs;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'التسلسل الزمني للنسخ المحفوظة (Pricing Versions)',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: versions.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد نسخ مؤرشفة بعد للأسعار.',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: versions.length,
                          itemBuilder: (context, index) {
                            final ver = versions[index];
                            return Container(
                              width: 180,
                              margin: const EdgeInsets.only(
                                left: 12,
                                bottom: 8,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ver.isActive
                                    ? Colors.amber.shade50
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: ver.isActive
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'نسخة سارية',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      if (ver.isActive)
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ver.id.substring(0, 8),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ver.createdAt
                                        .toLocal()
                                        .toString()
                                        .substring(0, 16),
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 9,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'سجل عمليات الحوكمة والتغييرات المالية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: auditLogs.isEmpty
                      ? const Center(
                          child: Text(
                            'سجل المراجعة والتدقيق فارغ حالياً.',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          itemCount: auditLogs.length,
                          itemBuilder: (context, index) {
                            final log = auditLogs[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  log['action'] == 'INSERT'
                                      ? Icons.add_circle_outline_rounded
                                      : Icons.published_with_changes_rounded,
                                  color: Colors.blueAccent,
                                ),
                                title: Text(
                                  log['action'] ?? 'تعديل سياق التسعير',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  'التاريخ: ${DateTime.parse(log['created_at']).toLocal().toString().substring(0, 16)}',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PricingVersionHistoryPage(
                                              auditLog: log,
                                            ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade100,
                                    foregroundColor: Colors.black87,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'عرض التفاصيل',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }

        return const Center(
          child: Text(
            'فشل تحميل السجلات.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        );
      },
    );
  }

  // --- Sub-widgets & helpers ---
  Widget _buildSubsectionTitle(ThemeColorExtension themeColor, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: themeColor.primary,
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget({
    required ThemeColorExtension themeColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    required String buttonText,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: themeColor.unselectedItem.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [themeColor.cardShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeColor.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: themeColor.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: themeColor.textPrimary.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  buttonText,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildModernInputDecoration(
    ThemeColorExtension themeColor, {
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
      prefixIcon: Icon(
        icon,
        size: 18,
        color: themeColor.unselectedItem.withValues(alpha: 0.6),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      fillColor: themeColor.background,
      filled: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: themeColor.unselectedItem.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeColor.primary, width: 1.5),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _addNewField() {
    setState(() {
      _fields.add(
        const DynamicFieldEntity(
          id: 'new_field',
          type: DynamicFieldType.number,
          label: {'ar': 'حقل جديد', 'en': 'New Field'},
          required: false,
        ),
      );
      // أضف مفتاح ثابت للحقل الجديد
      _fieldStableKeys.add(
        'fk_${DateTime.now().microsecondsSinceEpoch}_${_fields.length}',
      );
      _validateConfiguration();
      _initializeSimulatorDefaults();
    });
    _markDirty();
  }

  void _addNewComputedField() {
    setState(() {
      _computedFields.add(
        const ComputedFieldEntity(
          id: '',
          formula: '',
          label: {'ar': '', 'en': ''},
        ),
      );
      _validateConfiguration();
    });
    _markDirty();
  }

  void _updateFieldOrder(int currentIndex, String newOrderStr) {
    final newOrder = int.tryParse(newOrderStr);
    if (newOrder == null) return;

    int newIndex = newOrder - 1;
    if (newIndex < 0) newIndex = 0;
    if (newIndex >= _fields.length) newIndex = _fields.length - 1;

    if (newIndex != currentIndex) {
      setState(() {
        final field = _fields.removeAt(currentIndex);
        _fields.insert(newIndex, field);
        _validateConfiguration();
      });
    }
  }

  String _getMethodLabel(PricingMethod method) {
    switch (method) {
      case PricingMethod.fixed:
        return 'سعر ثابت';
      case PricingMethod.perSquareMeter:
        return 'سعر المتر المربع';
      case PricingMethod.perLinearMeter:
        return 'سعر المتر الطولي';
      case PricingMethod.perIssue:
        return 'سعر لكل وحدة / مشكلة';
      case PricingMethod.inspection:
        return 'سعر معاينة / فحص';
      default:
        return 'غير محدد';
    }
  }
}

// ── Field Card Widget (StatefulWidget to preserve TextEditingControllers) ──────
/// يحمل هذا الـ Widget الـ Controllers الخاصة به لمنع إغلاق الكيبورد
/// عند حدوث setState في الـ parent (ListView).
class _FieldCardWidget extends StatefulWidget {
  final DynamicFieldEntity field;
  final int index;
  final ThemeColorExtension themeColor;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onDelete;
  final ValueChanged<DynamicFieldEntity> onFieldChanged;
  final ValueChanged<String> onOrderChanged;

  const _FieldCardWidget({
    super.key,
    required this.field,
    required this.index,
    required this.themeColor,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onDelete,
    required this.onFieldChanged,
    required this.onOrderChanged,
  });

  @override
  State<_FieldCardWidget> createState() => _FieldCardWidgetState();
}

class _FieldCardWidgetState extends State<_FieldCardWidget> {
  late final TextEditingController _idController;
  late final TextEditingController _labelArController;
  late final TextEditingController _labelEnController;
  late final TextEditingController _minController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceModifierController;

  // New option insertion controllers
  late final TextEditingController _newOptIdController;
  late final TextEditingController _newOptLabelArController;
  late final TextEditingController _newOptLabelEnController;

  @override
  void initState() {
    super.initState();
    final f = widget.field;
    _idController = TextEditingController(text: f.id);
    _labelArController = TextEditingController(text: f.label['ar'] ?? '');
    _labelEnController = TextEditingController(text: f.label['en'] ?? '');
    _minController = TextEditingController(text: f.min?.toString() ?? '');
    _unitController = TextEditingController(text: f.unit ?? '');
    _priceModifierController = TextEditingController(
      text: f.priceModifier?.toString() ?? '',
    );
    _newOptIdController = TextEditingController();
    _newOptLabelArController = TextEditingController();
    _newOptLabelEnController = TextEditingController();
  }

  @override
  void didUpdateWidget(_FieldCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final f = widget.field;
    final old = oldWidget.field;
    // نحدث الـ controllers فقط إذا تغيّر الحقل من الخارج وليس بسبب كتابة المستخدم
    if (f.id != old.id && f.id != _idController.text) _idController.text = f.id;
    if ((f.label['ar'] ?? '') != (old.label['ar'] ?? '') &&
        (f.label['ar'] ?? '') != _labelArController.text) {
      _labelArController.text = f.label['ar'] ?? '';
    }
    if ((f.label['en'] ?? '') != (old.label['en'] ?? '') &&
        (f.label['en'] ?? '') != _labelEnController.text) {
      _labelEnController.text = f.label['en'] ?? '';
    }
    // عند تغيير النوع، نصفّر الحقول الرقمية
    if (f.type != old.type) {
      _minController.text = f.min?.toString() ?? '';
      _unitController.text = f.unit ?? '';
      _priceModifierController.text = f.priceModifier?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _labelArController.dispose();
    _labelEnController.dispose();
    _minController.dispose();
    _unitController.dispose();
    _priceModifierController.dispose();
    _newOptIdController.dispose();
    _newOptLabelArController.dispose();
    _newOptLabelEnController.dispose();
    super.dispose();
  }

  DynamicFieldEntity _copyWith({
    String? id,
    DynamicFieldType? type,
    Map<String, String>? label,
    bool? required,
    double? min,
    String? unit,
    double? priceModifier,
    List<DropdownOptionEntity>? options,
  }) {
    final f = widget.field;
    return DynamicFieldEntity(
      id: id ?? f.id,
      type: type ?? f.type,
      label: label ?? f.label,
      required: required ?? f.required,
      min: min ?? f.min,
      unit: unit ?? f.unit,
      priceModifier: priceModifier ?? f.priceModifier,
      options: options ?? f.options,
    );
  }


  String _getFieldTypeLabel(DynamicFieldType type) {
    switch (type) {
      case DynamicFieldType.number:
        return 'رقمي';
      case DynamicFieldType.toggle:
        return 'نعم/لا (تبديل)';
      case DynamicFieldType.dropdown:
        return 'قائمة منسدلة';
      case DynamicFieldType.optionsGroup:
        return 'مجموعة خيارات';
    }
  }

  InputDecoration _inputDec({required String label, required IconData icon}) {
    final t = widget.themeColor;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        color: t.unselectedItem,
      ),
      prefixIcon: Icon(
        icon,
        size: 18,
        color: t.unselectedItem.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: t.background,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: t.unselectedItem.withValues(alpha: 0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: t.unselectedItem.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: t.primary, width: 1.5),
      ),
    );
  }

  void _showEditOptionDialog(
    BuildContext context,
    DropdownOptionEntity option,
    List<DropdownOptionEntity> currentOptions,
  ) async {
    final updatedOptions = await showDialog<List<DropdownOptionEntity>>(
      context: context,
      builder: (context) {
        return _EditOptionDialog(
          option: option,
          currentOptions: currentOptions,
          themeColor: widget.themeColor,
          inputDec: _inputDec,
        );
      },
    );

    if (updatedOptions != null) {
      widget.onFieldChanged(_copyWith(options: updatedOptions));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.themeColor;
    final field = widget.field;
    final index = widget.index;
    final isExpanded = widget.isExpanded;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: t.unselectedItem.withValues(alpha: isDark ? 0.15 : 0.08),
          width: 1.2,
        ),
        boxShadow: [t.cardShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: t.primary.withValues(alpha: 0.8),
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Index badge + title
                Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: t.primary.withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: t.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        field.label['ar']?.isNotEmpty == true
                            ? field.label['ar']!
                            : field.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: t.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Row 2: Order input + action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'الترتيب:',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 50,
                          height: 36,
                          child: TextFormField(
                            initialValue: '${index + 1}',
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: t.textPrimary,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              fillColor: t.background,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: t.unselectedItem.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: t.unselectedItem.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: t.primary),
                              ),
                            ),
                            onChanged: widget.onOrderChanged,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: IconButton(
                            icon: Icon(
                              Icons.settings_rounded,
                              color: isExpanded ? t.primary : t.unselectedItem,
                            ),
                            onPressed: widget.onToggleExpand,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: widget.onDelete,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.all(8),
                            minimumSize: const Size(36, 36),
                          ),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Expanded settings panel
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: isExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, thickness: 0.5),
                            ),
                            // Field Type
                            DropdownButtonFormField<DynamicFieldType>(
                              initialValue: field.type,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: t.textPrimary,
                              ),
                              decoration: _inputDec(
                                label: 'نوع الحقل',
                                icon: Icons.merge_type_rounded,
                              ),
                              items: DynamicFieldType.values
                                  .map(
                                    (type) =>
                                        DropdownMenuItem<DynamicFieldType>(
                                          value: type,
                                          child: Text(_getFieldTypeLabel(type)),
                                        ),
                                  )
                                  .toList(),
                              onChanged: (newType) {
                                if (newType != null) {
                                  widget.onFieldChanged(
                                    DynamicFieldEntity(
                                      id: field.id,
                                      type: newType,
                                      label: field.label,
                                      required: field.required,
                                      min: newType == DynamicFieldType.number
                                          ? 0.0
                                          : null,
                                      unit: newType == DynamicFieldType.number
                                          ? ''
                                          : null,
                                      priceModifier:
                                          newType == DynamicFieldType.number
                                          ? 0.0
                                          : null,
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            // ID
                            TextFormField(
                              controller: _idController,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: t.textPrimary,
                              ),
                              decoration: _inputDec(
                                label: 'معرف الحقل (ID Unique - مثل: area)',
                                icon: Icons.tag_rounded,
                              ),
                              onChanged: (val) =>
                                  widget.onFieldChanged(_copyWith(id: val)),
                            ),
                            const SizedBox(height: 12),
                            // Arabic label
                            TextFormField(
                              controller: _labelArController,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: t.textPrimary,
                              ),
                              decoration: _inputDec(
                                label: 'العنوان بالعربية (مثل: المساحة)',
                                icon: Icons.text_fields_rounded,
                              ),
                              onChanged: (val) {
                                final labels = Map<String, String>.from(
                                  field.label,
                                );
                                labels['ar'] = val;
                                widget.onFieldChanged(_copyWith(label: labels));
                              },
                            ),
                            const SizedBox(height: 12),
                            // English label
                            TextFormField(
                              controller: _labelEnController,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: t.textPrimary,
                              ),
                              decoration: _inputDec(
                                label: 'العنوان بالإنجليزية (مثل: Area)',
                                icon: Icons.language_rounded,
                              ),
                              onChanged: (val) {
                                final labels = Map<String, String>.from(
                                  field.label,
                                );
                                labels['en'] = val;
                                widget.onFieldChanged(_copyWith(label: labels));
                              },
                            ),
                            const SizedBox(height: 12),
                            // Required switch
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: t.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: t.unselectedItem.withValues(
                                    alpha: 0.15,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        size: 18,
                                        color: t.secondary,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'حقل مطلوب؟',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: field.required,
                                    activeThumbColor: t.secondary,
                                    onChanged: (val) => widget.onFieldChanged(
                                      _copyWith(required: val),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Numeric-only fields
                            if (field.type == DynamicFieldType.number) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _minController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: t.textPrimary,
                                ),
                                decoration: _inputDec(
                                  label: 'الحد الأدنى للقيمة (مثل: 1)',
                                  icon: Icons.unfold_less_rounded,
                                ),
                                onChanged: (val) => widget.onFieldChanged(
                                  _copyWith(min: double.tryParse(val)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _unitController,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: t.textPrimary,
                                ),
                                decoration: _inputDec(
                                  label: 'وحدة القياس الخاصة (مثل: متر مربع)',
                                  icon: Icons.square_foot_rounded,
                                ),
                                onChanged: (val) =>
                                    widget.onFieldChanged(_copyWith(unit: val)),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _priceModifierController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: t.textPrimary,
                                ),
                                decoration: _inputDec(
                                  label: 'معامل السعر (مثال: 1.2 أو 50)',
                                  icon: Icons.toll_rounded,
                                ),
                                onChanged: (val) => widget.onFieldChanged(
                                  _copyWith(
                                    priceModifier: double.tryParse(val),
                                  ),
                                ),
                              ),
                            ],
                            // Dropdown options configurator
                            if (field.type == DynamicFieldType.dropdown) ...[
                              const SizedBox(height: 16),
                              const Divider(height: 1, thickness: 0.5),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.list_alt_rounded, size: 16, color: t.primary),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'خيارات القائمة المنسدلة (Dropdown Options)',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // List of existing options
                              if (field.options == null || field.options!.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: t.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: t.unselectedItem.withValues(alpha: 0.1)),
                                  ),
                                  child: Text(
                                    'لا توجد خيارات مضافة بعد. الرجاء إضافة خيار أدناه.',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      color: t.unselectedItem,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              else
                                ...field.options!.map((opt) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: t.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: t.unselectedItem.withValues(alpha: 0.15)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: t.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            opt.id,
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: t.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'العربية: ${opt.label['ar'] ?? ''}',
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 11,
                                                  color: t.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                'English: ${opt.label['en'] ?? ''}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: t.unselectedItem,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                         IconButton(
                                           icon: Icon(Icons.settings_suggest_outlined, size: 18, color: t.primary),
                                           onPressed: () => _showEditOptionDialog(context, opt, field.options ?? []),
                                         ),
                                         const SizedBox(width: 4),
                                         IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                          onPressed: () {
                                            final updatedOptions = List<DropdownOptionEntity>.from(field.options ?? []);
                                            updatedOptions.removeWhere((o) => o.id == opt.id);
                                            widget.onFieldChanged(_copyWith(options: updatedOptions));
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              const SizedBox(height: 12),
                              // Inline option adder form
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: t.background.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: t.primary.withValues(alpha: 0.15)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'إضافة خيار جديد:',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: t.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _newOptIdController,
                                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                                            decoration: InputDecoration(
                                              labelText: 'معرف الخيار (ID)',
                                              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 10),
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _newOptLabelArController,
                                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                                            decoration: InputDecoration(
                                              labelText: 'الاسم بالعربية',
                                              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 10),
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _newOptLabelEnController,
                                            style: const TextStyle(fontSize: 11),
                                            decoration: InputDecoration(
                                              labelText: 'الاسم بالإنجليزية',
                                              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 10),
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          final id = _newOptIdController.text.trim();
                                          final labelAr = _newOptLabelArController.text.trim();
                                          final labelEn = _newOptLabelEnController.text.trim();

                                          if (id.isEmpty || labelAr.isEmpty || labelEn.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'الرجاء تعبئة جميع حقول الخيار الجديد (المعرف، العربية، الإنجليزية).',
                                                  style: TextStyle(fontFamily: 'Cairo'),
                                                ),
                                                backgroundColor: Colors.amber,
                                              ),
                                            );
                                            return;
                                          }

                                          // Validation: Alphanumeric and underscores only
                                          final validIdRegex = RegExp(r'^[a-zA-Z0-9_]+$');
                                          if (!validIdRegex.hasMatch(id)) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'معرف الخيار يجب أن يحتوي على أحرف وأرقام وشرطة سفلية فقط وبدون مسافات.',
                                                  style: TextStyle(fontFamily: 'Cairo'),
                                                ),
                                                backgroundColor: Colors.amber,
                                              ),
                                            );
                                            return;
                                          }

                                          final existingOptions = field.options ?? [];
                                          if (existingOptions.any((o) => o.id == id)) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'هذا المعرف مضاف بالفعل لهذا الحقل. يرجى استخدام معرف فريد.',
                                                  style: TextStyle(fontFamily: 'Cairo'),
                                                ),
                                                backgroundColor: Colors.amber,
                                              ),
                                            );
                                            return;
                                          }

                                          final newOption = DropdownOptionEntity(
                                            id: id,
                                            label: {'ar': labelAr, 'en': labelEn},
                                          );

                                          final updatedOptions = List<DropdownOptionEntity>.from(existingOptions)..add(newOption);
                                          widget.onFieldChanged(_copyWith(options: updatedOptions));

                                          // Clear inputs
                                          _newOptIdController.clear();
                                          _newOptLabelArController.clear();
                                          _newOptLabelEnController.clear();
                                        },
                                        icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                                        label: const Text(
                                          'إضافة عنصر خيار',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: t.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],

                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── AST Human-Readable Renderer ───────────────────────────────────────────────
class _AstReadableRenderer extends StatelessWidget {
  final Map<String, dynamic> astJson;
  final int depth;

  const _AstReadableRenderer({required this.astJson, this.depth = 0});

  static const Map<String, String> _fieldLabels = {
    'area': 'المساحة (م²)',
    'furnished': 'مفروش',
    'total_linear_meters': 'المتر الطولي',
  };

  static const Map<String, String> _operatorLabels = {
    '>': 'أكبر من',
    '<': 'أصغر من',
    '>=': 'أكبر من أو يساوي',
    '<=': 'أصغر من أو يساوي',
    '==': 'يساوي',
    '!=': 'لا يساوي',
  };

  @override
  Widget build(BuildContext context) {
    final typeVal = astJson['type'] as String?;

    if (typeVal == 'AND' || typeVal == 'OR') {
      return _buildLogicalGroup(typeVal!);
    }
    return _buildLeafChip();
  }

  Widget _buildLogicalGroup(String type) {
    final conditions = (astJson['conditions'] as List? ?? [])
        .whereType<Map>()
        .map((c) => Map<String, dynamic>.from(c))
        .toList();

    final isAnd = type == 'AND';
    final groupColor = isAnd ? Colors.indigo : Colors.teal;
    final label = isAnd
        ? 'AND — جميع الشروط التالية'
        : 'OR — أيٌّ من الشروط التالية';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: groupColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: groupColor.shade700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        ...conditions.map(
          (c) => Padding(
            padding: EdgeInsets.only(right: (depth + 1) * 12.0, bottom: 6),
            child: _AstReadableRenderer(astJson: c, depth: depth + 1),
          ),
        ),
      ],
    );
  }

  Widget _buildLeafChip() {
    final field = astJson['field'] as String? ?? '?';
    final op = astJson['operator'] as String? ?? '?';
    final val = astJson['value'];

    final fieldLabel = _fieldLabels[field] ?? field;
    final opLabel = _operatorLabels[op] ?? op;

    String valueDisplay;
    if (val == true || val == 'true') {
      valueDisplay = 'نعم ✅';
    } else if (val == false || val == 'false') {
      valueDisplay = 'لا ❌';
    } else {
      valueDisplay = val?.toString() ?? '?';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_right_rounded,
            size: 14,
            color: Colors.purple.shade400,
          ),
          const SizedBox(width: 4),
          Text(
            fieldLabel,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A1A8E),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                opLabel,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 9,
                  color: Colors.purple.shade800,
                ),
              ),
            ),
          ),
          Text(
            valueDisplay,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Discount Validity Chip ─────────────────────────────────────────────────────
class _DiscountValidityChip extends StatelessWidget {
  final PricingDiscountEntity discount;

  const _DiscountValidityChip({required this.discount});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = discount.startDate;
    final end = discount.endDate;

    final bool isExpired = end != null && end.isBefore(now);
    final bool isUpcoming = start != null && start.isAfter(now);

    Color bgColor;
    Color fgColor;
    String label;
    IconData icon;

    if (isExpired) {
      bgColor = Colors.red.shade50;
      fgColor = Colors.red.shade700;
      label = 'منتهي';
      icon = Icons.cancel_rounded;
    } else if (isUpcoming) {
      bgColor = Colors.blue.shade50;
      fgColor = Colors.blue.shade700;
      label = 'قادم';
      icon = Icons.schedule_rounded;
    } else {
      bgColor = Colors.green.shade50;
      fgColor = Colors.green.shade700;
      label = 'نشط';
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit Option Dialog ────────────────────────────────────────────────────────
class _EditOptionDialog extends StatefulWidget {
  final DropdownOptionEntity option;
  final List<DropdownOptionEntity> currentOptions;
  final ThemeColorExtension themeColor;
  final InputDecoration Function({required String label, required IconData icon}) inputDec;

  const _EditOptionDialog({
    required this.option,
    required this.currentOptions,
    required this.themeColor,
    required this.inputDec,
  });

  @override
  State<_EditOptionDialog> createState() => _EditOptionDialogState();
}

class _EditOptionDialogState extends State<_EditOptionDialog> {
  late final TextEditingController _editIdController;
  late final TextEditingController _editLabelArController;
  late final TextEditingController _editLabelEnController;

  @override
  void initState() {
    super.initState();
    _editIdController = TextEditingController(text: widget.option.id);
    _editLabelArController = TextEditingController(text: widget.option.label['ar'] ?? '');
    _editLabelEnController = TextEditingController(text: widget.option.label['en'] ?? '');
  }

  @override
  void dispose() {
    _editIdController.dispose();
    _editLabelArController.dispose();
    _editLabelEnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.themeColor;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: t.cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [t.cardShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_rounded, color: t.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'تعديل عنصر خيار القائمة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _editIdController,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: widget.inputDec(
                label: 'معرف الخيار (ID)',
                icon: Icons.tag_rounded,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _editLabelArController,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              decoration: widget.inputDec(
                label: 'الاسم بالعربية',
                icon: Icons.text_fields_rounded,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _editLabelEnController,
              style: const TextStyle(fontSize: 13),
              decoration: widget.inputDec(
                label: 'الاسم بالإنجليزية',
                icon: Icons.language_rounded,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: t.unselectedItem,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () {
                    final newId = _editIdController.text.trim();
                    final newLabelAr = _editLabelArController.text.trim();
                    final newLabelEn = _editLabelEnController.text.trim();

                    if (newId.isEmpty || newLabelAr.isEmpty || newLabelEn.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'الرجاء تعبئة جميع حقول الخيار.',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                          backgroundColor: Colors.amber,
                        ),
                      );
                      return;
                    }

                    // Validation: Alphanumeric and underscores only
                    final validIdRegex = RegExp(r'^[a-zA-Z0-9_]+$');
                    if (!validIdRegex.hasMatch(newId)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'معرف الخيار يجب أن يحتوي على أحرف وأرقام وشرطة سفلية فقط وبدون مسافات.',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                          backgroundColor: Colors.amber,
                        ),
                      );
                      return;
                    }

                    // Check uniqueness if ID changed
                    if (newId != widget.option.id && widget.currentOptions.any((o) => o.id == newId)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'هذا المعرف مستخدم بالفعل في خيار آخر.',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                          backgroundColor: Colors.amber,
                        ),
                      );
                      return;
                    }

                    final updatedOptions = widget.currentOptions.map((o) {
                      if (o.id == widget.option.id) {
                        return DropdownOptionEntity(
                          id: newId,
                          label: {'ar': newLabelAr, 'en': newLabelEn},
                        );
                      }
                      return o;
                    }).toList();

                    Navigator.of(context).pop(updatedOptions);
                  },
                  child: const Text(
                    'حفظ التعديل',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashed Line Painter ──────────────────────────────────────────────────────

class DashedLinePainter extends CustomPainter {
  final Color color;
  const DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    const double dashWidth = 5;
    const double dashSpace = 4;
    double startX = 14;
    while (startX < size.width - 14) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
