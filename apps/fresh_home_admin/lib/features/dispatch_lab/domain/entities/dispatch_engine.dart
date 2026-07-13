import 'dispatch_decision.dart';
import 'dispatch_rules.dart';
import 'virtual_booking.dart';
import 'virtual_technician.dart';

class DispatchEngine {
  final List<FilterRule> filterRules;
  final List<RankingRule> rankingRules;
  final TieBreakerRule tieBreaker;

  DispatchEngine({
    required this.filterRules,
    required this.rankingRules,
    required this.tieBreaker,
  });

  DispatchDecision dispatch({
    required VirtualBooking booking,
    required List<VirtualTechnician> technicians,
  }) {
    final List<TechnicianDecisionDetails> detailsList = [];
    final List<VirtualTechnician> eligibleTechnicians = [];
    final Map<String, String> exclusionReasons = {};

    // 1. Filtering Phase
    final activeTechnicians = technicians.where((t) => t.isActive).toList();

    for (final tech in technicians) {
      String? exclusionReason;
      for (final rule in filterRules) {
        final String? err;
        if (rule is ExcludeExceedingFiftyPercentRule) {
          err = rule.evaluateWithContext(tech, booking, activeTechnicians);
        } else {
          err = rule.evaluate(tech, booking);
        }
        if (err != null) {
          exclusionReason = err;
          break; 
        }
      }

      if (exclusionReason != null) {
        exclusionReasons[tech.id] = exclusionReason;
      } else {
        eligibleTechnicians.add(tech);
      }
    }

    // If no technician is eligible, return immediately
    if (eligibleTechnicians.isEmpty) {
      for (final tech in technicians) {
        final exclReason = exclusionReasons[tech.id] ?? 'مستبعد';
        
        final Map<String, dynamic> metrics = {};
        for (final rule in rankingRules) {
          metrics[rule.id] = rule.getMetricString(tech);
        }

        detailsList.add(TechnicianDecisionDetails(
          technicianId: tech.id,
          name: tech.name,
          rating: tech.rating,
          dailyCapacity: tech.dailyCapacity,
          currentOrders: tech.currentOrders,
          utilization: tech.utilization,
          lastAssignedOrderIndex: tech.lastAssignedOrderIndex,
          isExcluded: true,
          exclusionReason: exclReason,
          metrics: metrics,
          finalRank: 0,
          rankReason: 'مستبعد في مرحلة التصفية: $exclReason',
        ));
      }

      return DispatchDecision(
        booking: booking,
        selectedTechnician: null,
        reason: 'تعذر التوزيع: لم يجتز أي فني قواعد التصفية النشطة.',
        technicianDetails: detailsList,
        timestamp: DateTime.now(),
      );
    }

    // 2. Ranking Phase
    final List<VirtualTechnician> sortedEligible = List.from(eligibleTechnicians);
    
    // Calculate total capacity of all active technicians and set it on the RelativeCapacityRankingRule
    final double totalCap = technicians.where((t) => t.isActive).fold(0.0, (sum, t) => sum + t.dailyCapacity);
    for (final rule in rankingRules) {
      if (rule is RelativeCapacityRankingRule) {
        rule.totalDailyCapacity = totalCap;
      }
    }

    sortedEligible.sort((a, b) {
      for (final rule in rankingRules) {
        final comp = rule.compare(a, b, booking);
        if (comp != 0) {
          return comp; 
        }
      }
      return 0; 
    });

    // Check for ties at the top of the sorted list
    final List<VirtualTechnician> tiedAtTop = [];
    if (sortedEligible.isNotEmpty) {
      final topTech = sortedEligible.first;
      tiedAtTop.add(topTech);
      for (int i = 1; i < sortedEligible.length; i++) {
        final nextTech = sortedEligible[i];
        bool isTied = true;
        for (final rule in rankingRules) {
          if (rule.compare(topTech, nextTech, booking) != 0) {
            isTied = false;
            break;
          }
        }
        if (isTied) {
          tiedAtTop.add(nextTech);
        } else {
          break; 
        }
      }
    }

    // 3. Tie Breaking Phase
    final VirtualTechnician winner;
    bool tieWasBroken = false;
    
    if (tiedAtTop.length > 1) {
      winner = tieBreaker.select(tiedAtTop, booking);
      tieWasBroken = true;
    } else {
      winner = sortedEligible.first;
    }

    // Reorder lists to put the winner at rank 1
    final List<VirtualTechnician> finalSortedList = [];
    finalSortedList.add(winner);
    for (final tech in sortedEligible) {
      if (tech.id != winner.id) {
        finalSortedList.add(tech);
      }
    }

    // Compile evaluation details for every technician
    for (final tech in technicians) {
      final isExcluded = exclusionReasons.containsKey(tech.id);
      
      final Map<String, dynamic> metrics = {};
      for (final rule in rankingRules) {
        metrics[rule.id] = rule.getMetricString(tech);
      }

      if (isExcluded) {
        final exclReason = exclusionReasons[tech.id]!;
        detailsList.add(TechnicianDecisionDetails(
          technicianId: tech.id,
          name: tech.name,
          rating: tech.rating,
          dailyCapacity: tech.dailyCapacity,
          currentOrders: tech.currentOrders,
          utilization: tech.utilization,
          lastAssignedOrderIndex: tech.lastAssignedOrderIndex,
          isExcluded: true,
          exclusionReason: exclReason,
          metrics: metrics,
          finalRank: 0,
          rankReason: 'مستبعد في مرحلة التصفية: $exclReason',
        ));
      } else {
        final rank = finalSortedList.indexWhere((e) => e.id == tech.id) + 1;
        String rankExplanation = '';
        
        if (tech.id == winner.id) {
          if (tieWasBroken) {
            rankExplanation = 'الفائز بالطلب (المركز الأول). تساوى مع الآخرين في الترتيب وتم اختياره بقاعدة كسر التعادل: (${tieBreaker.name}).';
          } else {
            final List<String> reasons = [];
            for (final rule in rankingRules) {
              if (finalSortedList.length > 1) {
                final runnerUp = finalSortedList[1];
                final comp = rule.compare(tech, runnerUp, booking);
                if (comp < 0) {
                  reasons.add('تفوّق بقاعدة (${rule.name}: ${rule.getMetricString(tech)} مقابل ${rule.getMetricString(runnerUp)})');
                  break; 
                } else {
                  reasons.add('تساوى بقاعدة (${rule.name}: ${rule.getMetricString(tech)})');
                }
              } else {
                reasons.add('هو الفني الوحيد المؤهل للطلب');
              }
            }
            rankExplanation = 'الفائز بالطلب (المركز الأول). ${reasons.join(' ← ')}.';
          }
        } else {
          final List<String> compareSteps = [];
          for (final rule in rankingRules) {
            final comp = rule.compare(winner, tech, booking);
            if (comp < 0) {
              compareSteps.add('أقل بقاعدة (${rule.name}: ${rule.getMetricString(tech)} مقابل ${rule.getMetricString(winner)} للفائز)');
              break; 
            } else {
              compareSteps.add('تساوى بقاعدة (${rule.name}: ${rule.getMetricString(tech)})');
            }
          }
          rankExplanation = 'الترتيب #$rank. ${compareSteps.join(' ← ')}.';
        }

        detailsList.add(TechnicianDecisionDetails(
          technicianId: tech.id,
          name: tech.name,
          rating: tech.rating,
          dailyCapacity: tech.dailyCapacity,
          currentOrders: tech.currentOrders,
          utilization: tech.utilization,
          lastAssignedOrderIndex: tech.lastAssignedOrderIndex,
          isExcluded: false,
          metrics: metrics,
          finalRank: rank,
          rankReason: rankExplanation,
        ));
      }
    }

    final List<String> explanationSteps = [];

    // 1. التصفية والاستبعاد
    explanationSteps.add(
      'اجتاز مرحلة التصفية (عنصر نشط ومتاح، وغير مكتمل السعة الكلية، ولم يتجاوز 50% من سعته قبل الجميع)'
    );

    // 2. التوزيع المتناسب المتداخل
    final hasProportionalRule = rankingRules.any((r) => r.id == 'proportional_share');
    if (hasProportionalRule) {
      final winnerUtil = (winner.currentOrders + 1) / winner.dailyCapacity;
      if (finalSortedList.length > 1) {
        final runnerUp = finalSortedList[1];
        final runnerUpUtil = (runnerUp.currentOrders + 1) / runnerUp.dailyCapacity;
        
        if (winnerUtil < runnerUpUtil) {
          explanationSteps.add(
            'التوزيع المتداخل: نسبة إشغاله المتوقعة بعد قبول هذا الطلب هي (${(winnerUtil * 100).toStringAsFixed(1)}%) وهي الأقل مقارنة بالمركز الثاني (${runnerUp.name}: ${(runnerUpUtil * 100).toStringAsFixed(1)}%)'
          );
        } else {
          explanationSteps.add(
            'التوزيع المتداخل: نسبة إشغاله المتوقعة بعد قبول هذا الطلب هي (${(winnerUtil * 100).toStringAsFixed(1)}%) وهي متساوية مع فنيين آخرين، وتفوّق لكون سعته الكلية أكبر (${winner.dailyCapacity} مقابل ${runnerUp.dailyCapacity})'
          );
        }
      } else {
        explanationSteps.add(
          'التوزيع المتداخل: نسبة إشغاله المتوقعة بعد قبول هذا الطلب هي (${(winnerUtil * 100).toStringAsFixed(1)}%) وهو الفني المؤهل الوحيد'
        );
      }
    }

    // 3. التقييم
    final hasRatingRule = rankingRules.any((r) => r.id == 'rating');
    if (hasRatingRule) {
      if (finalSortedList.length > 1) {
        final runnerUp = finalSortedList[1];
        if (winner.rating > runnerUp.rating) {
          explanationSteps.add(
            'التقييم: تقييمه هو (${winner.rating}) وهو الأعلى مقارنة بالمركز الثاني (${runnerUp.name}: ${runnerUp.rating})'
          );
        } else {
          explanationSteps.add(
            'التقييم: تقييمه هو (${winner.rating}) ومتساوٍ مع فنيين آخرين'
          );
        }
      } else {
        explanationSteps.add(
          'التقييم: تقييمه هو (${winner.rating})'
        );
      }
    }

    // 4. الانتظار (FIFO)
    final hasFifoRule = rankingRules.any((r) => r.id == 'idle_time');
    if (hasFifoRule) {
      if (finalSortedList.length > 1) {
        final runnerUp = finalSortedList[1];
        if (winner.lastAssignedOrderIndex == null) {
          explanationSteps.add(
            'الانتظار: لم يتم إسناد أي طلب له اليوم وهو الأكثر انتظاراً'
          );
        } else if (runnerUp.lastAssignedOrderIndex == null) {
          explanationSteps.add(
            'الانتظار: الفني المنافس لم يستلم طلبات بعد وتفوّق الفائز بالمعايير السابقة'
          );
        } else if (winner.lastAssignedOrderIndex! < runnerUp.lastAssignedOrderIndex!) {
          explanationSteps.add(
            'الانتظار: آخر طلب أُسند إليه كان الحجز رقم (${winner.lastAssignedOrderIndex}) وهو أقدم من المركز الثاني (${runnerUp.name}: الحجز رقم ${runnerUp.lastAssignedOrderIndex}) فهو الأطول انتظاراً'
          );
        } else {
          explanationSteps.add(
            'الانتظار: فترة انتظاره متساوية مع الآخرين'
          );
        }
      } else {
        explanationSteps.add(
          'الانتظار: هو الفني الوحيد'
        );
      }
    }

    // 5. كسر التعادل العشوائي
    if (tieWasBroken) {
      explanationSteps.add(
        'كسر التعادل: تم اختياره عشوائياً بقاعدة (${tieBreaker.name}) من بين الفنيين المتساوين تماماً في كل شيء: ${tiedAtTop.map((e) => e.name).join(', ')}'
      );
    }

    final overallReason = 'تم اختيار الفني (${winner.name}) بالتفصيل التدريجي التالي:\n- ${explanationSteps.join('\n- ')}.';

    // Sort details so the winner is first, followed by remaining ranks, then excluded ones.
    detailsList.sort((a, b) {
      if (a.isExcluded && b.isExcluded) return 0;
      if (a.isExcluded) return 1;
      if (b.isExcluded) return -1;
      return a.finalRank.compareTo(b.finalRank);
    });

    return DispatchDecision(
      booking: booking,
      selectedTechnician: winner,
      reason: overallReason,
      technicianDetails: detailsList,
      timestamp: DateTime.now(),
    );
  }
}
