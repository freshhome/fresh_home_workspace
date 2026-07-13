import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/dispatch_lab_scenario.dart';
import '../../domain/entities/dispatch_decision.dart';
import '../../domain/entities/dispatch_engine.dart';
import '../../domain/entities/dispatch_rules.dart';
import '../../domain/entities/virtual_booking.dart';
import '../../domain/entities/virtual_technician.dart';
import 'dispatch_lab_state.dart';

class DispatchLabCubit extends Cubit<DispatchLabState> {
  Timer? _continuousTimer;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  DispatchLabCubit() : super(DispatchLabState.initial()) {
    _initDefaultData();
  }

  void _initDefaultData() {
    // 1. Create Default Technicians
    final defaultTechs = [
      const VirtualTechnician(id: 'tech_1', name: 'أحمد سعيد', dailyCapacity: 8, currentOrders: 0, rating: 4.9, isActive: true),
      const VirtualTechnician(id: 'tech_2', name: 'محمد عبد الله', dailyCapacity: 5, currentOrders: 0, rating: 4.7, isActive: true),
      const VirtualTechnician(id: 'tech_3', name: 'علي حسن', dailyCapacity: 10, currentOrders: 0, rating: 4.5, isActive: true),
      const VirtualTechnician(id: 'tech_4', name: 'خالد عمر', dailyCapacity: 6, currentOrders: 0, rating: 4.8, isActive: true),
      const VirtualTechnician(id: 'tech_5', name: 'ياسر مصطفى', dailyCapacity: 4, currentOrders: 0, rating: 4.2, isActive: true),
    ];

    // 2. Create Default Scenarios
    final scenario1051 = _buildDefaultScenario(
      name: 'سيناريو 10-5-1',
      techCount: 10,
      capacity: 5,
      ratings: [4.9, 4.8, 4.7, 4.6, 4.5, 4.4, 4.3, 4.2, 4.1, 4.0],
      bookingCount: 30,
    );

    final scenario884 = _buildDefaultScenario(
      name: 'سيناريو 8-8-4',
      techCount: 8,
      capacity: 8,
      ratings: [4.8, 4.8, 4.8, 4.8, 4.2, 4.2, 4.2, 4.2],
      bookingCount: 40,
    );

    final scenarioHighDemand = _buildDefaultScenario(
      name: 'طلب مرتفع (High Demand)',
      techCount: 4,
      capacity: 4,
      ratings: [4.9, 4.7, 4.5, 4.0],
      bookingCount: 35, // total capacity is 16, demand is 35
    );

    final scenarioLowDemand = _buildDefaultScenario(
      name: 'طلب منخفض (Low Demand)',
      techCount: 8,
      capacity: 10,
      ratings: [4.8, 4.7, 4.6, 4.5, 4.4, 4.3, 4.2, 4.1],
      bookingCount: 8, // total capacity is 80, demand is 8
    );

    emit(state.copyWith(
      technicians: defaultTechs,
      savedScenarios: [scenario1051, scenario884, scenarioHighDemand, scenarioLowDemand],
    ));

    // Generate bookings for the initial default technicians list
    generateBookings(state.generatedBookingCount);
  }

  DispatchLabScenario _buildDefaultScenario({
    required String name,
    required int techCount,
    required int capacity,
    required List<double> ratings,
    required int bookingCount,
  }) {
    final List<VirtualTechnician> techs = [];
    final List<String> names = [
      'عبد الرحمن', 'مصطفى', 'يوسف', 'حمزة', 'إبراهيم', 
      'سلمان', 'فيصل', 'سعد', 'ماجد', 'فهد'
    ];

    for (int i = 0; i < techCount; i++) {
      techs.add(VirtualTechnician(
        id: 'scen_tech_${name}_$i',
        name: i < names.length ? '${names[i]} (س_$capacity)' : 'فني $i (س_$capacity)',
        dailyCapacity: capacity,
        currentOrders: 0,
        rating: i < ratings.length ? ratings[i] : 4.5,
        isActive: true,
      ));
    }

    final bookings = _generateRawBookings(bookingCount);

    return DispatchLabScenario(
      name: name,
      technicians: techs,
      activeFilterRuleIds: state.activeFilterRules.map((e) => e.id).toList(),
      activeRankingRuleIds: state.activeRankingRules.map((e) => e.id).toList(),
      tieBreakerId: state.activeTieBreaker.id,
      bookings: bookings,
      bookingCount: bookingCount,
    );
  }

