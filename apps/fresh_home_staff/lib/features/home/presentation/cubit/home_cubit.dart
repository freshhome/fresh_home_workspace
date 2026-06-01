import 'package:flutter_bloc/flutter_bloc.dart';

abstract class HomeState {}
class HomeInitial extends HomeState {}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());
}
