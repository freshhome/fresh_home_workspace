
import '../home_data.dart';
import '../../domain/home_domain.dart';

class SlidersMapper {
  static SliderModel toSliderModel(SliderEntity sliderEntity) => SliderModel(
        image: sliderEntity.image,
        serviceId: sliderEntity.serviceId,
        order: sliderEntity.order,

      );

  static SliderEntity toSliderEntity(SliderModel sliderModel) => SliderEntity(
        image: sliderModel.image,
        serviceId: sliderModel.serviceId,
        order: sliderModel.order,
      );
}
