import 'package:equatable/equatable.dart';
import 'package:shared/core/error/failures.dart';
import '../../domain/entities/home_data_entity.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeDataLoaded extends HomeState {
  final HomeDataEntity homeData;

  const HomeDataLoaded(this.homeData);

  @override
  List<Object> get props => [homeData];
}

class HomeError extends HomeState {
  final Failure failure;

  const HomeError(this.failure);

  @override
  List<Object> get props => [failure];
}