  List<VirtualBooking> _generateRawBookings(int count) {
    final List<VirtualBooking> generated = [];
    final services = ['تنظيف منازل', 'سباكة متميزة', 'صيانة كهرباء', 'غسيل سجاد الكنب', 'مكافحة حشرات'];
    for (int i = 1; i <= count; i++) {
      generated.add(VirtualBooking(
        id: _uuid.v4(),
        sequenceNumber: i,
        serviceName: services[_random.nextInt(services.length)],
        requiredCapacity: 1,
        createdAt: DateTime.now().add(Duration(minutes: i * 15)),
      ));
    }
    return generated;
  }

  // ============================================================================
  // TECHNICIAN CONFIGURATION
  // ============================================================================

  void addTechnician(String name, int capacity, double rating) {
    final newTech = VirtualTechnician(
      id: _uuid.v4(),
      name: name,
      dailyCapacity: capacity,
      currentOrders: 0,
      rating: rating,
      isActive: true,
      lastAssignedOrderIndex: null,
    );

    final updated = List<VirtualTechnician>.from(state.technicians)..add(newTech);
    emit(state.copyWith(technicians: updated));
    
    // If there is an active simulation, recalculate share/stats or let it reflect.
  }

  void removeTechnician(String id) {
    final updated = state.technicians.where((t) => t.id != id).toList();
    emit(state.copyWith(technicians: updated));
  }

  void updateTechnician(VirtualTechnician tech) {
    final updated = state.technicians.map((t) => t.id == tech.id ? tech : t).toList();
    emit(state.copyWith(technicians: updated));
  }

  void toggleTechnicianActive(String id) {
    final updated = state.technicians.map((t) {
      if (t.id == id) {
        return t.copyWith(isActive: !t.isActive);
      }
      return t;
    }).toList();
    emit(state.copyWith(technicians: updated));
  }

  // ============================================================================
  // BOOKING GENERATOR
  // ============================================================================

  void setGeneratedBookingCount(int count) {
    emit(state.copyWith(generatedBookingCount: count));
  }

  void generateBookings(int count) {
    stopContinuousSimulation();
    final newBookings = _generateRawBookings(count);

    // Reset technicians simulation metrics but preserve their settings
    final resetTechs = state.technicians.map((t) => t.copyWith(
      currentOrders: 0,
      lastAssignedOrderIndex: null,
    )).toList();

    emit(state.copyWith(
      bookings: newBookings,
      history: const [],
      technicians: resetTechs,
      currentBookingIndex: 0,
      generatedBookingCount: count,
      currentScenarioName: null, // Custom run
    ));
  }

  // ============================================================================
  // RULE MANAGEMENT
  // ============================================================================

  void updateActiveFilterRules(List<FilterRule> rules) {
    emit(state.copyWith(activeFilterRules: rules));
  }

  void updateActiveRankingRules(List<RankingRule> rules) {
    emit(state.copyWith(activeRankingRules: rules));
  }

  void updateTieBreaker(TieBreakerRule tieBreaker) {
    emit(state.copyWith(activeTieBreaker: tieBreaker));
  }

  // ============================================================================
  // SIMULATION CONTROLLERS
  // ============================================================================

  /// Dispatches the next booking in the queue.
  DispatchDecision? processNextBooking() {
    if (state.currentBookingIndex >= state.bookings.length) {
      stopContinuousSimulation();
      return null;
    }

    final booking = state.bookings[state.currentBookingIndex];
    
    // Create the Dispatch Engine with current rules configurations
    final engine = DispatchEngine(
      filterRules: state.activeFilterRules,
      rankingRules: state.activeRankingRules,
      tieBreaker: state.activeTieBreaker,
    );

    final decision = engine.dispatch(
      booking: booking,
      technicians: state.technicians,
    );

    // If a technician was selected, update their stats
    List<VirtualTechnician> updatedTechs = state.technicians;
    if (decision.selectedTechnician != null) {
      updatedTechs = state.technicians.map((t) {
        if (t.id == decision.selectedTechnician!.id) {
          return t.copyWith(
            currentOrders: t.currentOrders + booking.requiredCapacity,
            lastAssignedOrderIndex: booking.sequenceNumber,
          );
        }
        return t;
      }).toList();
    }

    final updatedHistory = List<DispatchDecision>.from(state.history)..add(decision);
    final nextIndex = state.currentBookingIndex + 1;

    emit(state.copyWith(
      technicians: updatedTechs,
      history: updatedHistory,
      currentBookingIndex: nextIndex,
    ));

    if (nextIndex >= state.bookings.length) {
      stopContinuousSimulation();
    }

    return decision;
  }

