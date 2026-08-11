import 'package:shared/domain/user/entities/user/city.dart';

/// Data Model (DTO) for Geographic City.
class CityModel {
  final int id;
  final int governorateId;
  final String nameAr;
  final String nameEn;
  final bool isActive;
  final int sortOrder;

  const CityModel({
    required this.id,
    required this.governorateId,
    required this.nameAr,
    required this.nameEn,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      governorateId: (json['governorate_id'] as num?)?.toInt() ?? 0,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'governorate_id': governorateId,
      'name_ar': nameAr,
      'name_en': nameEn,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  City toEntity() {
    return City(
      id: id,
      governorateId: governorateId,
      nameAr: nameAr,
      nameEn: nameEn,
      isActive: isActive,
      sortOrder: sortOrder,
    );
  }

  factory CityModel.fromEntity(City entity) {
    return CityModel(
      id: entity.id,
      governorateId: entity.governorateId,
      nameAr: entity.nameAr,
      nameEn: entity.nameEn,
      isActive: entity.isActive,
      sortOrder: entity.sortOrder,
    );
  }
}
