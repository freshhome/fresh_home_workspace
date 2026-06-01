import 'package:get_it/get_it.dart';

import '../data/data_sources/pricing_governance_remote_data_source.dart';
import '../data/repositories_impl/pricing_governance_repository_impl.dart';
import '../domain/repositories/pricing_governance_repository.dart';
import '../domain/use_cases/get_governance_audit_logs_usecase.dart';
import '../domain/use_cases/get_pricing_discounts_usecase.dart';
import '../domain/use_cases/get_pricing_rules_usecase.dart';
import '../domain/use_cases/get_pricing_versions_usecase.dart';
import '../domain/use_cases/replay_booking_pricing_usecase.dart';
import '../domain/use_cases/simulate_pricing_pipeline_usecase.dart';
import '../domain/use_cases/toggle_pricing_rule_usecase.dart';
import '../domain/use_cases/upsert_pricing_discount_usecase.dart';
import '../domain/use_cases/upsert_pricing_rule_usecase.dart';
import '../presentation/cubit/pricing_governance_cubit.dart';

final sl = GetIt.instance;

void initPricingGovernance() {
  // Cubit
  sl.registerFactory(
    () => PricingGovernanceCubit(
      getRules: sl(),
      upsertRule: sl(),
      toggleRule: sl(),
      getDiscounts: sl(),
      upsertDiscount: sl(),
      getVersions: sl(),
      getAuditLogs: sl(),
      replayBooking: sl(),
      simulatePricing: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetPricingRulesUseCase(sl()));
  sl.registerLazySingleton(() => UpsertPricingRuleUseCase(sl()));
  sl.registerLazySingleton(() => TogglePricingRuleUseCase(sl()));
  sl.registerLazySingleton(() => GetPricingDiscountsUseCase(sl()));
  sl.registerLazySingleton(() => UpsertPricingDiscountUseCase(sl()));
  sl.registerLazySingleton(() => GetPricingVersionsUseCase(sl()));
  sl.registerLazySingleton(() => GetGovernanceAuditLogsUseCase(sl()));
  sl.registerLazySingleton(() => ReplayBookingPricingUseCase(sl()));
  sl.registerLazySingleton(() => SimulatePricingPipelineUseCase(sl()));

  // Repository
  sl.registerLazySingleton<PricingGovernanceRepository>(
    () => PricingGovernanceRepositoryImpl(sl()),
  );

  // Data Sources
  sl.registerLazySingleton<PricingGovernanceRemoteDataSource>(
    () => PricingGovernanceRemoteDataSourceImpl(),
  );
}
