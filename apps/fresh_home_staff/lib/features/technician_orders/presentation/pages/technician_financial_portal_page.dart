import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class TechnicianFinancialPortalPage extends StatelessWidget {
  const TechnicianFinancialPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    // Hardcoded analytics for visual preview in production quality
    const double walletBalance = 1240.00;
    const double weeklyEarnings = 450.00;
    const double monthlyEarnings = 1890.00;
    const int completedJobsCount = 14;
    const double bonusEarnings = 120.00;

    // Daily breakdown for this week: Sat to Fri
    final List<Map<String, dynamic>> dailyStats = [
      {'day': 'السبت', 'amount': 150.0, 'completed': 2},
      {'day': 'الأحد', 'amount': 0.0, 'completed': 0},
      {'day': 'الاثنين', 'amount': 200.0, 'completed': 3},
      {'day': 'الثلاثاء', 'amount': 100.0, 'completed': 1},
      {'day': 'الأربعاء', 'amount': 0.0, 'completed': 0},
      {'day': 'الخميس', 'amount': 0.0, 'completed': 0},
      {'day': 'الجمعة', 'amount': 0.0, 'completed': 0},
    ];

    // Mock history of completed jobs with commission data
    final List<Map<String, dynamic>> jobHistory = [
      {
        'id': 'booking-991',
        'serviceName': 'تنظيف المكيفات',
        'date': '2026-05-27',
        'customerPaid': 350.0,
        'commission': 50.0,
        'techPayout': 300.0,
        'bonus': 30.0,
        'discountAbsorbed': 50.0,
        'isWeekend': true,
      },
      {
        'id': 'booking-982',
        'serviceName': 'تنظيف عميق للمطبخ',
        'date': '2026-05-25',
        'customerPaid': 200.0,
        'commission': 30.0,
        'techPayout': 170.0,
        'bonus': 0.0,
        'discountAbsorbed': 0.0,
        'isWeekend': false,
      },
      {
        'id': 'booking-973',
        'serviceName': 'غسيل سجاد صالون',
        'date': '2026-05-24',
        'customerPaid': 150.0,
        'commission': 20.0,
        'techPayout': 130.0,
        'bonus': 10.0,
        'discountAbsorbed': 20.0,
        'isWeekend': false,
      }
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text(
          'محفظة الأرباح والشفافية المالية',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Current Wallet Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeColor.primary,
                    themeColor.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.primary.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'رصيد المحفظة المتاح للسحب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${walletBalance.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSummaryStat(
                        title: 'الأسبوع الحالي',
                        val: '${weeklyEarnings.toStringAsFixed(0)} ج.م',
                      ),
                      Container(width: 1, height: 24, color: Colors.white24),
                      _buildSummaryStat(
                        title: 'الشهر الحالي',
                        val: '${monthlyEarnings.toStringAsFixed(0)} ج.م',
                      ),
                      Container(width: 1, height: 24, color: Colors.white24),
                      _buildSummaryStat(
                        title: 'إجمالي الحوافز',
                        val: '${bonusEarnings.toStringAsFixed(0)} ج.م',
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Performance graph placeholder (visual chart bars)
            const Text(
              'أداء الأسبوع الحالي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: dailyStats.map((stat) {
                        final double amt = stat['amount'] as double;
                        final double heightPct = (amt / 250.0).clamp(0.05, 1.0);
                        return Column(
                          children: [
                            Text(
                              amt.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 9,
                                color: amt > 0 ? themeColor.primary : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 16,
                              height: 80 * heightPct,
                              decoration: BoxDecoration(
                                color: amt > 0
                                    ? themeColor.primary
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              stat['day'] as String,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'إجمالي الأعمال المكتملة:',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '$completedJobsCount خدمة',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Active bonuses
            const Text(
              'الحوافز النشطة والدعم المالي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const BonusHighlightCard(
              title: 'حافز نهاية الأسبوع (الجمعة والسبت)',
              description: 'احصل على +30 ج.م إضافية لكل حجز مكتمل خلال عطلة نهاية الأسبوع لزيادة التغطية.',
              bonusAmount: 30.0,
            ),
            const SizedBox(height: 24),

            // Completed ledger breakdown
            const Text(
              'سجل الأعمال والشفافية المالية للطلبات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            ...jobHistory.map((job) {
              final double payout = job['techPayout'] as double;
              final double bonus = job['bonus'] as double;
              final double customerPaid = job['customerPaid'] as double;
              final double commission = job['commission'] as double;
              final double discountAbsorbed = job['discountAbsorbed'] as double;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                elevation: 0,
                child: ExpansionTile(
                  title: Text(
                    job['serviceName'] as String,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'تاريخ الخدمة: ${job['date']}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  trailing: Text(
                    '+ ${(payout + bonus).toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          CustomerPaidSummary(
                            basePrice: customerPaid - discountAbsorbed,
                            extraFees: 0.0,
                            customerDiscount: discountAbsorbed,
                            customerPaid: customerPaid,
                          ),
                          const SizedBox(height: 8),
                          CommissionBreakdownCard(
                            customerPaid: customerPaid,
                            technicianEarnings: payout,
                            platformCommission: commission,
                          ),
                          if (bonus > 0) ...[
                            const SizedBox(height: 8),
                            BonusHighlightCard(
                              title: 'مكافأة إضافية مطبقة',
                              description: 'تمت إضافة الحافز المستحق لهذا الطلب لجهودك الاستثنائية.',
                              bonusAmount: bonus,
                            ),
                          ],
                        ],
                      ),
                    )
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat({required String title, required String val}) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
