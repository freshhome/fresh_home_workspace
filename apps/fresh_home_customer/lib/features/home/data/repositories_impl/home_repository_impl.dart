import 'package:shared/core/error/error_mapper.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/core/error/failures.dart';
import '../mappers/sliders_mapper.dart';
import '../models/slider_model.dart';
import '../sources/supabase_home_remote_data_source.dart';
import '../../domain/entities/slider_entity.dart';
import '../../domain/repositories/home_repository.dart';
import 'package:fpdart/fpdart.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remote;

  HomeRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<SliderEntity>>> getSlider() async {

    try {
      final slidersData = await _remote.getSliders();
      List<SliderEntity> sliders = [];
      if (slidersData != null && slidersData['sliders'] != null) {
        sliders = (slidersData['sliders'] as List)
            .map((e) => SlidersMapper.toSliderEntity(SliderModel.fromJson(e)))
            .toList();
      }
      return Right(sliders);
    } on SupabaseExceptionApp catch (e) {
      return Left(ErrorMapper.mapExternalServiceError(e));
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(
        UnknownFailure(message: e.toString(), code: 'unexpected_error'),
      );
    }
  }
}
