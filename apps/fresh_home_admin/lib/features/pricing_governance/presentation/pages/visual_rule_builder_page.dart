import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared/shared.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/dynamic_field.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/pricing_rule_entity.dart';
import '../../domain/use_cases/upsert_pricing_rule_usecase.dart';

class VisualRuleBuilderPage extends StatefulWidget {
  final String subServiceId;

  const VisualRuleBuilderPage({super.key, required this.subServiceId});

  @override
  State<VisualRuleBuilderPage> createState() => _VisualRuleBuilderPageState();
}

class _VisualRuleBuilderPageState extends State<VisualRuleBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  final _ruleNameController = TextEditingController();
  final _modifierValueController = TextEditingController();

  String _actionType = 'multiply';
  String _actionTarget = 'subtotal';
  int _priority = 1;

  bool _isLoading = true;
  String? _errorMessage;
  List<DynamicFieldEntity> _dynamicFields = [];

  // Root Logical Group of the AST
  final AstNode _astRoot = AstNode(
    type: 'AND',
    conditions: [
      AstNode(type: 'LEAF', field: 'area', operator: '>', value: '100'),
    ],
  );

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  Future<void> _loadService() async {
    try {
      final result = await getIt<GetServiceByIdUseCase>().call(widget.subServiceId);
      result.fold(
        (failure) {
          setState(() {
            _errorMessage = 'فشل تحميل تفاصيل الخدمة: ${failure.message}';
            _isLoading = false;
          });
        },
        (service) {
          setState(() {
            _dynamicFields = service.price?.fields ?? [];
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ غير متوقع عند تحميل الخدمة: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _ruleNameController.dispose();
    _modifierValueController.dispose();
    super.dispose();
  }

  Future<void> _saveRule() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final double modValue = double.parse(_modifierValueController.text);
      final rule = PricingRuleEntity(
        id: const Uuid().v4(),
        subServiceId: widget.subServiceId,
        ruleName: _ruleNameController.text,
        conditionAst: _astRoot.toJson(),
        actionType: _actionType,
        actionValue: modValue,
        actionTarget: _actionTarget,
        priority: _priority,
        isActive: true,
      );

      await getIt<UpsertPricingRuleUseCase>().call(rule);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [VisualRuleBuilderPage Error]: $e\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red.shade900, content: Text('فشل حفظ قاعدة AST الشرطية: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;

    final defaultIds = {'area', 'furnished', 'total_linear_meters'};
    final allFields = [
      const DynamicFieldEntity(
        id: 'area',
        type: DynamicFieldType.number,
        label: {'ar': 'المساحة', 'en': 'Area'},
      ),
      const DynamicFieldEntity(
        id: 'furnished',
        type: DynamicFieldType.toggle,
        label: {'ar': 'مفروش', 'en': 'Furnished'},
      ),
      const DynamicFieldEntity(
        id: 'total_linear_meters',
        type: DynamicFieldType.number,
        label: {'ar': 'المتر الطولي', 'en': 'Total Linear Meters'},
      ),
      ..._dynamicFields.where((f) => !defaultIds.contains(f.id)),
    ];

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        title: const Text('باني القواعد الشرطية المرئي (AST)', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontFamily: 'Cairo', color: Colors.red, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _loadService();
                          },
                          child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ],
                    ),
                  ),
                )
              : Directionality(
                  textDirection: TextDirection.rtl,
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Basic parameters block
                        Container(
                          decoration: BoxDecoration(
                            color: themeColor.cardBackground,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [themeColor.cardShadow],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _ruleNameController,
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: themeColor.textPrimary),
                                  decoration: _buildModernInputDecoration(
                                    themeColor,
                                    label: 'اسم القاعدة الشرطية (مثال: رسوم مساحات البنتهاوس)',
                                    icon: Icons.title_rounded,
                                  ),
                                  validator: (value) => value == null || value.isEmpty ? 'حقل إلزامي' : null,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: _actionType,
                                  isExpanded: true,
                                  dropdownColor: themeColor.cardBackground,
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: themeColor.textPrimary),
                                  decoration: _buildModernInputDecoration(
                                    themeColor,
                                    label: 'نوع التعديل المالي (Action Type)',
                                    icon: Icons.settings_applications_rounded,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'multiply', child: Text('ضرب الحساب الكلي (Multiply)', style: TextStyle(fontFamily: 'Cairo'))),
                                    DropdownMenuItem(value: 'add', child: Text('رسوم إضافية ثابتة (Add)', style: TextStyle(fontFamily: 'Cairo'))),
                                    DropdownMenuItem(value: 'override', child: Text('تجاوز السعر بالكامل (Override)', style: TextStyle(fontFamily: 'Cairo'))),
                                    DropdownMenuItem(value: 'percent', child: Text('نسبة مئوية (Percent)', style: TextStyle(fontFamily: 'Cairo'))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _actionType = val;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: _actionTarget,
                                  isExpanded: true,
                                  dropdownColor: themeColor.cardBackground,
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: themeColor.textPrimary),
                                  decoration: _buildModernInputDecoration(
                                    themeColor,
                                    label: 'هدف التعديل (Action Target)',
                                    icon: Icons.gps_fixed_rounded,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'subtotal', child: Text('المجموع الفرعي (Subtotal)', style: TextStyle(fontFamily: 'Cairo'))),
                                    DropdownMenuItem(value: 'base_price', child: Text('السعر الأساسي فقط (Base Price)', style: TextStyle(fontFamily: 'Cairo'))),
                                    DropdownMenuItem(value: 'extra_fees', child: Text('الرسوم الإضافية فقط (Extra Fees)', style: TextStyle(fontFamily: 'Cairo'))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _actionTarget = val;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _modifierValueController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: themeColor.textPrimary),
                                  decoration: _buildModernInputDecoration(
                                    themeColor,
                                    label: _actionType == 'multiply' ? 'معامل الضرب (مثال: 1.15 لزيادة 15%)' : 'القيمة المالية للعملية (مثال: 150)',
                                    icon: Icons.attach_money_rounded,
                                  ),
                                  validator: (value) => double.tryParse(value ?? '') == null ? 'قيمة غير صالحة' : null,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('أولوية التقييم والتطبيق:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: themeColor.textPrimary)),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove_circle_outline_rounded, color: themeColor.primary),
                                          onPressed: () {
                                            if (_priority > 1) {
                                              setState(() => _priority--);
                                            }
                                          },
                                        ),
                                        Text('$_priority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor.textPrimary)),
                                        IconButton(
                                          icon: Icon(Icons.add_circle_outline_rounded, color: themeColor.primary),
                                          onPressed: () {
                                            setState(() => _priority++);
                                          },
                                        ),
                                      ],
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Visual AST rule block
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Text(
                            'شجرة الشروط والمنطق الرياضي (AST Tree)',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: themeColor.primary,
                            ),
                          ),
                        ),
                        AstNodeBuilderWidget(
                          node: _astRoot,
                          dynamicFields: allFields,
                          onChanged: () {
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 32),

                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _saveRule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'تطبيق وحفظ القاعدة في AST',
                                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
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
      prefixIcon: Icon(icon, size: 18, color: themeColor.unselectedItem.withValues(alpha: 0.6)),
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
        borderSide: BorderSide(
          color: themeColor.primary,
          width: 1.5,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ── AstNode Tree Data Structure ──────────────────────────────────────────────

class AstNode {
  String type; // 'AND' | 'OR' | 'LEAF'
  String? field;
  String? operator;
  String? value;
  List<AstNode> conditions;

  AstNode({
    required this.type,
    this.field,
    this.operator,
    this.value,
    List<AstNode>? conditions,
  }) : conditions = conditions ?? [];

  Map<String, dynamic> toJson() {
    if (type == 'AND' || type == 'OR') {
      return {
        'type': type,
        'conditions': conditions.map((c) => c.toJson()).toList(),
      };
    } else {
      dynamic parsedValue = value;
      if (value == 'true') {
        parsedValue = true;
      } else if (value == 'false') {
        parsedValue = false;
      } else if (double.tryParse(value ?? '') != null) {
        parsedValue = double.parse(value!);
      }
      return {
        'field': field,
        'operator': operator,
        'value': parsedValue,
      };
    }
  }

  factory AstNode.fromJson(Map<String, dynamic> json) {
    final typeVal = json['type'] as String?;
    if (typeVal == 'AND' || typeVal == 'OR') {
      final condsList = json['conditions'] as List? ?? [];
      return AstNode(
        type: typeVal!,
        conditions: condsList
            .map((c) => AstNode.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
      );
    } else {
      return AstNode(
        type: 'LEAF',
        field: json['field'] as String?,
        operator: json['operator'] as String?,
        value: json['value']?.toString(),
      );
    }
  }
}

// ── AstNodeBuilderWidget UI Editor ───────────────────────────────────────────

class AstNodeBuilderWidget extends StatelessWidget {
  final AstNode node;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  final int depth;
  final List<DynamicFieldEntity> dynamicFields;

  const AstNodeBuilderWidget({
    super.key,
    required this.node,
    required this.onChanged,
    required this.dynamicFields,
    this.onRemove,
    this.depth = 0,
  });

  InputDecoration _buildMiniInputDecoration(
    ThemeColorExtension themeColor, {
    String? hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      fillColor: themeColor.background,
      filled: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: themeColor.unselectedItem.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: themeColor.primary,
          width: 1.2,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;

    if (node.type == 'AND' || node.type == 'OR') {
      final groupBgColor = node.type == 'AND'
          ? (isDark ? Colors.blue.shade900.withValues(alpha: 0.2) : Colors.blue.shade50.withValues(alpha: 0.5))
          : (isDark ? Colors.orange.shade900.withValues(alpha: 0.2) : Colors.orange.shade50.withValues(alpha: 0.5));

      final groupBorderColor = node.type == 'AND'
          ? (isDark ? Colors.blue.shade700 : Colors.blue.shade300)
          : (isDark ? Colors.orange.shade700 : Colors.orange.shade300);

      final dropdownTextColor = node.type == 'AND'
          ? (isDark ? Colors.blue.shade200 : Colors.blue.shade900)
          : (isDark ? Colors.orange.shade200 : Colors.orange.shade900);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeColor.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: groupBorderColor,
            width: 1.5,
          ),
          boxShadow: [themeColor.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: groupBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: groupBorderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: node.type,
                      dropdownColor: themeColor.cardBackground,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: dropdownTextColor,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'AND',
                          child: Text('AND (كل الشروط)'),
                        ),
                        DropdownMenuItem(
                          value: 'OR',
                          child: Text('OR (أحد الشروط)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          node.type = val;
                          onChanged();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'مجموعة شروط (مستوى ${depth + 1})',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: themeColor.textPrimary.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                    onPressed: onRemove,
                  ),
              ],
            ),
            Divider(
              height: 24,
              thickness: 0.5,
              color: themeColor.unselectedItem.withValues(alpha: 0.15),
            ),
            if (node.conditions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 24,
                        color: themeColor.unselectedItem.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لا توجد شروط في هذه المجموعة. اضغط على الأزرار أدناه للإضافة.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: themeColor.unselectedItem.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...node.conditions.map((childNode) {
                return AstNodeBuilderWidget(
                  node: childNode,
                  depth: depth + 1,
                  dynamicFields: dynamicFields,
                  onChanged: onChanged,
                  onRemove: () {
                    node.conditions.remove(childNode);
                    onChanged();
                  },
                );
              }),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final firstField = dynamicFields.isNotEmpty
                        ? dynamicFields.first
                        : const DynamicFieldEntity(
                            id: 'area',
                            type: DynamicFieldType.number,
                            label: {'ar': 'المساحة'},
                          );
                    final isBoolOrDropdown = firstField.type == DynamicFieldType.toggle || firstField.type == DynamicFieldType.dropdown;
                    node.conditions.add(AstNode(
                      type: 'LEAF',
                      field: firstField.id,
                      operator: isBoolOrDropdown ? '=' : '>',
                      value: firstField.type == DynamicFieldType.toggle
                          ? 'true'
                          : (firstField.type == DynamicFieldType.dropdown
                              ? (firstField.options?.isNotEmpty == true ? firstField.options!.first.id : '')
                              : '100'),
                    ));
                    onChanged();
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'إضافة شرط فرعي',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.blue.shade900.withValues(alpha: 0.25) : Colors.blue.shade50,
                    foregroundColor: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isDark ? Colors.blue.shade800 : Colors.blue.shade100),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final firstField = dynamicFields.isNotEmpty
                        ? dynamicFields.first
                        : const DynamicFieldEntity(
                            id: 'area',
                            type: DynamicFieldType.number,
                            label: {'ar': 'المساحة'},
                          );
                    final isBoolOrDropdown = firstField.type == DynamicFieldType.toggle || firstField.type == DynamicFieldType.dropdown;
                    node.conditions.add(AstNode(
                      type: 'AND',
                      conditions: [
                        AstNode(
                          type: 'LEAF',
                          field: firstField.id,
                          operator: isBoolOrDropdown ? '=' : '>',
                          value: firstField.type == DynamicFieldType.toggle
                              ? 'true'
                              : (firstField.type == DynamicFieldType.dropdown
                                  ? (firstField.options?.isNotEmpty == true ? firstField.options!.first.id : '')
                                  : '100'),
                        )
                      ],
                    ));
                    onChanged();
                  },
                  icon: const Icon(Icons.playlist_add_rounded, size: 16),
                  label: const Text(
                    'إضافة مجموعة شروط',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.purple.shade900.withValues(alpha: 0.25) : Colors.purple.shade50,
                    foregroundColor: isDark ? Colors.purple.shade200 : Colors.purple.shade900,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isDark ? Colors.purple.shade800 : Colors.purple.shade100),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // LEAF condition widget
      final selectedField = dynamicFields.firstWhere(
        (f) => f.id == node.field,
        orElse: () => const DynamicFieldEntity(
          id: 'area',
          type: DynamicFieldType.number,
          label: {'ar': 'المساحة'},
        ),
      );

      final isToggle = selectedField.type == DynamicFieldType.toggle;
      final isDropdown = selectedField.type == DynamicFieldType.dropdown || selectedField.type == DynamicFieldType.optionsGroup;

      final allowedOps = (isToggle || isDropdown) ? ['=', '!='] : ['=', '>', '<', '>=', '<='];
      final initialOp = allowedOps.contains(node.operator) ? node.operator : '=';

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeColor.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('${node.field}_field_dropdown'),
                  initialValue: dynamicFields.any((f) => f.id == node.field) ? node.field : dynamicFields.first.id,
                  isExpanded: true,
                  dropdownColor: themeColor.cardBackground,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: themeColor.textPrimary),
                  decoration: _buildMiniInputDecoration(themeColor),
                  items: dynamicFields.map((field) {
                    final label = field.label['ar'] ?? field.label['en'] ?? field.id;
                    return DropdownMenuItem(
                      value: field.id,
                      child: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      node.field = val;
                      final selected = dynamicFields.firstWhere(
                        (f) => f.id == val,
                        orElse: () => const DynamicFieldEntity(
                          id: 'area',
                          type: DynamicFieldType.number,
                          label: {'ar': 'المساحة'},
                        ),
                      );
                      if (selected.type == DynamicFieldType.toggle) {
                        node.operator = '=';
                        node.value = 'true';
                      } else if (selected.type == DynamicFieldType.dropdown || selected.type == DynamicFieldType.optionsGroup) {
                        node.operator = '=';
                        final firstOpt = selected.options?.isNotEmpty == true
                            ? selected.options!.first.id
                            : '';
                        node.value = firstOpt;
                      } else {
                        node.operator = '=';
                        node.value = '';
                      }
                      onChanged();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('${node.field}_operator'),
                  initialValue: initialOp,
                  isExpanded: true,
                  dropdownColor: themeColor.cardBackground,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: themeColor.textPrimary),
                  decoration: _buildMiniInputDecoration(themeColor),
                  items: allowedOps.map((op) {
                    return DropdownMenuItem(value: op, child: Text(op, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      node.operator = val;
                      onChanged();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: isToggle
                  ? DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('${node.field}_toggle_val'),
                        initialValue: node.value == 'true' || node.value == 'false' ? node.value : 'true',
                        isExpanded: true,
                        dropdownColor: themeColor.cardBackground,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: themeColor.textPrimary),
                        decoration: _buildMiniInputDecoration(themeColor),
                        items: const [
                          DropdownMenuItem(
                            value: 'true',
                            child: Text('نعم (true)', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: 'false',
                            child: Text('لا (false)', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            node.value = val;
                            onChanged();
                          }
                        },
                      ),
                    )
                  : isDropdown
                      ? DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('${node.field}_dropdown_val'),
                            initialValue: (selectedField.options ?? []).any((opt) => opt.id == node.value)
                                ? node.value
                                : ((selectedField.options ?? []).isNotEmpty ? (selectedField.options ?? []).first.id : ''),
                            isExpanded: true,
                            dropdownColor: themeColor.cardBackground,
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: themeColor.textPrimary),
                            decoration: _buildMiniInputDecoration(themeColor),
                            items: (selectedField.options ?? []).map((opt) {
                              final optLabel = opt.label['ar'] ?? opt.label['en'] ?? opt.id;
                              return DropdownMenuItem(
                                value: opt.id,
                                child: Text(optLabel, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                node.value = val;
                                onChanged();
                              }
                            },
                          ),
                        )
                      : TextFormField(
                          key: ValueKey('${node.field}_text_val'),
                          initialValue: node.value,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: themeColor.textPrimary),
                          decoration: _buildMiniInputDecoration(themeColor, hintText: 'القيمة'),
                          onChanged: (val) {
                            node.value = val;
                          },
                        ),
            ),
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                onPressed: onRemove,
              ),
          ],
        ),
      );
    }
  }
}
