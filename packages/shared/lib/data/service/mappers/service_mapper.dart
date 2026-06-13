import 'package:shared/data/service/models/local/service_hive_model.dart';
import 'package:shared/data/service/models/local/sub_models/service_details_hive_model.dart';
import 'package:shared/data/service/models/local/sub_models/service_price_hive_model.dart';
import 'package:shared/data/service/models/remote/service_remote_model.dart';
import 'package:shared/data/service/models/remote/sub_models/service_details_remote_model.dart';
import 'package:shared/data/service/models/remote/sub_models/service_price_remote_model.dart';
import 'package:shared/data/service/models/remote/sub_models/computed_field_remote_model.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/dynamic_field.dart';
import 'package:shared/domain/service/entities/service_entity.dart';
import 'package:shared/domain/service/entities/sub_entities/service_details.dart';
import 'package:shared/domain/service/entities/sub_entities/service_price.dart';
import 'package:shared/domain/service/entities/sub_entities/computed_field.dart';
import 'package:shared/domain/service/entities/main_service_entity.dart';
import 'package:shared/domain/service/entities/sub_service_entity.dart';
import 'package:shared/domain/service/enums/pricing_method.dart';


class ServiceMapper {
  // --- LanguageContent ---
  static LanguageContentEntity languageContentRemoteToEntity(
    LanguageContentRemoteModel model,
  ) {
    return LanguageContentEntity(
      title: model.title,
      icon: model.icon,
      iconPath: model.iconPath,
      iconId: model.iconId,
      points: model.points,
    );
  }

  static LanguageContentEntity languageContentHiveToEntity(
    LanguageContentHiveModel model,
  ) {
    return LanguageContentEntity(
      title: model.title,
      icon: model.icon,
      iconPath: model.iconPath,
      iconId: model.iconId,
      points: model.points,
    );
  }

  static LanguageContentRemoteModel languageContentToRemote(
    LanguageContentEntity entity,
  ) {
    return LanguageContentRemoteModel(
      title: entity.title,
      icon: entity.icon,
      iconPath: entity.iconPath,
      iconId: entity.iconId,
      points: entity.points,
    );
  }

  static LanguageContentHiveModel languageContentToHive(
    LanguageContentEntity entity,
  ) {
    return LanguageContentHiveModel(
      title: entity.title,
      icon: entity.icon,
      iconPath: entity.iconPath,
      iconId: entity.iconId,
      points: entity.points,
    );
  }

  // --- Detail ---
  static DetailEntity detailRemoteToEntity(DetailRemoteModel model) {
    return DetailEntity(
      id: model.id,
      ar: languageContentRemoteToEntity(model.ar),
      en: languageContentRemoteToEntity(model.en),
    );
  }

  static DetailEntity detailHiveToEntity(DetailHiveModel model) {
    return DetailEntity(
      id: model.id,
      ar: languageContentHiveToEntity(model.ar),
      en: languageContentHiveToEntity(model.en),
    );
  }

  static DetailRemoteModel detailToRemote(DetailEntity entity) {
    return DetailRemoteModel(
      id: entity.id,
      ar: languageContentToRemote(entity.ar),
      en: languageContentToRemote(entity.en),
    );
  }

  static DetailHiveModel detailToHive(DetailEntity entity) {
    return DetailHiveModel(
      id: entity.id,
      ar: languageContentToHive(entity.ar),
      en: languageContentToHive(entity.en),
    );
  }

  // --- PriceOption ---
  static PriceOptionEntity priceOptionRemoteToEntity(
    PriceOptionRemoteModel model,
  ) {
    return PriceOptionEntity(key: model.key, value: model.value);
  }

  static PriceOptionEntity priceOptionHiveToEntity(PriceOptionHiveModel model) {
    return PriceOptionEntity(key: model.key, value: model.value);
  }

  static PriceOptionRemoteModel priceOptionToRemote(PriceOptionEntity entity) {
    return PriceOptionRemoteModel(
      key: entity.key ?? '',
      value: entity.value?.toDouble() ?? 0.0,
    );
  }

  static PriceOptionHiveModel priceOptionToHive(PriceOptionEntity entity) {
    return PriceOptionHiveModel(
      key: entity.key ?? '',
      value: entity.value?.toDouble() ?? 0.0,
    );
  }

