import 'dart:math';
import 'virtual_booking.dart';
import 'virtual_technician.dart';

// ============================================================================
// 1. BASE RULE CLASSES
// ============================================================================

abstract class FilterRule {
  String get id;
  String get name;
  String get description;

  /// Returns null if the technician passes, or a String explanation if excluded.
  String? evaluate(VirtualTechnician technician, VirtualBooking booking);
}

abstract class RankingRule {
  String get id;
  String get name;
  String get description;

  /// Returns negative if t1 is preferred, positive if t2 is preferred, 0 if tied.
  int compare(VirtualTechnician t1, VirtualTechnician t2, VirtualBooking booking);

  /// Returns a human-readable string representation of the technician's metric.
  String getMetricString(VirtualTechnician technician);
}

abstract class TieBreakerRule {
  String get id;
  String get name;
  String get description;

  VirtualTechnician select(List<VirtualTechnician> tiedTechnicians, VirtualBooking booking);
}

// ============================================================================
// 2. CONCRETE FILTER RULES
// ============================================================================

class ExcludeInactiveRule extends FilterRule {
  @override
  String get id => 'exclude_inactive';
  @override
  String get name => 'استبعاد الفنيين غير النشطين';
  @override
  String get description => 'يستبعد أي فني حالته غير نشطة (Active = false)';

  @override
  String? evaluate(VirtualTechnician technician, VirtualBooking booking) {
    return technician.isActive ? null : 'غير نشط حالياً';
  }
}

class ExcludeFullCapacityRule extends FilterRule {
  @override
  String get id => 'exclude_full_capacity';
  @override
  String get name => 'استبعاد مكتملي السعة اليومية';
  @override
  String get description => 'يستبعد الفني إذا استنفد كامل سعة عمله لهذا اليوم';

  @override
  String? evaluate(VirtualTechnician technician, VirtualBooking booking) {
    if (technician.remainingCapacity < booking.requiredCapacity) {
      return 'السعة المتبقية غير كافية (${technician.remainingCapacity} < ${booking.requiredCapacity})';
    }
    return null;
  }
}

class ExcludeLowRatingRule extends FilterRule {
  final double minRating;

  ExcludeLowRatingRule({this.minRating = 3.0});

  @override
  String get id => 'exclude_low_rating';
  @override
  String get name => 'استبعاد ذوي التقييم المنخفض';
  @override
  String get description => 'يستبعد الفنيين الذين يقل تقييمهم عن $minRating نجوم';

  @override
  String? evaluate(VirtualTechnician technician, VirtualBooking booking) {
    return technician.rating >= minRating
        ? null
        : 'التقييم منخفض جداً (${technician.rating.toStringAsFixed(1)} < $minRating)';
  }
}

class ExcludeExceedingFiftyPercentRule extends FilterRule {
  @override
  String get id => 'exclude_exceeding_fifty';
  @override
  String get name => 'منع تجاوز 50% قبل الجميع';
  @override
  String get description => 'يمنع الفني من تجاوز 50% من سعته إلا إذا وصل جميع الفنيين النشطين الآخرين لـ 50% على الأقل';

  @override
  String? evaluate(VirtualTechnician technician, VirtualBooking booking) {
    return null; 
  }

  String? evaluateWithContext(VirtualTechnician technician, VirtualBooking booking, List<VirtualTechnician> activeTechnicians) {
    // If the technician's current utilization is strictly less than 50%, they are allowed to receive this order.
    // They are only restricted if they have already reached or exceeded 50% utilization.
    if (technician.utilization < 0.5) {
      return null;
    }

    final bool hasSomeoneBelowFifty = activeTechnicians.any((t) => t.id != technician.id && t.utilization < 0.5);
    if (hasSomeoneBelowFifty) {
      return 'الفني وصل أو تجاوز بالفعل حد 50% من السعة (${(technician.utilization * 100).toStringAsFixed(0)}%) بينما يوجد فنيين آخرين لم يصلوا لـ 50%';
    }

    return null;
  }
}

// ============================================================================
// 3. CONCRETE RANKING RULES
// ============================================================================

class UtilizationRankingRule extends RankingRule {
  @override
  String get id => 'rank_utilization';
  @override
  String get name => 'نسبة الإشغال الأقل';
  @override
  String get description => 'يفضل الفني الذي لديه نسبة إشغال أقل مقارنة بسعته';

  @override
  int compare(VirtualTechnician t1, VirtualTechnician t2, VirtualBooking booking) {
    return t1.utilization.compareTo(t2.utilization);
  }

  @override
  String getMetricString(VirtualTechnician technician) {
    return '${(technician.utilization * 100).toStringAsFixed(0)}% (${technician.currentOrders}/${technician.dailyCapacity})';
  }
}

class RatingRankingRule extends RankingRule {
  @override
  String get id => 'rank_rating';
  @override
  String get name => 'التقييم الأعلى';
  @override
  String get description => 'يفضل الفني صاحب التقييم الأعلى';

  @override
  int compare(VirtualTechnician t1, VirtualTechnician t2, VirtualBooking booking) {
    // Descending order for rating (higher is better)
    return t2.rating.compareTo(t1.rating);
  }

  @override
  String getMetricString(VirtualTechnician technician) {
    return '${technician.rating.toStringAsFixed(1)} نجوم';
  }
}

class IdleTimeRankingRule extends RankingRule {
  @override
  String get id => 'rank_idle_time';
  @override
  String get name => 'الانتظار الأطول (FIFO)';
  @override
  String get description => 'يفضل الفني الذي ينتظر منذ أطول فترة دون إسناد طلبات له';