  void startContinuousSimulation({Duration delay = const Duration(milliseconds: 600)}) {
    if (state.isContinuousMode) return;
    if (state.currentBookingIndex >= state.bookings.length) {
      // Auto-replay or reset day if already finished?
      // Let's just replay or do nothing.
      replaySimulation();
    }

    emit(state.copyWith(isContinuousMode: true));
    _continuousTimer = Timer.periodic(delay, (timer) {
      final dec = processNextBooking();
      if (dec == null) {
        timer.cancel();
      }
    });
  }

  void stopContinuousSimulation() {
    _continuousTimer?.cancel();
    _continuousTimer = null;
    if (state.isContinuousMode) {
      emit(state.copyWith(isContinuousMode: false));
    }
  }

  void replaySimulation() {
    stopContinuousSimulation();
    
    final resetTechs = state.technicians.map((t) => t.copyWith(
      currentOrders: 0,
      lastAssignedOrderIndex: null,
    )).toList();

    emit(state.copyWith(
      technicians: resetTechs,
      history: const [],
      currentBookingIndex: 0,
      isContinuousMode: false,
    ));
  }

  void resetDay() {
    stopContinuousSimulation();

    final resetTechs = state.technicians.map((t) => t.copyWith(
      currentOrders: 0,
      lastAssignedOrderIndex: null,
    )).toList();

    emit(state.copyWith(
      technicians: resetTechs,
      bookings: const [],
      history: const [],
      currentBookingIndex: 0,
      isContinuousMode: false,
    ));
  }

  // ============================================================================
  // SCENARIO MANAGEMENT
  // ============================================================================

  void saveScenario(String name) {
    // Create new scenario from current state
    final scenario = DispatchLabScenario(
      name: name,
      technicians: state.technicians.map((t) => t.copyWith(
        currentOrders: 0,
        lastAssignedOrderIndex: null,
      )).toList(), // save starting state of technicians
      activeFilterRuleIds: state.activeFilterRules.map((e) => e.id).toList(),
      activeRankingRuleIds: state.activeRankingRules.map((e) => e.id).toList(),
      tieBreakerId: state.activeTieBreaker.id,
      bookings: state.bookings,
      bookingCount: state.bookings.length,
    );

    // Avoid duplication by name
    final updatedScenarios = state.savedScenarios.where((s) => s.name != name).toList()
      ..add(scenario);

    emit(state.copyWith(
      savedScenarios: updatedScenarios,
      currentScenarioName: name,
    ));
  }

  void loadScenario(DispatchLabScenario scenario) {
    stopContinuousSimulation();

    // Map IDs to rule instances
    final allFilters = [
      ExcludeInactiveRule(),
      ExcludeFullCapacityRule(),
      ExcludeLowRatingRule(),
      ExcludeExceedingFiftyPercentRule(),
    ];
    final allRankings = [
      UtilizationRankingRule(),
      RatingRankingRule(),
      IdleTimeRankingRule(),
      RemainingCapacityRankingRule(),
      RelativeCapacityRankingRule(),
      ProportionalShareRankingRule(),
    ];
    final allTieBreakers = [RandomTieBreaker(), FirstAvailableTieBreaker(), LeastTotalCapacityTieBreaker()];

    final filters = allFilters.where((f) => scenario.activeFilterRuleIds.contains(f.id)).toList();
    
    // Sort ranking rules to match scenario order
    final rankings = <RankingRule>[];
    for (final id in scenario.activeRankingRuleIds) {
      final rule = allRankings.firstWhere((r) => r.id == id);
      rankings.add(rule);
    }

    final tieBreaker = allTieBreakers.firstWhere(
      (t) => t.id == scenario.tieBreakerId,
      orElse: () => RandomTieBreaker(),
    );

    // Reset technicians when loading scenario
    final techs = scenario.technicians.map((t) => t.copyWith(
      currentOrders: 0,
      lastAssignedOrderIndex: null,
    )).toList();

    emit(state.copyWith(
      technicians: techs,
      bookings: scenario.bookings,
      history: const [],
      currentBookingIndex: 0,
      activeFilterRules: filters,
      activeRankingRules: rankings,
      activeTieBreaker: tieBreaker,
      currentScenarioName: scenario.name,
      generatedBookingCount: scenario.bookingCount,
    ));
  }

  @override
  Future<void> close() {
    _continuousTimer?.cancel();
    return super.close();
  }
}
