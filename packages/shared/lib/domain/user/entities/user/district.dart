import 'package:equatable/equatable.dart';

/// Domain Entity representing a Geographic District / Area in Fresh Home System V2.
class District extends Equatable {
  final int id;
  final int cityId;
  final String nameAr;
  final String nameEn;
  final bool isActive;
  final int sortOrder;

  const District({
    required this.id,
    required this.cityId,
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
  List<Object?> get props => [id, cityId, nameAr, nameEn, isActive, sortOrder];
}
