import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/get_home_data_use_cases.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetHomeDataUseCases _getHomeDataUseCase;

  HomeCubit(this._getHomeDataUseCase) : super(const HomeInitial());

  Future<void> getHomeData() async {
    emit(const HomeLoading());
    final stream = _getHomeDataUseCase.call();
    await for (final result in stream) {
      if (isClosed) return;
      result.fold(
        (failure) => emit(HomeError(failure)),
        (data) => emit(HomeDataLoaded(data)),
      );
    }
  }
}
