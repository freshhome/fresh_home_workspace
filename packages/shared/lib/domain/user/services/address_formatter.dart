import 'package:shared/domain/user/entities/user/address.dart';

/// Domain Service providing standardized text formatting for addresses.
class AddressFormatter {
  /// Single line representation for overview lists and booking review screens.
  static String toSingleLine(Address address) {
    final parts = <String>[];
    parts.add(address.district);
    parts.add(address.streetOrCompound);
    parts.add(address.buildingIdentifier);

    if (address.floor != null && address.floor!.isNotEmpty) {
      parts.add('Floor ${address.floor}');
    }
    if (address.apartmentOrUnit != null && address.apartmentOrUnit!.isNotEmpty) {
      parts.add('Apt ${address.apartmentOrUnit}');
    }
    if (address.landmark != null && address.landmark!.isNotEmpty) {
      parts.add('(${address.landmark})');
    }
    parts.add(address.city);
    parts.add(address.governorate);

    return parts.join(', ');
  }

  /// Multi-line representation suitable for receipts, invoices, and detailed address cards.
  static String toMultiLine(Address address) {
    final lines = <String>[];
    lines.add('${address.buildingIdentifier}, ${address.streetOrCompound}');
    
    final unitParts = <String>[];
    if (address.floor != null && address.floor!.isNotEmpty) {
      unitParts.add('Floor ${address.floor}');
    }
    if (address.apartmentOrUnit != null && address.apartmentOrUnit!.isNotEmpty) {
      unitParts.add('Apt/Unit ${address.apartmentOrUnit}');
    }
    if (unitParts.isNotEmpty) {
      lines.add(unitParts.join(' - '));
    }

    if (address.landmark != null && address.landmark!.isNotEmpty) {
      lines.add('Landmark: ${address.landmark}');
    }

    lines.add('${address.district}, ${address.city}, ${address.governorate}');
    return lines.join('\n');
  }

  /// Short summary for compact dropdowns, selection pills, and order headers.
  static String toShortSummary(Address address) {
    return '${address.district} - ${address.streetOrCompound} (${address.buildingIdentifier})';
  }

  /// Technician Last-100m delivery summary focusing on immediate arrival details.
  static String toTechnicianSummary(Address address) {
    final details = <String>[];
    details.add('Bldg: ${address.buildingIdentifier}');
    if (address.floor != null && address.floor!.isNotEmpty) {
      details.add('Floor: ${address.floor}');
    }
    if (address.apartmentOrUnit != null && address.apartmentOrUnit!.isNotEmpty) {
      details.add('Apt: ${address.apartmentOrUnit}');
    }
    if (address.landmark != null && address.landmark!.isNotEmpty) {
      details.add('Landmark: ${address.landmark}');
    }
    return details.join(' | ');
  }

  /// Unbound Google Maps / Waze navigation query string.
  static String toGoogleMapsQuery(Address address) {
    if (address.hasCoordinates) {
      return '${address.latitude},${address.longitude}';
    }
    return '${address.district}, ${address.streetOrCompound}, ${address.buildingIdentifier}, ${address.city}, ${address.governorate}';
  }
}