  // --- DynamicField Mapping Helpers ---
  static DynamicFieldEntity dynamicFieldRemoteToEntity(
    DynamicFieldRemoteModel model,
  ) {
    return DynamicFieldEntity(
      id: model.id,
      type: DynamicFieldType.fromString(model.type),
      label: model.label,
      required: model.required,
      min: model.min,
      unit: model.unit,
      priceModifier: model.priceModifier,
      options: model.options
          ?.map((opt) => DropdownOptionEntity(
                id: opt.id,
                label: opt.label,
              ))
          .toList(),
      description: model.description,
      icon: model.icon,
      displayType: model.displayType,
    );
  }

  static DynamicFieldEntity dynamicFieldMapToEntity(Map<dynamic, dynamic> map) {
    return DynamicFieldEntity(
      id: map['id'] as String? ?? '',
      type: DynamicFieldType.fromString(map['type'] as String? ?? ''),
      label: Map<String, String>.from(map['label'] as Map? ?? {}),
      required: map['required'] as bool? ?? false,
      min: map['min'] as num?,
      unit: map['unit'] as String?,
      priceModifier: map['price_modifier'] as num?,
      options: (map['options'] as List?)
          ?.map((opt) => DropdownOptionEntity(
                id: (opt as Map)['id'] as String? ?? '',
                label: Map<String, String>.from(opt['label'] as Map? ?? {}),
              ))
          .toList(),
      description: map['description'] != null
          ? Map<String, String>.from(map['description'] as Map? ?? {})
          : null,
      icon: map['icon'] as String?,
      displayType: map['display_type'] as String?,
    );
  }

  static DynamicFieldRemoteModel dynamicFieldToRemote(DynamicFieldEntity entity) {
    return DynamicFieldRemoteModel(
      id: entity.id,
      type: entity.type.name,
      label: entity.label,
      required: entity.required,
      min: entity.min?.toDouble(),
      unit: entity.unit,
      priceModifier: entity.priceModifier?.toDouble(),
      options: entity.options
          ?.map((opt) => DropdownOptionRemoteModel(
                id: opt.id,
                label: opt.label,
              ))
          .toList(),
      description: entity.description,
      icon: entity.icon,
      displayType: entity.displayType,
    );
  }

  static Map<String, dynamic> dynamicFieldToMap(DynamicFieldEntity entity) {
    return {
      'id': entity.id,
      'type': entity.type.name,
      'label': entity.label,
      'required': entity.required,
      'min': entity.min,
      'unit': entity.unit,
      'price_modifier': entity.priceModifier,
      'options': entity.options
          ?.map((opt) => {
                'id': opt.id,
                'label': opt.label,
              })
          .toList(),
      'description': entity.description,
      'icon': entity.icon,
      'display_type': entity.displayType,
    };
  }

  // --- Price ---
  static PriceEntity priceRemoteToEntity(PriceRemoteModel model) {
    return PriceEntity(
      type: model.type,
      value: model.value,
      unit: model.unit,
      options: model.options.map(priceOptionRemoteToEntity).toList(),
      fields: model.fields.map(dynamicFieldRemoteToEntity).toList(),
      basePriceFormula: model.basePriceFormula,
      minPrice: model.minPrice,
    );
  }

  static PriceEntity priceHiveToEntity(PriceHiveModel model) {
    return PriceEntity(
      type: model.type,
      value: model.value,
      unit: model.unit,
      options: model.options.map(priceOptionHiveToEntity).toList(),
      fields: model.fields
              ?.map((e) => dynamicFieldMapToEntity(e as Map))
              .toList() ??
          const [],
      basePriceFormula: model.basePriceFormula,
      minPrice: model.minPrice,
    );
  }

  static PriceRemoteModel priceToRemote(PriceEntity entity) {
    return PriceRemoteModel(
      type: entity.type,
      value: entity.value.toDouble(),
      unit: entity.unit,
      options: entity.options.map(priceOptionToRemote).toList(),
      fields: entity.fields.map(dynamicFieldToRemote).toList(),
      basePriceFormula: entity.basePriceFormula,
      minPrice: entity.minPrice?.toDouble(),
    );
  }

