import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fresh_home_admin/features/pricing_governance/domain/entities/pricing_version_entity.dart';
import '../cubit/pricing_governance_cubit.dart';
import '../cubit/pricing_governance_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/pricing_rule_entity.dart';
import '../../domain/entities/pricing_discount_entity.dart';
import 'visual_rule_builder_page.dart';
import 'discount_campaign_builder_page.dart';
import 'pricing_version_history_page.dart';
import 'pricing_simulation_sandbox_page.dart';

class PricingGovernanceDashboard extends StatefulWidget {
  final String subServiceId;

  const PricingGovernanceDashboard({super.key, required this.subServiceId});

  @override
  State<PricingGovernanceDashboard> createState() => _PricingGovernanceDashboardState();
}

class _PricingGovernanceDashboardState extends State<PricingGovernanceDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PricingGovernanceCubit _cubit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cubit = getIt<PricingGovernanceCubit>()..loadPricingGovernanceData(widget.subServiceId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9FB),
        appBar: AppBar(
          title: const Text(
            'لوحة حوكمة أسعار المؤسسات',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(icon: Icon(Icons.rule_folder_rounded), text: 'قواعد التسعير (AST)'),
              Tab(icon: Icon(Icons.local_offer_rounded), text: 'الخصومات والعروض'),
              Tab(icon: Icon(Icons.history_toggle_off_rounded), text: 'سجل التغييرات والنسخ'),
            ],
          ),
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocConsumer<PricingGovernanceCubit, PricingGovernanceState>(
            listener: (context, state) {
              if (state is PricingGovernanceFailure) {
                debugPrint('❌ [PricingGovernanceDashboard Error]: ${state.message}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red.shade900,
                    content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is PricingGovernanceLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is PricingGovernanceLoaded) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRulesTab(state.rules),
                    _buildDiscountsTab(state.discounts),
                    _buildAuditTab(state.versions, state.auditLogs),
                  ],
                );
              }

              return const Center(
                child: Text(
                  'حدث خطأ غير متوقع أثناء تحميل بيانات الحوكمة.',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Rules List ──────────────────────────────────────────────────────
  Widget _buildRulesTab(List<PricingRuleEntity> rules) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'sim',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => getIt<PricingGovernanceCubit>(),
                    child: PricingSimulationSandboxPage(subServiceId: widget.subServiceId),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.science_rounded),
            label: const Text('محاكي الأسعار (Sandbox)', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            backgroundColor: Colors.purple.shade100,
            foregroundColor: Colors.purple.shade900,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VisualRuleBuilderPage(subServiceId: widget.subServiceId),
                ),
              );
              if (result == true) {
                _cubit.loadPricingGovernanceData(widget.subServiceId);
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('قاعدة شرطية جديدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: rules.isEmpty
          ? _buildEmptyState(Icons.rule_rounded, 'لا توجد قواعد تسعير شرطية مضافة بعد لهذه الخدمة.\nاضغط على إضافة قاعدة لتبدأ في تصميم الهيكل الشرطي.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              rule.ruleName,
                              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Switch(
                              value: rule.isActive,
                              onChanged: (val) {
                                _cubit.toggleRule(rule.id, widget.subServiceId, val);
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              rule.actionType == 'multiply'
                                  ? 'معامل الضرب: x${rule.actionValue.toStringAsFixed(2)}'
                                  : 'رسوم إضافية ثابتة: +${rule.actionValue.toStringAsFixed(0)} ج.م',
                              style: const TextStyle(fontFamily: 'Cairo', color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Chip(
                              label: Text('الأولوية: ${rule.priority}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                              backgroundColor: Colors.grey.shade100,
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'شجرة الشروط (AST Cond):',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F0FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.shade100),
                          ),
                          child: _AstReadableRenderer(
                            astJson: Map<String, dynamic>.from(
                              (rule.conditionAst as Map? ?? const <String, dynamic>{}),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ── Tab 2: Discounts List ──────────────────────────────────────────────────
  Widget _buildDiscountsTab(List<PricingDiscountEntity> discounts) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiscountCampaignBuilderPage(subServiceId: widget.subServiceId),
            ),
          );
          if (result == true) {
            _cubit.loadPricingGovernanceData(widget.subServiceId);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('حملة خصم جديدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
      ),
      body: discounts.isEmpty
          ? _buildEmptyState(Icons.local_offer_rounded, 'لا توجد حملات ترويجية أو أكواد خصم متاحة حالياً.\nقم بإنشاء كود خصم جديد لتطبيقه على سلة المشتريات.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: discounts.length,
              itemBuilder: (context, index) {
                final discount = discounts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                            _DiscountValidityChip(discount: discount),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  discount.isStackable ? Icons.layers_rounded : Icons.looks_one_rounded,
                                  size: 14,
                                  color: discount.isStackable ? Colors.blue.shade700 : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  discount.isStackable ? 'قابل للتراكم' : 'غير متراكم',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: discount.isStackable ? Colors.blue.shade700 : Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.confirmation_num_outlined, size: 13, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'الاستخدام: ${discount.usageCount} / ${discount.usageLimit ?? '∞'}',
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (discount.startDate != null || discount.endDate != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.date_range_rounded, size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                'من ${discount.startDate?.toLocal().toString().substring(0, 10) ?? '—'} إلى ${discount.endDate?.toLocal().toString().substring(0, 10) ?? '—'}',
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade600),
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

  // ── Tab 3: Auditing Logs and snapshotted versions ────────────────────────
  Widget _buildAuditTab(List<PricingVersionEntity> versions, List<Map<String, dynamic>> auditLogs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التسلسل الزمني للنسخ المحفوظة (Pricing Versions)',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: versions.isEmpty
                ? const Center(child: Text('لا توجد نسخ مؤرشفة بعد للأسعار.', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: versions.length,
                    itemBuilder: (context, index) {
                      final ver = versions[index];
                      return Container(
                        width: 180,
                        margin: const EdgeInsets.only(left: 12, bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ver.isActive ? Colors.amber.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: ver.isActive ? Colors.amber : Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('نسخة سارية', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey)),
                                if (ver.isActive)
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ver.id.substring(0, 8),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ver.createdAt.toLocal().toString().substring(0, 16),
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: Colors.grey.shade600),
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
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: auditLogs.isEmpty
                ? const Center(child: Text('سجل المراجعة والتدقيق فارغ حالياً.', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)))
                : ListView.builder(
                    itemCount: auditLogs.length,
                    itemBuilder: (context, index) {
                      final log = auditLogs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Icon(
                            log['action'] == 'INSERT'
                                ? Icons.add_circle_outline_rounded
                                : Icons.published_with_changes_rounded,
                            color: Colors.blueAccent,
                          ),
                          title: Text(
                            log['action'] ?? 'تعديل سياق التسعير',
                            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            'التاريخ: ${DateTime.parse(log['created_at']).toLocal().toString().substring(0, 16)}',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PricingVersionHistoryPage(auditLog: log),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('عرض التفاصيل', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
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

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AST Human-Readable Renderer ───────────────────────────────────────────────
/// Recursively renders an AST JSON map as a tree of human-readable condition chips.
/// Leaf nodes are displayed as Arabic field labels with operator and value.
/// Logical groups (AND/OR) are shown as colored header badges with child indentation.
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
    final label = isAnd ? 'AND — جميع الشروط التالية' : 'OR — أيٌّ من الشروط التالية';

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
          Icon(Icons.arrow_right_rounded, size: 14, color: Colors.purple.shade400),
          const SizedBox(width: 4),
          Text(
            fieldLabel,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4A1A8E)),
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
                style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: Colors.purple.shade800),
              ),
            ),
          ),
          Text(
            valueDisplay,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
          ),
        ],
      ),
    );
  }
}

// ── Discount Validity Chip ─────────────────────────────────────────────────────
/// Displays a color-coded status badge for a discount campaign:
/// - 🟢 نشط   : current date is within start–end range (or no dates set)
/// - 🔴 منتهي : end date is in the past
/// - 🔵 قادم  : start date is in the future
class _DiscountValidityChip extends StatelessWidget {
  final dynamic discount; // PricingDiscountEntity

  const _DiscountValidityChip({required this.discount});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = discount.startDate as DateTime?;
    final end = discount.endDate as DateTime?;

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
            style: TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.bold, color: fgColor),
          ),
        ],
      ),
    );
  }
}

