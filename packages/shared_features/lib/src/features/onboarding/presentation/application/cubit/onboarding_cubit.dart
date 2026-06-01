import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/use_cases/set_onboarding_completed_use_case.dart';

part 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final SetOnboardingCompletedUseCase _setOnboardingCompletedUseCase;
  
  OnboardingCubit(this._setOnboardingCompletedUseCase) 
      : super(const OnboardingState(currentPage: 0));

  void nextPage() {
    if (state.currentPage < 3) {
      emit(OnboardingState(currentPage: state.currentPage + 1));
    }
  }

  void updatePage(int index) {
    emit(OnboardingState(currentPage: index));
  }

  Future<void> completeOnboarding() async {
    await _setOnboardingCompletedUseCase();
  }
}
