import 'package:json_annotation/json_annotation.dart';

class TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const TimestampConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json is String) {
      return DateTime.parse(json);
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    // Default to epoch 0 if type is unknown or null
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  dynamic toJson(DateTime date) => date.toIso8601String();
}
