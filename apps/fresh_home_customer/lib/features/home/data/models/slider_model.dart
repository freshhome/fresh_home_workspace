import 'package:json_annotation/json_annotation.dart';
import '../../domain/home_domain.dart';

part 'slider_model.g.dart';

@JsonSerializable()
class SliderModel  extends SliderEntity{
const  SliderModel({
  required super.image,
  required super.serviceId,
  required super.order,

  });

  factory SliderModel.fromJson(Map<String, dynamic> json) =>
      _$SliderModelFromJson(json);

  Map<String, dynamic> toJson() => _$SliderModelToJson(this);
}
