import 'package:get_it/get_it.dart';
import '../presentation/cubit/home_cubit.dart';

Future<void> initHomeDI(GetIt getIt) async {
  getIt.registerFactory(() => HomeCubit());
}
