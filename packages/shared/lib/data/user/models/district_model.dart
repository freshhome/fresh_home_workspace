import 'package:shared/domain/user/entities/user/district.dart';

/// Data Model (DTO) for Geographic District / Area.
class DistrictModel {
  final int id;
  final int cityId;
  final String nameAr;
  final String nameEn;
  final bool isActive;
  final int sortOrder;

  const DistrictModel({
    required this.id,
    required this.cityId,
    required this.nameAr,
    required this.nameEn,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      cityId: (json['city_id'] as num?)?.toInt() ?? 0,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city_id': cityId,
      'name_ar': nameAr,
      'name_en': nameEn,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  District toEntity() {
    return District(
      id: id,
      cityId: cityId,
      nameAr: nameAr,
      nameEn: nameEn,
      isActive: isActive,
      sortOrder: sortOrder,
    );
  }

  factory DistrictModel.fromEntity(District entity) {
    return DistrictModel(
      id: entity.id,
      cityId: entity.cityId,
      nameAr: entity.nameAr,
      nameEn: entity.nameEn,
      isActive: entity.isActive,
      sortOrder: entity.sortOrder,
    );
  }
}
