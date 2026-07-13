import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_home_admin/features/dispatch_lab/domain/entities/dispatch_engine.dart';
import 'package:fresh_home_admin/features/dispatch_lab/domain/entities/dispatch_rules.dart';
import 'package:fresh_home_admin/features/dispatch_lab/domain/entities/virtual_booking.dart';
import 'package:fresh_home_admin/features/dispatch_lab/domain/entities/virtual_technician.dart';

void main() {
  group('DispatchEngine Unit Tests', () {
    late VirtualBooking booking;

    setUp(() {
      booking = VirtualBooking(
        id: 'booking_1',
        sequenceNumber: 1,
        serviceName: 'تنظيف منازل',
        requiredCapacity: 1,
        createdAt: DateTime.now(),
      );
    });

    test('Should exclude inactive technicians', () {
      final t1 = VirtualTechnician(id: 't1', name: 'Tech 1', dailyCapacity: 5, currentOrders: 0, rating: 4.8, isActive: false);
      final t2 = VirtualTechnician(id: 't2', name: 'Tech 2', dailyCapacity: 5, currentOrders: 0, rating: 4.5, isActive: true);

      final engine = DispatchEngine(
        filterRules: [ExcludeInactiveRule()],
        rankingRules: [RatingRankingRule()],
        tieBreaker: FirstAvailableTieBreaker(),
      );

      final decision = engine.dispatch(booking: booking, technicians: [t1, t2]);

      expect(decision.selectedTechnician, isNotNull);
      expect(decision.selectedTechnician!.id, equals('t2'));
      
      final detailsT1 = decision.technicianDetails.firstWhere((d) => d.technicianId == 't1');
      expect(detailsT1.isExcluded, isTrue);
      expect(detailsT1.exclusionReason, equals('غير نشط حالياً'));
    });

    test('Should exclude technicians with no remaining capacity', () {
      final t1 = VirtualTechnician(id: 't1', name: 'Tech 1', dailyCapacity: 3, currentOrders: 3, rating: 4.8, isActive: true);
      final t2 = VirtualTechnician(id: 't2', name: 'Tech 2', dailyCapacity: 5, currentOrders: 0, rating: 4.5, isActive: true);

      final engine = DispatchEngine(
        filterRules: [ExcludeFullCapacityRule()],
        rankingRules: [RatingRankingRule()],
        tieBreaker: FirstAvailableTieBreaker(),
      );

      final decision = engine.dispatch(booking: booking, technicians: [t1, t2]);

      expect(decision.selectedTechnician, isNotNull);
      expect(decision.selectedTechnician!.id, equals('t2'));
      
      final detailsT1 = decision.technicianDetails.firstWhere((d) => d.technicianId == 't1');
      expect(detailsT1.isExcluded, isTrue);
      expect(detailsT1.exclusionReason, contains('السعة المتبقية غير كافية'));
    });

    test('Should prioritize higher rating when RatingRankingRule is primary', () {
      final t1 = VirtualTechnician(id: 't1', name: 'Tech 1', dailyCapacity: 5, currentOrders: 0, rating: 4.8, isActive: true);
      final t2 = VirtualTechnician(id: 't2', name: 'Tech 2', dailyCapacity: 5, currentOrders: 0, rating: 4.5, isActive: true);

      final engine = DispatchEngine(
        filterRules: [],
        rankingRules: [RatingRankingRule()],
        tieBreaker: FirstAvailableTieBreaker(),
      );

      final decision = engine.dispatch(booking: booking, technicians: [t1, t2]);

      expect(decision.selectedTechnician, isNotNull);
      expect(decision.selectedTechnician!.id, equals('t1'));
    });

    test('Should break ties using secondary rule (Utilization)', () {
      // Both have rating 4.8, but t2 has 0 utilization (preferred) while t1 has 1 order (20% utilization)
      final t1 = VirtualTechnician(id: 't1', name: 'Tech 1', dailyCapacity: 5, currentOrders: 1, rating: 4.8, isActive: true);
      final t2 = VirtualTechnician(id: 't2', name: 'Tech 2', dailyCapacity: 5, currentOrders: 0, rating: 4.8, isActive: true);

      final engine = DispatchEngine(
        filterRules: [],
        rankingRules: [RatingRankingRule(), UtilizationRankingRule()],
        tieBreaker: FirstAvailableTieBreaker(),
      );

      final decision = engine.dispatch(booking: booking, technicians: [t1, t2]);

      expect(decision.selectedTechnician, isNotNull);
      expect(decision.selectedTechnician!.id, equals('t2'));
    });

    test('Should break ties using tertiary rule (FIFO / IdleTime)', () {
      // Both have rating 4.8 and 0% utilization.
      // t1 was last assigned at booking #5.
      // t2 was last assigned at booking #2 (idle longer, i.e., preferred)
      final t1 = VirtualTechnician(id: 't1', name: 'Tech 1', dailyCapacity: 5, currentOrders: 0, rating: 4.8, isActive: true, lastAssignedOrderIndex: 5);
      final t2 = VirtualTechnician(id: 't2', name: 'Tech 2', dailyCapacity: 5, currentOrders: 0, rating: 4.8, isActive: true, lastAssignedOrderIndex: 2);

      final engine = DispatchEngine(
        filterRules: [],
        rankingRules: [RatingRankingRule(), UtilizationRankingRule(), IdleTimeRankingRule()],
        tieBreaker: FirstAvailableTieBreaker(),
      );

      final decision = engine.dispatch(booking: booking, technicians: [t1, t2]);

      expect(decision.selectedTechnician, isNotNull);
      expect(decision.selectedTechnician!.id, equals('t2'));
    });

    test('Should fallback to tie breaker when completely tied', () {
      final t1 = VirtualTechnician(id: 't1', name: 'Tech 1', dailyCapacity: 5, currentOrders: 0, rating: 4.8, isActive: true);
      final t2 = VirtualTechnician(id: 't2', name: 'Tech 2', dailyCapacity: 8, currentOrders: 0, rating: 4.8, isActive: true);

      final engine = DispatchEngine(
        filterRules: [],
        rankingRules: [RatingRankingRule(), UtilizationRankingRule()],
        tieBreaker: LeastTotalCapacityTieBreaker(), // should prefer t1 (capacity 5 < 8)
      );

      final decision = engine.dispatch(booking: booking, technicians: [t1, t2]);

      expect(decision.selectedTechnician, isNotNull);
      expect(decision.selectedTechnician!.id, equals('t1'));
    });

    test('Should prioritize higher relative capacity (RelativeCapacityRankingRule)', () {
      // Tech 1: capacity 10, remaining 9/16
      // Tech 2: capacity 5, remaining 5/16
      // Tech 3: capacity 1, remaining 1/16
      final t1 = VirtualTechnician(id: 't1', name: 'Tech 1', dailyCapacity: 10, currentOrders: 1, rating: 4.8, isActive: true);
      final t2 = VirtualTechnician(id: 't2', name: 'Tech 2', dailyCapacity: 5, currentOrders: 0, rating: 4.8, isActive: true);
      final t3 = VirtualTechnician(id: 't3', name: 'Tech 3', dailyCapacity: 1, currentOrders: 0, rating: 4.8, isActive: true);

      final engine = DispatchEngine(
        filterRules: [],
        rankingRules: [RelativeCapacityRankingRule()],
        tieBreaker: FirstAvailableTieBreaker(),
      );

      final decision = engine.dispatch(booking: booking, technicians: [t1, t2, t3]);

      expect(decision.selectedTechnician, isNotNull);
      expect(decision.selectedTechnician!.id, equals('t1')); // 9/16 is highest

      final detailsT1 = decision.technicianDetails.firstWhere((d) => d.technicianId == 't1');
      expect(detailsT1.metrics['rank_relative_capacity'], contains('9/16'));
    });

    test('Should enforce Fifty Percent Rule (ExcludeExceedingFiftyPercentRule)', () {
      // t1: capacity 10, current orders 5 (50% - at threshold)
      // t2: capacity 5, current orders 2 (40% - below threshold)
      // t3: capacity 1, current orders 0 (0% - below threshold)
      final t1 = VirtualTechnician(id: 't1', name: 'Tech 1', dailyCapacity: 10, currentOrders: 5, rating: 4.8, isActive: true);
      final t2 = VirtualTechnician(id: 't2', name: 'Tech 2', dailyCapacity: 5, currentOrders: 2, rating: 4.8, isActive: true);
      final t3 = VirtualTechnician(id: 't3', name: 'Tech 3', dailyCapacity: 1, currentOrders: 0, rating: 4.8, isActive: true);

      final engine = DispatchEngine(
        filterRules: [ExcludeExceedingFiftyPercentRule()],
        rankingRules: [RelativeCapacityRankingRule()],
        tieBreaker: FirstAvailableTieBreaker(),
      );

      final decision = engine.dispatch(booking: booking, technicians: [t1, t2, t3]);

      // t1 is at exactly 50%, so t1 must be excluded since t2 (40%) and t3 (0%) are below 50%.
      // t2 and t3 are < 50%, so they are eligible.
      // t2 wins because it has higher relative remaining capacity (3/16 vs 1/16).
      expect(decision.selectedTechnician, isNotNull);
      expect(decision.selectedTechnician!.id, equals('t2'));

      final detailsT1 = decision.technicianDetails.firstWhere((d) => d.technicianId == 't1');
      final detailsT2 = decision.technicianDetails.firstWhere((d) => d.technicianId == 't2');
      final detailsT3 = decision.technicianDetails.firstWhere((d) => d.technicianId == 't3');

      expect(detailsT1.isExcluded, isTrue);
      expect(detailsT2.isExcluded, isFalse);
      expect(detailsT3.isExcluded, isFalse);
    });

    test('Should simulate WRR proportional share interleaving (ProportionalShareRankingRule)', () {
      final t1 = VirtualTechnician(id: 't1', name: 'Tech 1', dailyCapacity: 10, currentOrders: 0, rating: 5.0, isActive: true);
      final t2 = VirtualTechnician(id: 't2', name: 'Tech 2', dailyCapacity: 5, currentOrders: 0, rating: 5.0, isActive: true);
      final t3 = VirtualTechnician(id: 't3', name: 'Tech 3', dailyCapacity: 1, currentOrders: 0, rating: 5.0, isActive: true);

      final engine = DispatchEngine(
        filterRules: [ExcludeExceedingFiftyPercentRule()],
        rankingRules: [ProportionalShareRankingRule()],
        tieBreaker: FirstAvailableTieBreaker(),
      );

      final List<VirtualTechnician> techs = [t1, t2, t3];
      final List<String> assignments = [];

      for (int i = 1; i <= 9; i++) {
        final b = VirtualBooking(
          id: 'b$i',
          serviceName: 'Service',
          requiredCapacity: 1,
          sequenceNumber: i,
          createdAt: DateTime.now(),
        );
        final dec = engine.dispatch(booking: b, technicians: techs);
        final winner = dec.selectedTechnician!;
        
        assignments.add(winner.id);
        
        final idx = techs.indexWhere((t) => t.id == winner.id);
        techs[idx] = techs[idx].copyWith(
          currentOrders: techs[idx].currentOrders + 1,
          lastAssignedOrderIndex: i,
        );
      }

      // Desired sequence: t1, t1, t2, t1, t1, t2, t1, t2, t3
      expect(assignments, equals(['t1', 't1', 't2', 't1', 't1', 't2', 't1', 't2', 't3']));
    });
  });
}
