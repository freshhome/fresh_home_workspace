class ServicesUpdatedEntity {
  final DateTime lastUpdatedAt;
  final Map<String, DateTime> services;
  final Map<String, DateTime> subServices;

  const ServicesUpdatedEntity({
    required this.lastUpdatedAt,
    required this.services,
    required this.subServices,
  });
}
 