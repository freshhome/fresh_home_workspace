import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'pricing_governance_state.dart';
import '../../domain/use_cases/get_pricing_rules_usecase.dart';
import '../../domain/use_cases/upsert_pricing_rule_usecase.dart';
import '../../domain/use_cases/toggle_pricing_rule_usecase.dart';
import '../../domain/use_cases/get_pricing_discounts_usecase.dart';
import '../../domain/use_cases/upsert_pricing_discount_usecase.dart';
import '../../domain/use_cases/toggle_pricing_discount_usecase.dart';
import '../../domain/use_cases/delete_pricing_discount_usecase.dart';
import '../../domain/use_cases/get_pricing_versions_usecase.dart';
import '../../domain/use_cases/get_governance_audit_logs_usecase.dart';
import '../../domain/use_cases/replay_booking_pricing_usecase.dart';
import '../../domain/use_cases/simulate_pricing_pipeline_usecase.dart';
import '../../domain/entities/pricing_rule_entity.dart';
import '../../domain/entities/pricing_discount_entity.dart';

class PricingGovernanceCubit extends Cubit<PricingGovernanceState> {
  final GetPricingRulesUseCase _getRules;
  final UpsertPricingRuleUseCase _upsertRule;
  final TogglePricingRuleUseCase _toggleRule;
  final GetPricingDiscountsUseCase _getDiscounts;
  final UpsertPricingDiscountUseCase _upsertDiscount;
  final TogglePricingDiscountUseCase _toggleDiscount;
  final DeletePricingDiscountUseCase _deleteDiscount;
  final GetPricingVersionsUseCase _getVersions;
  final GetGovernanceAuditLogsUseCase _getAuditLogs;
  final ReplayBookingPricingUseCase _replayBooking;
  final SimulatePricingPipelineUseCase _simulatePricing;

  PricingGovernanceCubit({
    required GetPricingRulesUseCase getRules,
    required UpsertPricingRuleUseCase upsertRule,
    required TogglePricingRuleUseCase toggleRule,
    required GetPricingDiscountsUseCase getDiscounts,
    required UpsertPricingDiscountUseCase upsertDiscount,
    required TogglePricingDiscountUseCase toggleDiscount,
    required DeletePricingDiscountUseCase deleteDiscount,
    required GetPricingVersionsUseCase getVersions,
    required GetGovernanceAuditLogsUseCase getAuditLogs,
    required ReplayBookingPricingUseCase replayBooking,
    required SimulatePricingPipelineUseCase simulatePricing,
  })  : _getRules = getRules,
        _upsertRule = upsertRule,
        _toggleRule = toggleRule,
        _getDiscounts = getDiscounts,
        _upsertDiscount = upsertDiscount,
        _toggleDiscount = toggleDiscount,
        _deleteDiscount = deleteDiscount,
        _getVersions = getVersions,
        _getAuditLogs = getAuditLogs,
        _replayBooking = replayBooking,
        _simulatePricing = simulatePricing,
        super(PricingGovernanceInitial());

  Future<void> loadPricingGovernanceData(String subServiceId) async {
    emit(PricingGovernanceLoading());
    try {
      final rules = await _getRules(subServiceId);
      final discounts = await _getDiscounts();
      final versions = await _getVersions(subServiceId);

      // Audit logs are optional — fetched independently so a schema-mismatch
      // or empty-table error doesn't block loading of rules/discounts/versions.
      List<Map<String, dynamic>> auditLogs = [];
      try {
        auditLogs = await _getAuditLogs(subServiceId);
      } catch (auditError) {
        debugPrint(
          '⚠️ [PricingGovernanceCubit] Audit logs could not be loaded (non-fatal): $auditError\n'
          '   Hint: Run migration 40_fix_governance_audit_text_id.sql on Supabase if this is a UUID type error.',
        );
      }

      emit(PricingGovernanceLoaded(
        rules: rules,
        discounts: discounts,
        versions: versions,
        auditLogs: auditLogs,
      ));
    } catch (e) {
      emit(PricingGovernanceFailure('فشل تحميل بيانات الحوكمة والتسعير: $e'));
    }
  }

  Future<void> saveRule(PricingRuleEntity rule) async {
    try {
      await _upsertRule(rule);
      await loadPricingGovernanceData(rule.subServiceId);
    } catch (e) {
      emit(PricingGovernanceFailure('فشل حفظ القاعدة الشرطية: $e'));
    }
  }

  Future<void> toggleRule(String ruleId, String subServiceId, bool isActive) async {
    try {
      await _toggleRule(ruleId, isActive);
      await loadPricingGovernanceData(subServiceId);
    } catch (e) {
      emit(PricingGovernanceFailure('فشل تعديل حالة تفعيل القاعدة: $e'));
    }
  }

  Future<void> saveDiscount(PricingDiscountEntity discount, String subServiceId) async {
    try {
      await _upsertDiscount(discount);
      await loadPricingGovernanceData(subServiceId);
    } catch (e) {
      emit(PricingGovernanceFailure('فشل حفظ حملة الخصومات: $e'));
    }
  }

  Future<void> toggleDiscountActive(String discountId, String subServiceId, bool isActive) async {
    try {
      await _toggleDiscount(discountId, isActive);
      await loadPricingGovernanceData(subServiceId);
    } catch (e) {
      emit(PricingGovernanceFailure('فشل تعديل حالة تفعيل الخصم: $e'));
    }
  }

  Future<void> deleteDiscount(String discountId, String subServiceId) async {
    try {
      await _deleteDiscount(discountId);
      await loadPricingGovernanceData(subServiceId);
    } catch (e) {
      emit(PricingGovernanceFailure('فشل حذف حملة الخصومات: $e'));
    }
  }

  Future<void> replayPricing(String bookingId) async {
    emit(PricingGovernanceLoading());
    try {
      final result = await _replayBooking(bookingId);
      emit(BookingReplaySuccess(result));
    } catch (e) {
      emit(PricingGovernanceFailure('فشل تشغيل إعادة تدقيق تسعير الحجز: $e'));
    }
  }

  int _simulationRequestToken = 0;

  Future<void> simulatePricing(String subServiceId, Map<String, dynamic> inputs, List<Map<String, dynamic>> options) async {
    final currentToken = ++_simulationRequestToken;
    emit(PricingGovernanceLoading());
    try {
      final result = await _simulatePricing(subServiceId, inputs, options);
      if (currentToken != _simulationRequestToken) return;
      emit(PricingSimulationSuccess(result));
    } catch (e) {
      if (currentToken != _simulationRequestToken) return;
      debugPrint('❌ [PricingGovernanceCubit - simulatePricing Error]: $e');
      emit(PricingGovernanceFailure('فشل محاكاة التسعير: $e'));
    }
  }
}
