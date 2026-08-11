import 'package:equatable/equatable.dart';

/// Domain Entity representing a Geographic Governorate in Fresh Home System V2.
class Governorate extends Equatable {
  final int id;
  final String nameAr;
  final String nameEn;
  final String code;
  final bool isActive;
  final int sortOrder;

  const Governorate({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.code,
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
  List<Object?> get props => [id, nameAr, nameEn, code, isActive, sortOrder];
}
