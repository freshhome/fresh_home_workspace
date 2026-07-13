import 'package:equatable/equatable.dart';
import '../../domain/entities/virtual_booking.dart';
import '../../domain/entities/virtual_technician.dart';

class DispatchLabScenario extends Equatable {
  final String name;
  final List<VirtualTechnician> technicians;
  final List<String> activeFilterRuleIds;
  final List<String> activeRankingRuleIds;
  final String tieBreakerId;
  final List<VirtualBooking> bookings;
  final int bookingCount;

  const DispatchLabScenario({
    required this.name,
    required this.technicians,
    required this.activeFilterRuleIds,
    required this.activeRankingRuleIds,
    required this.tieBreakerId,
    required this.bookings,
    required this.bookingCount,
  });

  factory DispatchLabScenario.fromJson(Map<String, dynamic> json) {
    return DispatchLabScenario(
      name: json['name'] as String,
      technicians: (json['technicians'] as List<dynamic>)
          .map((e) => VirtualTechnician.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeFilterRuleIds: List<String>.from(json['activeFilterRuleIds'] as List<dynamic>),
      activeRankingRuleIds: List<String>.from(json['activeRankingRuleIds'] as List<dynamic>),
      tieBreakerId: json['tieBreakerId'] as String,
      bookings: (json['bookings'] as List<dynamic>)
          .map((e) => VirtualBooking.fromJson(e as Map<String, dynamic>))
          .toList(),
      bookingCount: json['bookingCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'technicians': technicians.map((e) => e.toJson()).toList(),
      'activeFilterRuleIds': activeFilterRuleIds,
      'activeRankingRuleIds': activeRankingRuleIds,
      'tieBreakerId': tieBreakerId,
      'bookings': bookings.map((e) => e.toJson()).toList(),
      'bookingCount': bookingCount,
    };
  }

  @override
  List<Object?> get props => [
        name,
        technicians,
        activeFilterRuleIds,
        activeRankingRuleIds,
        tieBreakerId,
        bookings,
        bookingCount,
      ];
}