  @override
  int compare(VirtualTechnician t1, VirtualTechnician t2, VirtualBooking booking) {
    // If t1 has never been assigned, it's waiting since beginning.
    if (t1.lastAssignedOrderIndex == null && t2.lastAssignedOrderIndex == null) {
      return 0;
    }
    if (t1.lastAssignedOrderIndex == null) return -1; // t1 preferred
    if (t2.lastAssignedOrderIndex == null) return 1;  // t2 preferred
    
    // Older index is preferred (smaller index means assigned earlier, i.e., idle longer)
    return t1.lastAssignedOrderIndex!.compareTo(t2.lastAssignedOrderIndex!);
  }

  @override
  String getMetricString(VirtualTechnician technician) {
    if (technician.lastAssignedOrderIndex == null) {
      return 'ينتظر منذ بداية اليوم';
    }
    return 'آخر تعيين في الحجز #${technician.lastAssignedOrderIndex}';
  }
}

class RemainingCapacityRankingRule extends RankingRule {
  @override
  String get id => 'rank_remaining_capacity';
  @override
  String get name => 'السعة المتبقية الأكثر';
  @override
  String get description => 'يفضل الفني الذي لديه عدد أكبر من الوحدات الشاغرة بسعته اليومية';

  @override
  int compare(VirtualTechnician t1, VirtualTechnician t2, VirtualBooking booking) {
    // Descending order for remaining capacity (higher is better)
    return t2.remainingCapacity.compareTo(t1.remainingCapacity);
  }

  @override
  String getMetricString(VirtualTechnician technician) {
    return '${technician.remainingCapacity} طلب متبقي';
  }
}

class RelativeCapacityRankingRule extends RankingRule {
  double totalDailyCapacity = 1.0;

  @override
  String get id => 'rank_relative_capacity';
  @override
  String get name => 'الحصة النسبية للسعة المتبقية';
  @override
  String get description => 'يفضل الفني الذي لديه حصة نسبية أعلى من السعة المتبقية إلى إجمالي سعة الفنيين النشطين (مثال: 9/16)';

  @override
  int compare(VirtualTechnician t1, VirtualTechnician t2, VirtualBooking booking) {
    return t2.remainingCapacity.compareTo(t1.remainingCapacity);
  }

  @override
  String getMetricString(VirtualTechnician technician) {
    final int total = totalDailyCapacity.toInt();
    final double percentage = total == 0 ? 0.0 : (technician.remainingCapacity / total) * 100;
    return '${technician.remainingCapacity}/$total (${percentage.toStringAsFixed(0)}%)';
  }
}

class ProportionalShareRankingRule extends RankingRule {
  @override
  String get id => 'rank_proportional_share';
  @override
  String get name => 'التوزيع المتناسب المتداخل';
  @override
  String get description => 'يفضل الفني الذي ستكون نسبة إشغاله هي الأقل بعد قبول هذا الطلب (يضمن التداخل العادل والتوزيع التدريجي)';

  @override
  int compare(VirtualTechnician t1, VirtualTechnician t2, VirtualBooking booking) {
    final double u1 = (t1.currentOrders + booking.requiredCapacity) / t1.dailyCapacity;
    final double u2 = (t2.currentOrders + booking.requiredCapacity) / t2.dailyCapacity;
    
    final int cmp = u1.compareTo(u2); // Ascending order (lower utilization preferred)
    if (cmp != 0) return cmp;

    // Tie-breaker: prefer larger capacity first to balance round distribution
    return t2.dailyCapacity.compareTo(t1.dailyCapacity);
  }

  @override
  String getMetricString(VirtualTechnician technician) {
    final double nextUtilization = (technician.currentOrders + 1) / technician.dailyCapacity * 100;
    return 'إشغال متوقع: ${nextUtilization.toStringAsFixed(0)}%';
  }
}

// ============================================================================
// 4. CONCRETE TIE BREAKER RULES
// ============================================================================

class RandomTieBreaker extends TieBreakerRule {
  final Random _random = Random();

  @override
  String get id => 'tie_random';
  @override
  String get name => 'حسم عشوائي';
  @override
  String get description => 'يختار أحد الفنيين المتساوين عشوائياً لكسر التعادل';

  @override
  VirtualTechnician select(List<VirtualTechnician> tiedTechnicians, VirtualBooking booking) {
    return tiedTechnicians[_random.nextInt(tiedTechnicians.length)];
  }
}

class FirstAvailableTieBreaker extends TieBreakerRule {
  @override
  String get id => 'tie_first_available';
  @override
  String get name => 'الفني الأول في القائمة';
  @override
  String get description => 'يختار أول فني متوفر في القائمة الافتراضية للفنيين';

  @override
  VirtualTechnician select(List<VirtualTechnician> tiedTechnicians, VirtualBooking booking) {
    return tiedTechnicians.first;
  }
}

class LeastTotalCapacityTieBreaker extends TieBreakerRule {
  @override
  String get id => 'tie_least_total_capacity';
  @override
  String get name => 'السعة الإجمالية الأقل';
  @override
  String get description => 'يفضل الفني الذي يمتلك أصغر سعة كلية (لسرعة شغل طاقته)';

  @override
  VirtualTechnician select(List<VirtualTechnician> tiedTechnicians, VirtualBooking booking) {
    if (tiedTechnicians.isEmpty) throw StateError('Empty technicians list');
    VirtualTechnician chosen = tiedTechnicians.first;
    for (int i = 1; i < tiedTechnicians.length; i++) {
      if (tiedTechnicians[i].dailyCapacity < chosen.dailyCapacity) {
        chosen = tiedTechnicians[i];
      }
    }
    return chosen;
  }
}
