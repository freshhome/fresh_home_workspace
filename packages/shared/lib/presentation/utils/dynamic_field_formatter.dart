import 'package:shared/domain/booking/entities/booking/sub_entities/dynamic_field_snapshot.dart';

class FormattedField {
  final String id;
  final String label;
  final String displayValue;
  final String type;
  final String? unit;

  const FormattedField({
    required this.id,
    required this.label,
    required this.displayValue,
    required this.type,
    this.unit,
  });
}

class DynamicFieldFormatter {
  static const Set<String> _excludedKeys = {
    'selected_options',
    'windows',
    '__field_snapshot',
    '__field_labels',
    'name',
    'phone',
    'customer_name',
    'customer_phone',
    'client_name',
    'client_phone',
    'contact_name',
    'contact_phone',
    'payment_method',
    'payment_type',
    'payment_status',
    'total',
    'price',
    'address_id',
    'service_id',
    'sub_service_id',
  };

  static const Map<String, Map<String, String>> _knownFieldLabels = {
    'area': {'ar': 'المساحة', 'en': 'Area'},
    'rooms': {'ar': 'عدد الغرف', 'en': 'Rooms'},
    'bathrooms': {'ar': 'عدد الحمامات', 'en': 'Bathrooms'},
    'kitchens': {'ar': 'عدد المطابخ', 'en': 'Kitchens'},
    'living_rooms': {'ar': 'عدد الصالات', 'en': 'Living Rooms'},
    'floors': {'ar': 'عدد الطوابق', 'en': 'Floors'},
    'balconies': {'ar': 'عدد الشرفات', 'en': 'Balconies'},
    'windows': {'ar': 'النوافذ', 'en': 'Windows'},
    'property_type': {'ar': 'نوع العقار', 'en': 'Property Type'},
    'cleaning_type': {'ar': 'نوع التنظيف', 'en': 'Cleaning Type'},
    'furnishing_status': {'ar': 'حالة الفرش', 'en': 'Furnishing Status'},
    'duration': {'ar': 'المدة', 'en': 'Duration'},
    'hours': {'ar': 'عدد الساعات', 'en': 'Hours'},
    'technicians_count': {'ar': 'عدد الفنيين', 'en': 'Technicians Count'},
    'frequency': {'ar': 'التكرار', 'en': 'Frequency'},
    'notes': {'ar': 'ملاحظات', 'en': 'Notes'},
  };

  static const Map<String, Map<String, String>> _knownFieldUnits = {
    'area': {'ar': 'م²', 'en': 'm²'},
    'hours': {'ar': 'ساعة', 'en': 'hrs'},
  };

