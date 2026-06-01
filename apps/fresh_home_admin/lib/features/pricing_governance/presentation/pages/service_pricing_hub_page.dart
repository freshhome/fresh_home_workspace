import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/dialogs/dialog_helper.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/dynamic_field.dart';

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
  String? _basePriceFormula;
  double? _minPrice;

  // Simulator Inputs State
  final Map<String, dynamic> _simulatorInputs = {};
  final List<String> _simulatorSelectedOptions = [];

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
      _minPrice = price.minPrice?.toDouble();
    } else {
      _pricingMethod = PricingMethod.fixed;
      _basePrice = 0.0;
      _unit = 'ريال';
      _fields = [];
      _options = [];
      _basePriceFormula = null;
      _formulaController = TextEditingController(text: '');
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
    for (final field in _fields) {
      if (field.type == DynamicFieldType.number) {
        _simulatorInputs[field.id] = field.min?.toDouble() ?? 100.0;
      } else if (field.type == DynamicFieldType.toggle) {
        _simulatorInputs[field.id] = false;
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

  double _calculateSimulatedBase() {
    double basePrice = _basePrice;
    double primaryVal = 1.0;

    for (final field in _fields) {
      final dynamicVal = _simulatorInputs[field.id];
      if (dynamicVal != null) {
        if (field.type == DynamicFieldType.number) {
          double val = (dynamicVal as num).toDouble();
          if (field.min != null && val < field.min!) {
            val = field.min!.toDouble();
          }
          if (field.id == 'area' || field.id == 'total_linear_meters') {
            primaryVal = val;
          } else {
            if (field.priceModifier != null) {
              basePrice += val * field.priceModifier!;
            }
          }
        } else if (field.type == DynamicFieldType.toggle) {
          if (dynamicVal == true && field.priceModifier != null) {
            double modifier = field.priceModifier!.toDouble();
            if (modifier <= 5.0) {
              basePrice *= modifier;
            }
          }
        }
      }
    }

    if (_pricingMethod == PricingMethod.perSquareMeter ||
        _pricingMethod == PricingMethod.perLinearMeter) {
      basePrice *= primaryVal;
    }

    return basePrice;
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

  Widget _buildStatusBar() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "09:41",
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.signal_cellular_4_bar_rounded,
                color: Colors.white,
                size: 10,
              ),
              SizedBox(width: 4),
              Icon(Icons.wifi_rounded, color: Colors.white, size: 10),
              SizedBox(width: 4),
              Icon(Icons.battery_5_bar_rounded, color: Colors.white, size: 10),
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

  Widget _buildDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: List.generate(
          24,
          (index) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 1,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
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
            Text(
              "محاكاة شاشة العميل (Interactive Emulator)",
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: themeColor.primary,
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
              child: Stack(
                children: [
                  Scaffold(
                    backgroundColor: const Color(
                      0xFF090D1A,
                    ), // Sleek deep background for mockup
                    appBar: AppBar(
                      backgroundColor: const Color(0xFF131A30),
                      title: const Text(
                        "حجز الخدمة",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      centerTitle: true,
                      automaticallyImplyLeading: false,
                      elevation: 0,
                      toolbarHeight: 52,
                    ),
                    body: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        ..._buildEmulatorInputWidgets(themeColor),
                        const SizedBox(height: 12),
                        if (_options.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            child: Text(
                              "الخيارات والإضافات المتوفرة",
                              style: TextStyle(
                                color: Colors.white70,
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._options.map((opt) {
                            final isSelected = _simulatorSelectedOptions
                                .contains(opt.key);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF131A30,
                                ).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? themeColor.secondary.withValues(
                                          alpha: 0.6,
                                        )
                                      : const Color(0xFF1E293B),
                                  width: 1.2,
                                ),
                              ),
                              child: Theme(
                                data: ThemeData.dark(),
                                child: CheckboxListTile(
                                  title: Text(
                                    opt.key ?? '',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '+${opt.value} ريال',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: themeColor.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  value: isSelected,
                                  activeColor: themeColor.secondary,
                                  checkColor: Colors.white,
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true && opt.key != null) {
                                        _simulatorSelectedOptions.add(opt.key!);
                                      } else {
                                        _simulatorSelectedOptions.remove(
                                          opt.key,
                                        );
                                      }
                                    });
                                  },
                                ),
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 20),
                        _buildInvoiceBreakdown(themeColor, themeText),
                      ],
                    ),
                  ),
                  // Status bar and Notch Overlay
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: const Color(0xFF131A30),
                      height: 24,
                      child: Stack(
                        children: [_buildStatusBar(), _buildPhoneNotch()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildEmulatorInputWidgets(ThemeColorExtension themeColor) {
    return _fields.map((field) {
      final String label = field.label['ar'] ?? field.id;

      if (field.type == DynamicFieldType.number) {
        final double currentVal =
            (_simulatorInputs[field.id] as num?)?.toDouble() ??
            field.min?.toDouble() ??
            100.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131A30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${currentVal.toStringAsFixed(0)} ${field.unit ?? ''}',
                      style: TextStyle(
                        color: themeColor.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: themeColor.secondary,
                  inactiveTrackColor: const Color(0xFF1E293B),
                  thumbColor: Colors.white,
                  overlayColor: themeColor.secondary.withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                ),
                child: Slider(
                  value: currentVal,
                  min: (field.min ?? 0.0).toDouble(),
                  max: ((field.min ?? 100.0) * 10).toDouble(),
                  onChanged: (val) {
                    setState(() {
                      _simulatorInputs[field.id] = val;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      } else if (field.type == DynamicFieldType.toggle) {
        final bool currentVal = _simulatorInputs[field.id] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF131A30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
          ),
          child: Theme(
            data: ThemeData.dark(),
            child: SwitchListTile(
              title: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'Cairo',
                ),
              ),
              value: currentVal,
              activeThumbColor: themeColor.secondary,
              activeTrackColor: themeColor.secondary.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: const Color(0xFF1E293B),
              dense: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onChanged: (val) {
                setState(() {
                  _simulatorInputs[field.id] = val;
                });
              },
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }).toList();
  }

  Widget _buildInvoiceBreakdown(
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
  ) {
    final basePriceSimulated = _calculateSimulatedBase();
    final extrasSimulated = _calculateSimulatedExtras();
    final totalSimulated = basePriceSimulated + extrasSimulated;

    final finalBillTotal = _simulationResult != null
        ? _simulationResult!.total
        : totalSimulated;
    final isCloudUsed = _simulationResult != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCloudUsed
              ? themeColor.secondary.withValues(alpha: 0.6)
              : const Color(0xFF1E293B),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "تفصيل الحساب المالي",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: 'Cairo',
                ),
              ),
              if (isCloudUsed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: themeColor.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: themeColor.secondary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "مدقق سحابياً",
                    style: TextStyle(
                      color: themeColor.secondary,
                      fontSize: 9,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          _buildDashedDivider(),
          _buildBillRow(
            "سعر الوحدة الأساسي",
            "${_basePrice.toStringAsFixed(0)} ريال",
          ),
          _buildBillRow(
            "حساب الحقول والمعاملات",
            "${basePriceSimulated.toStringAsFixed(0)} ريال",
          ),
          _buildBillRow(
            "خيارات وإضافات مخصصة",
            "+ ${extrasSimulated.toStringAsFixed(0)} ريال",
          ),
          if (isCloudUsed && _simulationResult!.discount > 0)
            _buildBillRow(
              "الخصومات والحملات النشطة",
              "- ${_simulationResult!.discount.toStringAsFixed(0)} ريال",
              color: Colors.redAccent,
            ),
          _buildDashedDivider(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeColor.secondary.withValues(alpha: 0.1),
                  themeColor.secondary.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeColor.secondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "الإجمالي النهائي",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  "${finalBillTotal.toStringAsFixed(0)} ريال",
                  style: TextStyle(
                    color: themeColor.secondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(
    String label,
    String val, {
    Color color = Colors.white70,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontFamily: 'Cairo'),
          ),
          Text(
            val,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
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
                          initialValue: _unit,
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
                          key: ValueKey('min_price_${_minPrice ?? 0}'),
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
                                'مثال: 2000 ريال (اتركه فارغاً لعدم تحديد حد أدنى)',
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
        const SizedBox(height: 20),
        const Text(
          'أمثلة وصيغ جاهزة للتحميل:',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: themeColor.textPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            labelText: 'اختر صيغة نموذجية للتحميل السريع',
            fillColor: themeColor.cardBackground,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: const [
            DropdownMenuItem(
              value: '({area} * 5.5) + 150',
              child: Text('سعر المتر المربع + رسوم تأسيس'),
            ),
            DropdownMenuItem(
              value: '({bathrooms} * 150) + ({kitchens} * 200) + 100',
              child: Text('حساب عدد الغرف/الحمامات المستقل'),
            ),
            DropdownMenuItem(
              value: '{width} * {height} * 25',
              child: Text('حساب الطول × العرض للمساحات الزجاجية'),
            ),
            DropdownMenuItem(
              value: '{total_linear_meters} * 75',
              child: Text('سعر المتر الطولي الثابت'),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _basePriceFormula = val;
                _formulaController.text = val;
              });
            }
          },
        ),
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
          final discounts = state.discounts;
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
                                            color: Colors.black87,
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
                    ),
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
