import 'package:shared/domain/user/entities/user/governorate.dart';

/// Data Model (DTO) for Geographic Governorate.
class GovernorateModel {
  final int id;
  final String nameAr;
  final String nameEn;
  final String code;
  final bool isActive;
  final int sortOrder;

  const GovernorateModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.code,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory GovernorateModel.fromJson(Map<String, dynamic> json) {
    return GovernorateModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      code: json['code'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'code': code,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  Governorate toEntity() {
    return Governorate(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      code: code,
      isActive: isActive,
      sortOrder: sortOrder,
    );
  }

  factory GovernorateModel.fromEntity(Governorate entity) {
    return GovernorateModel(
      id: entity.id,
      nameAr: entity.nameAr,
      nameEn: entity.nameEn,
      code: entity.code,
      isActive: entity.isActive,
      sortOrder: entity.sortOrder,
    );
  }
}
