import 'package:shared/domain/user/entities/user/address.dart';

/// Domain Service providing standardized text formatting for addresses (V3).
/// V3 uses the unified [addressDetails] field instead of fragmented street/building/floor/apartment.
class AddressFormatter {
  /// Single line representation for overview lists and booking review screens.
  static String toSingleLine(Address address) {
    return '${address.district}، ${address.city} - ${address.addressDetails}';
  }

  /// Multi-line representation suitable for receipts, invoices, and detailed address cards.
  static String toMultiLine(Address address) {
    final lines = <String>[];
    lines.add(address.addressDetails);
    lines.add('${address.district}، ${address.city}، ${address.governorate}');
    if (address.hasLocationUrl) {
      lines.add(address.locationUrl!);
    }
    return lines.join('\n');
  }

  /// Short summary for compact dropdowns, selection pills, and order headers.
  static String toShortSummary(Address address) {
    return '${address.district} - ${address.addressDetails}';
  }

  /// Technician Last-100m delivery summary focusing on immediate arrival details.
  static String toTechnicianSummary(Address address) {
    return address.addressDetails;
  }

  /// Unbound Google Maps / Waze navigation query string.
  static String toGoogleMapsQuery(Address address) {
    if (address.hasCoordinates) {
      return '${address.latitude},${address.longitude}';
    }
    return '${address.district}, ${address.city}, ${address.governorate}';
  }
}
