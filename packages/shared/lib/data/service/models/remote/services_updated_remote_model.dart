import 'package:json_annotation/json_annotation.dart';
import 'package:shared/core/converters/timestamp_converter.dart';

part 'services_updated_remote_model.g.dart';

@JsonSerializable()
@TimestampConverter()
class ServicesUpdatedRemoteModel {
  final DateTime lastUpdatedAt;
  final Map<String, DateTime> services;
  final Map<String, DateTime> subServices;

  const ServicesUpdatedRemoteModel({
    required this.lastUpdatedAt,
    required this.services,
    required this.subServices,
  });

  factory ServicesUpdatedRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$ServicesUpdatedRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$ServicesUpdatedRemoteModelToJson(this);
}
