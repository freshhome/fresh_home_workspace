import 'package:equatable/equatable.dart';

/// Domain Entity representing a Geographic City in Fresh Home System V2.
class City extends Equatable {
  final int id;
  final int governorateId;
  final String nameAr;
  final String nameEn;
  final bool isActive;
  final int sortOrder;

  const City({
    required this.id,
    required this.governorateId,
    required this.nameAr,
    required this.nameEn,
    this.isActive = true,
    this.sortOrder = 0,
  });

  /// Helper returning localized name based on application locale.
  String getName(String locale) {
    if (locale.toLowerCase().startsWith('en')) {
      return nameEn.isNotEmpty ? nameEn : nameAr;
    }
    return nameAr.isNotEmpty ? nameAr : nameEn;
  }

  @override
  List<Object?> get props => [id, governorateId, nameAr, nameEn, isActive, sortOrder];
}