  static PriceHiveModel priceToHive(PriceEntity entity) {
    return PriceHiveModel(
      type: entity.type,
      value: entity.value.toDouble(),
      unit: entity.unit,
      options: entity.options.map(priceOptionToHive).toList(),
      fields: entity.fields.map(dynamicFieldToMap).toList(),
      basePriceFormula: entity.basePriceFormula,
      minPrice: entity.minPrice?.toDouble(),
    );
  }

  // --- NotIncluded ---
  static NotIncludedEntity notIncludedRemoteToEntity(
    NotIncludedRemoteModel model,
  ) {
    return NotIncludedEntity(
      ar: model.ar != null
          ? languageContentRemoteToEntity(model.ar!)
          : const LanguageContentEntity(),
      en: model.en != null
          ? languageContentRemoteToEntity(model.en!)
          : const LanguageContentEntity(),
    );
  }

  static NotIncludedEntity notIncludedHiveToEntity(NotIncludedHiveModel model) {
    return NotIncludedEntity(
      ar: languageContentHiveToEntity(model.ar),
      en: languageContentHiveToEntity(model.en),
    );
  }

  static NotIncludedRemoteModel notIncludedToRemote(NotIncludedEntity entity) {
    return NotIncludedRemoteModel(
      ar: languageContentToRemote(entity.ar),
      en: languageContentToRemote(entity.en),
    );
  }

    static NotIncludedHiveModel notIncludedToHive(NotIncludedEntity entity) {
    return NotIncludedHiveModel(
      ar: languageContentToHive(entity.ar),
      en: languageContentToHive(entity.en),
    );
  }

  // --- ComputedField Mappings ---
  static ComputedFieldEntity computedFieldRemoteToEntity(
    ComputedFieldRemoteModel model,
  ) {
    return ComputedFieldEntity(
      id: model.id ?? '',
      formula: model.formula ?? '',
      label: model.label ?? const {},
    );
  }

  static ComputedFieldEntity computedFieldMapToEntity(Map<dynamic, dynamic> map) {
    return ComputedFieldEntity(
      id: map['id'] as String? ?? '',
      formula: map['formula'] as String? ?? '',
      label: Map<String, String>.from(map['label'] as Map? ?? {}),
    );
  }

  static ComputedFieldRemoteModel computedFieldToRemote(ComputedFieldEntity entity) {
    return ComputedFieldRemoteModel(
      id: entity.id,
      formula: entity.formula,
      label: entity.label,
    );
  }

  static Map<String, dynamic> computedFieldToMap(ComputedFieldEntity entity) {
    return {
      'id': entity.id,
      'formula': entity.formula,
      'label': entity.label,
    };
  }

  // --- Unified Service Mappings ---

  static ServiceEntity remoteToEntity(ServiceRemoteModel model) {
    return ServiceEntity(
      id: model.id,
      parentId: model.parentId,
      isBookable: model.isBookable,
      title: model.title,
      description: model.description,
      instructions: model.instructions,
      image: model.image,
      status: model.status,
      order: model.order,
      updatedAt: model.updatedAt,
      price: model.priceConfig != null ? priceRemoteToEntity(model.priceConfig!) : null,
      details: model.details?.map(detailRemoteToEntity).toList(),
      notIncluded: model.notIncluded != null ? notIncludedRemoteToEntity(model.notIncluded!) : null,
      computedFields: model.computedFields?.map(computedFieldRemoteToEntity).toList(),
      commissionRate: model.commissionRate,
    );
  }

  static ServiceEntity hiveToEntity(ServiceHiveModel model) {
    return ServiceEntity(
      id: model.id,
      parentId: model.parentId,
      isBookable: model.isBookable,
      title: model.title,
      description: model.description,
      instructions: model.instructions,
      image: model.image,
      status: model.status,
      order: model.order,
      updatedAt: model.updatedAt,
      price: model.price != null ? priceHiveToEntity(model.price!) : null,
      details: model.details?.map(detailHiveToEntity).toList(),
      notIncluded: model.notIncluded != null ? notIncludedHiveToEntity(model.notIncluded!) : null,
      computedFields: model.computedFields?.map((e) => computedFieldMapToEntity(e as Map)).toList(),
      commissionRate: model.commissionRate,
    );
  }

