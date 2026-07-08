import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/shared_features.dart';

part 'sign_out_state.dart';

class SignOutCubit extends Cubit<SignOutState> {
  final SignOutUseCase signOutUseCase;
  SignOutCubit(this.signOutUseCase) : super(SignOutInitial());

  Future<void> signOut() async {
    emit(SignOutLoading());
    final res = await signOutUseCase();
    if (isClosed) return;
    res.fold((Failure l) => emit(SignOutError(l)), (_) => emit(SignOutSuccess()));
  }
}
