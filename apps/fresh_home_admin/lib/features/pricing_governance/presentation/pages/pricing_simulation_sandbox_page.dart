import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/presentation/presentation.dart';
import '../cubit/pricing_governance_cubit.dart';
import '../cubit/pricing_governance_state.dart';

class PricingSimulationSandboxPage extends StatefulWidget {
  final String subServiceId;

  const PricingSimulationSandboxPage({super.key, required this.subServiceId});

  @override
  State<PricingSimulationSandboxPage> createState() => _PricingSimulationSandboxPageState();
}

class _PricingSimulationSandboxPageState extends State<PricingSimulationSandboxPage> {
  double _areaValue = 150.0;
  bool _isFurnished = false;
  double _linearMetersValue = 0.0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Trigger initial simulation on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSimulation();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSliderChanged(VoidCallback setVal) {
    setVal();
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _runSimulation();
    });
  }

  void _onSwitchChanged(bool value) {
    setState(() => _isFurnished = value);
    _debounceTimer?.cancel();
    _runSimulation();
  }

  void _runSimulation() {
    final inputs = {
      'area': _areaValue,
      'furnished': _isFurnished,
      'total_linear_meters': _linearMetersValue,
    };
    context.read<PricingGovernanceCubit>().simulatePricing(widget.subServiceId, inputs, []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('محاكي التسعير السحابي (Sandbox)', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;

            if (isMobile) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInputsCard(isMobile: true),
                    const SizedBox(height: 16),
                    _buildResultsPanel(isMobile: true),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Inputs Panel
                  Expanded(
                    flex: 1,
                    child: _buildInputsCard(isMobile: false),
                  ),
                  const SizedBox(width: 20),
                  // Results Panel
                  Expanded(
                    flex: 2,
                    child: _buildResultsPanel(isMobile: false),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputsCard({required bool isMobile}) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('معطيات الحجز الافتراضي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        const SizedBox(height: 16),
        // ── Area Slider ───────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('المساحة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_areaValue.toStringAsFixed(0)} م²',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo.shade700),
              ),
            ),
          ],
        ),
        Slider(
          value: _areaValue,
          min: 50,
          max: 500,
          divisions: 45,
          activeColor: Colors.indigo.shade400,
          label: '${_areaValue.toStringAsFixed(0)} م²',
          onChanged: (v) => _onSliderChanged(() => setState(() => _areaValue = v)),
        ),
        const SizedBox(height: 8),
        // ── Furnished Toggle ──────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: _isFurnished ? Colors.amber.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isFurnished ? Colors.amber.shade200 : Colors.grey.shade200),
          ),
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(
              _isFurnished ? 'مفروش ✅' : 'غير مفروش',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: _isFurnished ? Colors.amber.shade800 : Colors.grey.shade700,
              ),
            ),
            value: _isFurnished,
            activeThumbColor: Colors.amber.shade700,
            onChanged: _onSwitchChanged,
          ),
        ),
        const SizedBox(height: 16),
        // ── Linear Meters Slider ──────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text('المتر الطولي', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_linearMetersValue.toStringAsFixed(1)} م',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade700),
              ),
            ),
          ],
        ),
        Slider(
          value: _linearMetersValue,
          min: 0,
          max: 50,
          divisions: 50,
          activeColor: Colors.teal.shade400,
          label: '${_linearMetersValue.toStringAsFixed(1)} م',
          onChanged: (v) => _onSliderChanged(() => setState(() => _linearMetersValue = v)),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _runSimulation,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('تشغيل المحاكاة السحابية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isMobile ? content : SingleChildScrollView(child: content),
      ),
    );
  }

  Widget _buildResultsPanel({required bool isMobile}) {
    return BlocConsumer<PricingGovernanceCubit, PricingGovernanceState>(
      listener: (context, state) {
        if (state is PricingGovernanceFailure) {
          debugPrint('❌ [PricingSimulationError]: ${state.message}');
        }
      },
      builder: (context, state) {
        if (state is PricingGovernanceLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is PricingSimulationSuccess) {
          final result = state.simulationResult;
          return _buildSimulationResult(result, isMobile: isMobile);
        }

        if (state is PricingGovernanceFailure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(state.message, style: const TextStyle(color: Colors.red, fontFamily: 'Cairo'), textAlign: TextAlign.center),
            ),
          );
        }

        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text(
              'أدخل المعطيات واضغط على "تشغيل المحاكاة السحابية" لرؤية تفاصيل التسعير الفعلي.',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimulationResult(Map<String, dynamic> result, {required bool isMobile}) {
    final metadata = result['metadata'] as Map<String, dynamic>? ?? {};
    
    final basePriceVal = (result['basePrice'] ?? result['base_price'] ?? 0.0).toDouble();
    final extraFeesVal = (result['extraFees'] ?? result['extra_fees'] ?? 0.0).toDouble();
    final discountVal = (result['discount'] ?? 0.0).toDouble();
    final totalVal = (result['total'] ?? 0.0).toDouble();
    
    final subtotalVal = (metadata['subtotal'] ?? result['subtotal'] ?? basePriceVal).toDouble();
    final trace = (metadata['execution_trace'] ?? result['execution_trace']) as List? ?? [];
    final appliedDiscounts = (metadata['applied_discounts'] ?? result['applied_discounts']) as List? ?? [];

    // Calculate technician commission / payout split
    final baseCommissionableAmount = subtotalVal + extraFeesVal;
    final platformCommissionVal = baseCommissionableAmount * 0.20;
    final bonusesVal = 0.0; // default 0
    final technicianPayoutVal = (baseCommissionableAmount * 0.80) + bonusesVal;
    final netProfitVal = totalVal - technicianPayoutVal;
    final globalCapHitVal = subtotalVal > 0 ? (discountVal / subtotalVal) >= 0.299 : false;

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PricingSummaryCards(
          customerPrice: totalVal,
          technicianPayout: technicianPayoutVal,
          netProfit: netProfitVal,
          discountImpact: discountVal,
          globalCapHit: globalCapHitVal,
        ),
        const SizedBox(height: 16),
        isMobile
            ? Column(
                children: [
                  ProfitPreviewCard(
                    customerPrice: totalVal,
                    technicianPayout: technicianPayoutVal,
                    discountImpact: discountVal,
                    netProfit: netProfitVal,
                  ),
                  const SizedBox(height: 16),
                  TechnicianPayoutPreviewCard(
                    customerPrice: totalVal,
                    technicianPayout: technicianPayoutVal,
                    platformCommission: platformCommissionVal,
                    bonuses: bonusesVal,
                    promosAbsorbed: discountVal,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ProfitPreviewCard(
                      customerPrice: totalVal,
                      technicianPayout: technicianPayoutVal,
                      discountImpact: discountVal,
                      netProfit: netProfitVal,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TechnicianPayoutPreviewCard(
                      customerPrice: totalVal,
                      technicianPayout: technicianPayoutVal,
                      platformCommission: platformCommissionVal,
                      bonuses: bonusesVal,
                      promosAbsorbed: discountVal,
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 16),
        DiscountImpactCard(
          discountAmount: discountVal,
          subtotal: subtotalVal,
          appliedCampaigns: appliedDiscounts,
          globalCapHit: globalCapHitVal,
        ),
        const SizedBox(height: 16),
        SimulationStageTimeline(executionTrace: trace),
      ],
    );

    return isMobile ? column : SingleChildScrollView(child: column);
  }
}
