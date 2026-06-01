import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../entities/slider_entity.dart';

abstract class HomeRepository {

  Future<Either<Failure, List<SliderEntity>>> getSlider();
}