  static ServiceRemoteModel entityToRemote(ServiceEntity entity) {
    return ServiceRemoteModel(
      id: entity.id,
      parentId: entity.parentId,
      isBookable: entity.isBookable,
      title: entity.title,
      description: entity.description,
      instructions: entity.instructions,
      image: entity.image,
      status: entity.status,
      order: entity.order,
      updatedAt: entity.updatedAt,
      priceConfig: entity.price != null ? priceToRemote(entity.price!) : null,
      details: entity.details?.map(detailToRemote).toList(),
      notIncluded: entity.notIncluded != null ? notIncludedToRemote(entity.notIncluded!) : null,
      computedFields: entity.computedFields?.map(computedFieldToRemote).toList(),
      commissionRate: entity.commissionRate,
    );
  }

  static ServiceHiveModel entityToHive(ServiceEntity entity) {
    return ServiceHiveModel(
      id: entity.id,
      parentId: entity.parentId,
      isBookable: entity.isBookable,
      title: entity.title,
      description: entity.description,
      instructions: entity.instructions,
      image: entity.image,
      status: entity.status,
      order: entity.order,
      updatedAt: entity.updatedAt,
      price: entity.price != null ? priceToHive(entity.price!) : null,
      details: entity.details?.map(detailToHive).toList(),
      notIncluded: entity.notIncluded != null ? notIncludedToHive(entity.notIncluded!) : null,
      computedFields: entity.computedFields?.map(computedFieldToMap).toList(),
      commissionRate: entity.commissionRate,
    );
  }

  static ServiceHiveModel remoteToHive(ServiceRemoteModel model) {
    return ServiceHiveModel(
      id: model.id,
      parentId: model.parentId,
      isBookable: model.isBookable,
      title: model.title,
      description: model.description,
      instructions: model.instructions,
      image: model.image,
      status: model.status,
      order: model.order,
      updatedAt: model.updatedAt,
      price: model.priceConfig != null ? priceToHive(priceRemoteToEntity(model.priceConfig!)) : null,
      details: model.details?.map((e) => detailToHive(detailRemoteToEntity(e))).toList(),
      notIncluded: model.notIncluded != null ? notIncludedToHive(notIncludedRemoteToEntity(model.notIncluded!)) : null,
      computedFields: model.computedFields?.map((e) => computedFieldToMap(computedFieldRemoteToEntity(e))).toList(),
      commissionRate: model.commissionRate,
    );
  }

  static MainServiceEntity serviceToMainServiceEntity(ServiceEntity service, List<ServiceEntity> children) {
    return MainServiceEntity(
      id: service.id,
      parentId: service.parentId,
      isBookable: service.isBookable,
      title: service.title,
      description: service.description,
      instructions: service.instructions,
      image: service.image,
      status: service.status,
      order: service.order,
      updatedAt: service.updatedAt,
      subServices: children.map((c) => serviceToSubServiceEntity(c)).toList(),
    );
  }

  static SubServiceEntity serviceToSubServiceEntity(ServiceEntity service) {
    return SubServiceEntity(
      id: service.id,
      parentId: service.parentId,
      isBookable: service.isBookable,
      title: service.title,
      description: service.description,
      instructions: service.instructions,
      image: service.image,
      status: service.status,
      order: service.order,
      updatedAt: service.updatedAt,
      commissionRate: service.commissionRate,
      price: service.price ?? PriceEntity(
        type: PricingMethod.fixed,
        value: 0.0,
        unit: '',
        options: const [],
      ),
      details: service.details ?? const [],
      notIncluded: service.notIncluded ?? NotIncludedEntity(
        ar: const LanguageContentEntity(title: '', icon: '', points: []),
        en: const LanguageContentEntity(title: '', icon: '', points: []),
      ),
      computedFields: service.computedFields,
    );
  }

  static MainServiceEntity remoteToEntityMain(ServiceRemoteModel model) {
    return serviceToMainServiceEntity(remoteToEntity(model), []);
  }

  static SubServiceEntity remoteToEntitySub(ServiceRemoteModel model) {
    return serviceToSubServiceEntity(remoteToEntity(model));
  }
}
