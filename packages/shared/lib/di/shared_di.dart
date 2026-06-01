import 'package:get_it/get_it.dart';
import 'package:shared/core/di/core_di.dart';
import 'package:shared/di/booking_di.dart';
import 'package:shared/di/counter_di.dart';
import 'package:shared/di/service_di.dart';
import 'package:shared/di/user_di.dart';
import 'package:shared/di/technician_di.dart';

Future<void> initSharedDI(GetIt getIt) async {
  // Core
  await setupCoreDI(getIt);

  // Features
  setupCounterDI(getIt);
  setupUserDI(getIt);
  setupServiceDI(getIt);
  setupBookingDI(getIt);
  setupTechnicianDI(getIt);
}