  static List<FormattedField> formatBooking({
    required Map<String, dynamic> pricingInputs,
    required DynamicFieldSnapshot? snapshot,
    required String locale,
  }) {
    final List<FormattedField> list = [];

    // Filter metadata keys and customer info/payment methods
    final Map<String, dynamic> filteredInputs = Map<String, dynamic>.from(pricingInputs)
      ..removeWhere((k, v) =>
          v == null ||
          v.toString() == 'null' ||
          _excludedKeys.contains(k.toLowerCase()));

    if (snapshot != null) {
      // 1. Process using strongly-typed Snapshot Field Definitions
      for (final entry in filteredInputs.entries) {
        final key = entry.key;
        final val = entry.value;
        final schema = snapshot.fields.firstWhere(
          (f) => f.id == key,
          orElse: () => SnapshotField(
            id: key,
            type: 'text',
            label: {locale: key},
          ),
        );

        var labelText = schema.label[locale] ?? schema.label['ar'] ?? key;
        if (labelText == key) {
          // Fallback to __field_labels if snapshot doesn't have label
          final rawLabels = pricingInputs['__field_labels'] as Map?;
          if (rawLabels != null) {
            final labelMap = rawLabels[key];
            if (labelMap is Map) {
              labelText = labelMap[locale]?.toString() ?? labelMap['ar']?.toString() ?? key;
            }
          }
        }
        if (labelText == key) {
          final known = _knownFieldLabels[key.toLowerCase()];
          if (known != null) {
            labelText = known[locale] ?? known['ar'] ?? key;
          }
        }

        var unitText = schema.unit?[locale] ?? schema.unit?['ar'];
        if (unitText == null || unitText.isEmpty) {
          unitText = _knownFieldUnits[key.toLowerCase()]?[locale] ?? _knownFieldUnits[key.toLowerCase()]?['ar'];
        }
        String displayValue = '';

        if (schema.type == 'toggle') {
          final bool isTrue = val == true || val.toString().toLowerCase() == 'true';
          displayValue = isTrue 
              ? (locale == 'ar' ? 'نعم' : 'Yes') 
              : (locale == 'ar' ? 'لا' : 'No');
        } else if (schema.type == 'dropdown' || schema.type == 'optionsGroup' || schema.type == 'options_group') {
          if (val is List) {
            final List<String> labels = [];
            for (final item in val) {
              final option = schema.options?.firstWhere(
                (o) => o.id == item.toString(),
                orElse: () => SnapshotOption(id: item.toString(), label: {locale: item.toString()}),
              );
              labels.add(option?.label[locale] ?? option?.label['ar'] ?? item.toString());
            }
            displayValue = labels.join(', ');
          } else {
            final option = schema.options?.firstWhere(
              (o) => o.id == val.toString(),
              orElse: () => SnapshotOption(id: val.toString(), label: {locale: val.toString()}),
            );
            displayValue = option?.label[locale] ?? option?.label['ar'] ?? val.toString();
          }
        } else if (schema.type == 'number') {
          final num? number = num.tryParse(val.toString());
          displayValue = number != null 
              ? number.toStringAsFixed(number.truncateToDouble() == number ? 0 : 1) 
              : val.toString();
        } else {
          displayValue = val.toString();
        }

        list.add(FormattedField(
          id: key,
          label: labelText,
          displayValue: displayValue,
          type: schema.type,
          unit: unitText,
        ));
      }
    } else {
      // 2. Legacy Fallback: Parse using __field_labels (flat map)
      final rawLabels = pricingInputs['__field_labels'] as Map?;
      final Map<String, Map<String, String>> fieldLabels = {};
      if (rawLabels != null) {
        rawLabels.forEach((k, v) {
          if (v is Map) {
            fieldLabels[k.toString()] = Map<String, String>.from(v);
          }
        });
      }

      for (final entry in filteredInputs.entries) {
        final key = entry.key;
        final val = entry.value;

        // Try to translate label
        final labelMap = fieldLabels[key];
        var labelText = labelMap?[locale] ?? labelMap?['ar'] ?? key;
        if (labelText == key) {
          final known = _knownFieldLabels[key.toLowerCase()];
          if (known != null) {
            labelText = known[locale] ?? known['ar'] ?? key;
          }
        }
        final unitText = _knownFieldUnits[key.toLowerCase()]?[locale] ?? _knownFieldUnits[key.toLowerCase()]?['ar'];

        // Try to translate value (e.g. if it is a dropdown option ID)
        String displayValue = '';
        if (val is List) {
          final List<String> labels = [];
          for (final item in val) {
            final valMap = fieldLabels[item.toString()];
            labels.add(valMap?[locale] ?? valMap?['ar'] ?? item.toString());
          }
          displayValue = labels.join(', ');
        } else {
          final valMap = fieldLabels[val.toString()];
          displayValue = valMap?[locale] ?? valMap?['ar'] ?? val.toString();
        }

        // Specific fallbacks for bool values
        if (val == true || val.toString().toLowerCase() == 'true') {
          displayValue = locale == 'ar' ? 'نعم' : 'Yes';
        } else if (val == false || val.toString().toLowerCase() == 'false') {
          displayValue = locale == 'ar' ? 'لا' : 'No';
        }

        list.add(FormattedField(
          id: key,
          label: labelText,
          displayValue: displayValue,
          type: 'text',
          unit: unitText,
        ));
      }
    }

    return list;
  }

  static Map<String, FormattedField> formatBookingAsMap({
    required Map<String, dynamic> pricingInputs,
    required DynamicFieldSnapshot? snapshot,
    required String locale,
  }) {
    final list = formatBooking(
      pricingInputs: pricingInputs,
      snapshot: snapshot,
      locale: locale,
    );
    return {for (var f in list) f.id: f};
  }
}
