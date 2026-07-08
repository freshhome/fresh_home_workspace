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
  static List<FormattedField> formatBooking({
    required Map<String, dynamic> pricingInputs,
    required DynamicFieldSnapshot? snapshot,
    required String locale,
  }) {
    final List<FormattedField> list = [];

    // Filter metadata keys that are not input fields
    final Map<String, dynamic> filteredInputs = Map<String, dynamic>.from(pricingInputs)
      ..remove('selected_options')
      ..remove('windows')
      ..remove('__field_snapshot')
      ..remove('__field_labels');

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

        final labelText = schema.label[locale] ?? schema.label['ar'] ?? key;
        final unitText = schema.unit?[locale] ?? schema.unit?['ar'];
        String displayValue = '';

        if (schema.type == 'toggle') {
          final bool isTrue = val == true || val.toString().toLowerCase() == 'true';
          displayValue = isTrue 
              ? (locale == 'ar' ? 'نعم' : 'Yes') 
              : (locale == 'ar' ? 'لا' : 'No');
        } else if (schema.type == 'dropdown') {
          final option = schema.options?.firstWhere(
            (o) => o.id == val.toString(),
            orElse: () => SnapshotOption(id: val.toString(), label: {locale: val.toString()}),
          );
          displayValue = option?.label[locale] ?? option?.label['ar'] ?? val.toString();
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
        final labelText = labelMap?[locale] ?? labelMap?['ar'] ?? key;

        // Try to translate value (e.g. if it is a dropdown option ID)
        final valMap = fieldLabels[val.toString()];
        String displayValue = valMap?[locale] ?? valMap?['ar'] ?? val.toString();

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
          unit: null,
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
