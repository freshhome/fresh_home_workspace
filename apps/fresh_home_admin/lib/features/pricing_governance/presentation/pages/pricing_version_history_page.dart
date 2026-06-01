import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/use_cases/replay_booking_pricing_usecase.dart';

class PricingVersionHistoryPage extends StatefulWidget {
  final Map<String, dynamic> auditLog;

  const PricingVersionHistoryPage({super.key, required this.auditLog});

  @override
  State<PricingVersionHistoryPage> createState() => _PricingVersionHistoryPageState();
}

class _PricingVersionHistoryPageState extends State<PricingVersionHistoryPage> {
  bool _isReplaying = false;
  Map<String, dynamic>? _replayResult;
  String? _replayError;

  Future<void> _runAuditedReplay() async {
    setState(() {
      _isReplaying = true;
      _replayResult = null;
      _replayError = null;
    });

    try {
      final testBookingId = widget.auditLog['id'] ?? 'd290f1ee-6c54-4b01-90e6-d701748f0851';
      final result = await getIt<ReplayBookingPricingUseCase>().call(testBookingId);

      setState(() {
        _replayResult = result;
        _isReplaying = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [PricingVersionHistoryPage Error]: $e\n$stackTrace');
      setState(() {
        _replayError = e.toString();
        _isReplaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;

    final oldState = widget.auditLog['before_state'] ?? {};
    final newState = widget.auditLog['after_state'] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('تفاصيل التدقيق المالي وإعادة المحاكاة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Audit Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [themeColor.primary, themeColor.primary.withValues(alpha: 0.85)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'نوع العملية: ${widget.auditLog['action'] ?? 'تعديل سياق الأسعار'}',
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'معرف التغيير: ${widget.auditLog['id']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                  ),
                  Text(
                    'تاريخ التسجيل: ${DateTime.parse(widget.auditLog['created_at']).toLocal().toString().substring(0, 19)}',
                    style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Side-by-Side State diff representation
            const Text('مقارنة حالة البيانات (قبل وبعد التغيير)', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            PricingDiffViewer(beforeState: oldState, afterState: newState),
            const SizedBox(height: 20),

            // Time Travel sandbox replay block
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أداة إعادة المحاكاة والتدقيق الفوري (Time-Travel Audit Replay)',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'تتيح لك هذه الميزة الحصرية إعادة تشغيل خط الأنابيب بأكمله لحجز معين باستخدام إعدادات الأسعار المؤرشفة المقفلة عند تنفيذه الأصلي.',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isReplaying ? null : _runAuditedReplay,
                      icon: _isReplaying
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.replay_circle_filled_rounded),
                      label: const Text('تشغيل إعادة الحساب والتدقيق السحابي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade50,
                        foregroundColor: Colors.purple.shade900,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    if (_replayError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_replayError!, style: const TextStyle(fontFamily: 'monospace', color: Colors.red, fontSize: 11)),
                      )
                    ] else if (_replayResult != null) ...[
                      const SizedBox(height: 16),
                      const Text('نتائج التدقيق وإعادة المحاكاة السحابية:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('السعر الأصلي المسجل: ${_replayResult!['original_snapshot']?['total'] ?? 0} ج.م', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            Text('السعر المعاد حسابه بالخادم: ${_replayResult!['replayed_snapshot']?['total'] ?? 0} ج.م', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                            const Divider(),
                            Text(
                              'ملاحظات التدقيق: ${_replayResult!['is_match'] == true ? 'متطابق بنسبة 100%' : 'يوجد اختلاف مالي!'}',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: _replayResult!['is_match'] == true ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ── PricingDiffViewer Component ──────────────────────────────────────────────

class PricingDiffViewer extends StatelessWidget {
  final Map<String, dynamic> beforeState;
  final Map<String, dynamic> afterState;

  const PricingDiffViewer({
    super.key,
    required this.beforeState,
    required this.afterState,
  });

  @override
  Widget build(BuildContext context) {
    // Exclude noisy system columns
    final excludeKeys = {'id', 'sub_service_id', 'created_at', 'updated_at', 'rule_id', 'discount_id', 'actor_id'};

    final allKeys = <String>{...beforeState.keys, ...afterState.keys}
        .where((k) => !excludeKeys.contains(k))
        .toList()
      ..sort();

    final List<Widget> changedWidgets = [];
    final List<Widget> unchangedWidgets = [];

    for (final key in allKeys) {
      final hasBefore = beforeState.containsKey(key);
      final hasAfter = afterState.containsKey(key);
      final valBefore = beforeState[key];
      final valAfter = afterState[key];

      if (hasBefore && hasAfter && valBefore.toString() == valAfter.toString()) {
        // Unchanged key
        unchangedWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    _translateKey(key),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Text(
                    _formatValue(valAfter),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (!hasBefore && hasAfter) {
        // Added key
        changedWidgets.add(
          _buildDiffCard(
            context,
            title: 'إضافة حقل: ${_translateKey(key)}',
            badgeText: 'مضاف (+)',
            badgeColor: Colors.green,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatValue(valAfter),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.green),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade50.withValues(alpha: 0.05),
            borderColor: Colors.green.shade200,
          ),
        );
      } else if (hasBefore && !hasAfter) {
        // Deleted key
        changedWidgets.add(
          _buildDiffCard(
            context,
            title: 'حذف حقل: ${_translateKey(key)}',
            badgeText: 'محذوف (-)',
            badgeColor: Colors.red,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatValue(valBefore),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.red.shade800,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade50.withValues(alpha: 0.05),
            borderColor: Colors.red.shade200,
          ),
        );
      } else {
        // Modified key
        changedWidgets.add(
          _buildDiffCard(
            context,
            title: 'تعديل حقل: ${_translateKey(key)}',
            badgeText: 'معدل (~)',
            badgeColor: Colors.orange,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('القيمة السابقة:', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.black54)),
                Text(
                  _formatValue(valBefore),
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.red.shade800),
                ),
                const SizedBox(height: 8),
                const Text('القيمة الجديدة:', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.black54)),
                Text(
                  _formatValue(valAfter),
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.green.shade800),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade50.withValues(alpha: 0.05),
            borderColor: Colors.orange.shade200,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (changedWidgets.isNotEmpty) ...[
          const Text('التعديلات والتحسينات المكتشفة:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple)),
          const SizedBox(height: 8),
          ...changedWidgets,
        ],
        const SizedBox(height: 16),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: const Text(
              'استعراض القيم غير المعدلة (Unchanged Keys)',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: unchangedWidgets,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiffCard(
    BuildContext context, {
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Widget body,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 0.5),
          body,
        ],
      ),
    );
  }

  String _translateKey(String key) {
    switch (key) {
      case 'name':
        return 'الاسم / الوصف';
      case 'code':
        return 'كود الكوبون';
      case 'type':
        return 'نوع القاعدة / العرض';
      case 'value_type':
        return 'نوع القيمة (نسبة/ثابت)';
      case 'value':
        return 'القيمة المالية';
      case 'action_type':
        return 'نوع الإجراء الرياضي';
      case 'action_value':
        return 'قيمة الإجراء الرياضي';
      case 'action_target':
        return 'الهدف المالي المتأثر';
      case 'priority':
        return 'أولوية التنفيذ';
      case 'is_active':
        return 'حالة التفعيل';
      case 'condition_ast':
        return 'شجرة شروط القاعدة (AST)';
      case 'conditions_ast':
        return 'شجرة شروط الكوبون (AST)';
      case 'stackable':
        return 'قابل للتراكم والتداخل';
      default:
        return key;
    }
  }

  String _formatValue(dynamic val) {
    if (val == null) return 'null';
    if (val is Map || val is List) {
      try {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(val);
      } catch (_) {
        return val.toString();
      }
    }
    return val.toString();
  }
}
