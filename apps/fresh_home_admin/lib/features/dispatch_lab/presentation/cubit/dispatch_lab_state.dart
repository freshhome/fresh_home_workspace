import 'package:equatable/equatable.dart';
import '../../domain/entities/dispatch_decision.dart';
import '../../domain/entities/dispatch_rules.dart';
import '../../domain/entities/virtual_booking.dart';
import '../../domain/entities/virtual_technician.dart';
import '../../data/models/dispatch_lab_scenario.dart';

class DispatchLabState extends Equatable {
  final List<VirtualTechnician> technicians;
  final List<VirtualBooking> bookings;
  final List<DispatchDecision> history;
  final List<FilterRule> activeFilterRules;
  final List<RankingRule> activeRankingRules;
  final TieBreakerRule activeTieBreaker;
  final bool isContinuousMode;
  final int currentBookingIndex;
  final List<DispatchLabScenario> savedScenarios;
  final String? currentScenarioName;
  final String? error;
  final int generatedBookingCount;

  const DispatchLabState({
    required this.technicians,
    required this.bookings,
    required this.history,
    required this.activeFilterRules,
    required this.activeRankingRules,
    required this.activeTieBreaker,
    required this.isContinuousMode,
    required this.currentBookingIndex,
    required this.savedScenarios,
    this.currentScenarioName,
    this.error,
    required this.generatedBookingCount,
  });

  factory DispatchLabState.initial() {
    return DispatchLabState(
      technicians: const [],
      bookings: const [],
      history: const [],
      activeFilterRules: [
        ExcludeInactiveRule(),
        ExcludeFullCapacityRule(),
        ExcludeExceedingFiftyPercentRule(),
      ],
      activeRankingRules: [
        ProportionalShareRankingRule(),
        RatingRankingRule(),
        IdleTimeRankingRule(),
      ],
      activeTieBreaker: RandomTieBreaker(),
      isContinuousMode: false,
      currentBookingIndex: 0,
      savedScenarios: const [],
      currentScenarioName: null,
      error: null,
      generatedBookingCount: 10,
    );
  }

  DispatchLabState copyWith({
    List<VirtualTechnician>? technicians,
    List<VirtualBooking>? bookings,
    List<DispatchDecision>? history,
    List<FilterRule>? activeFilterRules,
    List<RankingRule>? activeRankingRules,
    TieBreakerRule? activeTieBreaker,
    bool? isContinuousMode,
    int? currentBookingIndex,
    List<DispatchLabScenario>? savedScenarios,
    String? currentScenarioName,
    String? error,
    int? generatedBookingCount,
  }) {
    return DispatchLabState(
      technicians: technicians ?? this.technicians,
      bookings: bookings ?? this.bookings,
      history: history ?? this.history,
      activeFilterRules: activeFilterRules ?? this.activeFilterRules,
      activeRankingRules: activeRankingRules ?? this.activeRankingRules,
      activeTieBreaker: activeTieBreaker ?? this.activeTieBreaker,
      isContinuousMode: isContinuousMode ?? this.isContinuousMode,
      currentBookingIndex: currentBookingIndex ?? this.currentBookingIndex,
      savedScenarios: savedScenarios ?? this.savedScenarios,
      currentScenarioName: currentScenarioName ?? this.currentScenarioName,
      error: error ?? this.error,
      generatedBookingCount: generatedBookingCount ?? this.generatedBookingCount,
    );
  }

  @override
  List<Object?> get props => [
        technicians,
        bookings,
        history,
        activeFilterRules,
        activeRankingRules,
        activeTieBreaker,
        isContinuousMode,
        currentBookingIndex,
        savedScenarios,
        currentScenarioName,
        error,
        generatedBookingCount,
      ];
}
