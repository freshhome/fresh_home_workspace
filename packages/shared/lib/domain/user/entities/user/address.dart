class Address {
  final String? id;
  final String governorate;
  final String city;
  final String street;
  final String buildingNumber;
  final String? apartmentNumber;
  final String? floorNumber;
  final double? latitude;
  final double? longitude;

  Address({
    this.id,
    required this.governorate,
    required this.city,
    required this.street,
    required this.buildingNumber,
    this.apartmentNumber,
    this.floorNumber,
    this.latitude,
    this.longitude,
  });
}
