import 'package:get_it/get_it.dart';
import 'package:shared/data/local/hive/hive_initializer.dart';

Future<void> setupHiveDI(GetIt getIt) async {
  await HiveInitializer.init();
}