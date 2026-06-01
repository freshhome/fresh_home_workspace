import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/service/use_cases/service/get_main_services_use_case.dart';
import 'package:shared/domain/service/use_cases/service/get_bookable_services_use_case.dart';
import 'package:shared/domain/service/entities/service_entity.dart';
import 'package:shared/domain/service/enums/service_status.dart';
import 'package:shared/core/error/failures.dart';
import '../entities/home_data_entity.dart';
import '../entities/slider_entity.dart';
import '../repositories/home_repository.dart';

class GetHomeDataUseCases {
  final HomeRepository homeRepository;
  final GetMainServicesUseCase getMainServicesUseCase;
  final GetBookableServicesUseCase getBookableServicesUseCase;

  GetHomeDataUseCases(
    this.homeRepository,
    this.getMainServicesUseCase,
    this.getBookableServicesUseCase,
  );

  Stream<Either<Failure, HomeDataEntity>> call() async* {
    // 1. Fetch Sliders once
    final sliderResult = await homeRepository.getSlider();
    List<SliderEntity> sliders = [];
    
    sliderResult.fold(
      (failure) => null, // We can still show services if sliders fail
      (data) => sliders = data,
    );

    // 2. Fetch Popular Bookable Services
    final popularResult = await getBookableServicesUseCase.call(forceRefresh: false);
    List<ServiceEntity> popularServices = [];
    popularResult.fold(
      (failure) => null,
      (data) {
        popularServices = data.where((element) => element.status == ServiceStatus.active).take(5).toList();
      },
    );

    // 3. Listen to Services Stream
    yield* getMainServicesUseCase.call().map((result) {
      return result.fold(
        (failure) => Left(failure),
        (services) => Right(HomeDataEntity(
          services: services,
          sliders: sliders,
          popularServices: popularServices,
        )),
      );
    });
  }
}

