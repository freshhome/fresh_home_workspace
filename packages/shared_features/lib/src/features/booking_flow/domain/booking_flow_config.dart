import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/service/entities/sub_entities/service_price.dart';

enum BookingFlowMode { customer, admin }

/// Configuration class that drives the booking flow behaviour.
/// Pass this as a parameter when launching the booking feature.
class BookingFlowConfig {
  final BookingFlowMode mode;

  /// For customer mode: the authenticated customer's userId.
  /// For admin mode: the authenticated admin's userId.
  final String actorId;

  /// For customer mode: the service is pre-selected before entering the flow.
  /// For admin mode: leave null so the user picks from the service catalogue.
  final BookedService? preSelectedService;

  /// Optional initial price entity (e.g. from the service detail screen).
  final PriceEntity? initialServicePrice;

  const BookingFlowConfig({
    required this.mode,
    required this.actorId,
    this.preSelectedService,
    this.initialServicePrice,
  });

  /// Does the flow need an internal service-selection step?
  bool get requiresServiceSelection => preSelectedService == null;

  /// Should the flow load and sync the customer's saved Profile data?
  bool get requiresProfileSync => mode == BookingFlowMode.customer;

  /// Should the flow show a manual client-data entry step?
  bool get requiresManualClientData => mode == BookingFlowMode.admin;

  /// Total number of steps shown in the progress bar.
  /// Admin: Service → Pricing → Schedule → Client Data → Confirm (5)
  /// Customer: Pricing → Schedule → Address → Confirm (4)
  int get totalSteps => requiresManualClientData ? 5 : 4;

  /// The earliest date a user can select for booking.
  /// Admin can book for today (same-day booking).
  /// Customers must book from tomorrow.
  DateTime get earliestSelectableDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (mode == BookingFlowMode.admin) {
      return today;
    } else {
      return today.add(const Duration(days: 1));
    }
  }
}
