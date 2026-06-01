import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/core/models/sync/sync_metadata_hive_model.dart';
import 'package:shared/data/booking/models/local/booking_hive_model.dart';
import 'package:shared/data/booking/models/local/order_status_hive_adapter.dart';
import 'package:shared/data/booking/models/local/sub_models/booking_components_hive_model.dart';
import 'package:shared/data/service/models/local/service_hive_model.dart';
import 'package:shared/data/service/models/local/services_updated_hive_model.dart';
import 'package:shared/data/service/models/local/sub_models/service_details_hive_model.dart';
import 'package:shared/data/service/models/local/sub_models/service_price_hive_model.dart';
import 'package:shared/data/service/models/local/pending_action_hive_model.dart';
import 'package:shared/data/user/models/remote/phone_model.dart';
import 'package:shared/data/user/models/address_model.dart';
import 'package:shared/data/user/models/local/client_profile_hive_model.dart';
import 'package:shared/data/user/models/local/technician_profile_hive_model.dart';
import 'package:shared/data/user/models/local/user_hive_model.dart';
import 'package:shared/domain/service/enums/pricing_method.dart';
import 'package:shared/domain/service/enums/service_status.dart';

class HiveInitializer {
  static const int SERVICES_CACHE_VERSION = 2; // Incremented cache version for unified Services Tree model

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(AddressModelAdapter());
    Hive.registerAdapter(UserHiveModelAdapter());

    // Services Feature Adapters
    Hive.registerAdapter(PricingMethodAdapter());
    Hive.registerAdapter(LanguageContentHiveModelAdapter());
    Hive.registerAdapter(NotIncludedHiveModelAdapter());
    Hive.registerAdapter(PriceOptionHiveModelAdapter());
    Hive.registerAdapter(PriceHiveModelAdapter());
    Hive.registerAdapter(DetailHiveModelAdapter());
    Hive.registerAdapter(ServiceHiveModelAdapter()); // Registered unified Service tree adapter
    Hive.registerAdapter(PendingActionHiveModelAdapter());
    Hive.registerAdapter(ServiceStatusAdapter());
    Hive.registerAdapter(ClientProfileHiveModelAdapter());
    Hive.registerAdapter(TechnicianProfileHiveModelAdapter());
    Hive.registerAdapter(PhoneModelAdapter());

    // Booking Core Adapters
    Hive.registerAdapter(OrderStatusAdapter());
    Hive.registerAdapter(BookedServiceHiveModelAdapter());
    Hive.registerAdapter(ContactHiveModelAdapter());
    Hive.registerAdapter(BookingPricingHiveModelAdapter());
    Hive.registerAdapter(BookingHiveModelAdapter());
    Hive.registerAdapter(ServicesUpdatedHiveModelAdapter());
    Hive.registerAdapter(SyncMetadataHiveModelAdapter());

    // Open Core Boxes
    await _openBoxSafe(HiveBoxNames.userBox);
    await _openBoxSafe(HiveBoxNames.settingsBox);
    await _openBoxSafe(HiveBoxNames.localeBox);

    // Cache versioning and Migration Check
    final settingsBox = Hive.box(HiveBoxNames.settingsBox);
    final cachedVersion = settingsBox.get('services_cache_version', defaultValue: 0) as int;
    if (cachedVersion != SERVICES_CACHE_VERSION) {
      try {
        await Hive.deleteBoxFromDisk(HiveBoxNames.servicesBox);
      } catch (_) {}
      try {
        await Hive.deleteBoxFromDisk('sub_services_box'); // Deprecated box
      } catch (_) {}
      await settingsBox.put('services_cache_version', SERVICES_CACHE_VERSION);
    }

    // Open Services Boxes
    await _openBoxSafe<ServiceHiveModel>(HiveBoxNames.servicesBox);
    await _openBoxSafe<SyncMetadataHiveModel>(HiveBoxNames.syncMetadataBox);
    await _openBoxSafe<ServicesUpdatedHiveModel>(HiveBoxNames.servicesUpdatedBox);
    await _openBoxSafe<PendingActionHiveModel>(HiveBoxNames.pendingActionsBox);
    await _openBoxSafe<BookingHiveModel>(HiveBoxNames.bookingsBox);
  }

  static Future<Box<T>> _openBoxSafe<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (_) {}
      return await Hive.openBox<T>(boxName);
    }
  }
}
