import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class SimulationStageTimeline extends StatelessWidget {
  final List<dynamic> executionTrace;

  const SimulationStageTimeline({
    super.key,
    required this.executionTrace,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    // We expect the trace to have records showing stages like:
    // stage_1_base_pricing, stage_2_rules, stage_3_options, stage_4_discounts, stage_5_finalize.
    // Let's normalize/group the trace records for rendering.
    final Map<String, List<Map<String, dynamic>>> groupedTrace = {};
    for (var entry in executionTrace) {
      final map = Map<String, dynamic>.from(entry as Map);
      final stage = map['stage'] as String? ?? 'unknown';
      if (!groupedTrace.containsKey(stage)) {
        groupedTrace[stage] = [];
      }
      groupedTrace[stage]!.add(map);
    }

    final List<_TimelineStageData> stages = [
      _TimelineStageData(
        key: 'stage_1_base_pricing',
        title: 'المرحلة الأولى: التسعير الأساسي',
        subtitle: 'حساب السعر الأساسي بناءً على معطيات الحجز الكلاسيكية (المساحة أو المتر الطولي).',
        icon: Icons.filter_1_rounded,
      ),
      _TimelineStageData(
        key: 'stage_2_rules',
        title: 'المرحلة الثانية: القواعد الشرطية (AST)',
        subtitle: 'تطبيق محددات ومضاعفات الأسعار الديناميكية المشروطة في قواعد البيانات.',
        icon: Icons.filter_2_rounded,
      ),
      _TimelineStageData(
        key: 'stage_3_options',
        title: 'المرحلة الثالثة: الخيارات والملحقات الإضافية',
        subtitle: 'حساب الرسوم الإضافية المرتبطة بالخدمة والخيارات المفعلة.',
        icon: Icons.filter_3_rounded,
      ),
      _TimelineStageData(
        key: 'stage_4_apply_discounts',
        title: 'المرحلة الرابعة: الخصومات والعروض التسويقية',
        subtitle: 'تطبيق الكوبونات وحملات الخصومات التراكمية وسقف الخصم 30%.',
        icon: Icons.filter_4_rounded,
      ),
      _TimelineStageData(
        key: 'stage_5_finalize',
        title: 'المرحلة الخامسة: تدقيق وتثبيت المعاملة المالية',
        subtitle: 'الناتج النهائي وتوليد الرقم التعريفي لنسخة التسعير المؤرشفة.',
        icon: Icons.filter_5_rounded,
      ),
    ];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: themeColor.cardBorder,
      ),
      elevation: 0,
      color: themeColor.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline_rounded,
                  color: themeColor.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'تفاصيل خط أنابيب التسعير (Pricing Pipeline Trace)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, thickness: 0.5),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stages.length,
              itemBuilder: (context, index) {
                final stage = stages[index];
                final isLast = index == stages.length - 1;
                
                // Check if this stage was triggered in the trace
                // Note: SQL traces might use stage_2_apply_conditional_rules, stage_2_rules, etc.
                // Let's matching by prefixes or parts
                List<Map<String, dynamic>> records = [];
                for (var key in groupedTrace.keys) {
                  if (key.contains(stage.key.replaceAll('stage_', '').split('_').first)) {
                    records.addAll(groupedTrace[key]!);
                  }
                }
                if (stage.key == 'stage_4_apply_discounts' && records.isEmpty) {
                  records.addAll(groupedTrace['stage_4_discounts'] ?? []);
                }

                final isPassed = records.isNotEmpty;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Line & Icon
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isPassed
                                  ? themeColor.primary.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isPassed ? themeColor.primary : Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              stage.icon,
                              size: 14,
                              color: isPassed ? themeColor.primary : Colors.grey.shade500,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: isPassed ? themeColor.primary : Colors.grey.shade300,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stage.title,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isPassed
                                      ? themeColor.textPrimary
                                      : themeColor.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stage.subtitle,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: themeColor.secondaryText,
                                  height: 1.4,
                                ),
                              ),
                              if (isPassed && records.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: themeColor.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: records.map((rec) {
                                      final action = rec['action'] as String? ?? rec['message'] as String? ?? '';
                                      final before = rec['before'] ?? 0;
                                      final after = rec['after'] ?? rec['running_total'] ?? 0;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '• $action',
                                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                '${before.toString() == '0' || before.toString() == '0.0' || before == after ? '' : '${before.toString()} ➔ '}${after.toString()} ج.م',
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: themeColor.primary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStageData {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;

  _TimelineStageData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
