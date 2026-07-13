import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import '../../data/models/dispatch_lab_scenario.dart';
import '../../domain/entities/dispatch_decision.dart';
import '../../domain/entities/virtual_technician.dart';
import '../cubit/dispatch_lab_cubit.dart';
import '../cubit/dispatch_lab_state.dart';

class DispatchLabPage extends StatelessWidget {
  const DispatchLabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DispatchLabCubit(),
      child: const DispatchLabView(),
    );
  }
}

class DispatchLabView extends StatefulWidget {
  const DispatchLabView({super.key});

  @override
  State<DispatchLabView> createState() => _DispatchLabViewState();
}

class _DispatchLabViewState extends State<DispatchLabView> {
  final TextEditingController _techNameController = TextEditingController();
  final TextEditingController _techCapacityController = TextEditingController();
  final TextEditingController _techRatingController = TextEditingController();
  final TextEditingController _customBookingCountController = TextEditingController(text: '10');

  @override
  void dispose() {
    _techNameController.dispose();
    _techCapacityController.dispose();
    _techRatingController.dispose();
    _customBookingCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        title: const Text(
          'مختبر خوارزميات التوزيع (Playground)',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: themeColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<DispatchLabCubit, DispatchLabState>(
        builder: (context, state) {
          final bodyContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Simulation Control Bar
              _buildControlBar(context, state),
              const SizedBox(height: 16),
              
              if (isDesktop)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Configuration & Rules
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            children: [
                              _buildRulesConfigurationCard(context, state),
                              const SizedBox(height: 16),
                              _buildScenarioManagementCard(context, state),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right Column: Technicians, Timeline, Stats
                      Expanded(
                        flex: 6,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            children: [
                              _buildTechniciansTableCard(context, state),
                              const SizedBox(height: 16),
                              _buildStatsAndSharesCard(context, state),
                              const SizedBox(height: 16),
                              _buildTimelineCard(context, state),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Mobile layout
                Column(
                  children: [
                    _buildRulesConfigurationCard(context, state),
                    const SizedBox(height: 16),
                    _buildScenarioManagementCard(context, state),
                    const SizedBox(height: 16),
                    _buildTechniciansTableCard(context, state),
                    const SizedBox(height: 16),
                    _buildStatsAndSharesCard(context, state),
                    const SizedBox(height: 16),
                    _buildTimelineCard(context, state),
                  ],
                ),
            ],
          );

          return isDesktop
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: bodyContent,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: bodyContent,
                );
        },
      ),
    );
  }

  // ============================================================================
  // WIDGET 1: SIMULATION CONTROLS BAR
  // ============================================================================
  Widget _buildControlBar(BuildContext context, DispatchLabState state) {
    final themeColor = context.themeColor;
    final cubit = context.read<DispatchLabCubit>();

    final double totalCap = state.technicians.where((t) => t.isActive).fold(0, (sum, t) => sum + t.dailyCapacity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Left: Run state info
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (state.currentBookingIndex >= state.bookings.length && state.bookings.isNotEmpty)
                      ? Colors.green.withValues(alpha: 0.1)
                      : state.isContinuousMode
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (state.currentBookingIndex >= state.bookings.length && state.bookings.isNotEmpty)
                      ? 'مكتمل'
                      : state.isContinuousMode
                          ? 'محاكاة مستمرة'
                          : 'جاهز',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: (state.currentBookingIndex >= state.bookings.length && state.bookings.isNotEmpty)
                        ? Colors.green
                        : state.isContinuousMode
                            ? Colors.orange
                            : themeColor.secondaryText,
                  ),
                ),
              ),
              Text(
                'الحجوزات: ${state.currentBookingIndex} / ${state.bookings.length}',
                style: TextStyle(fontWeight: FontWeight.bold, color: themeColor.textPrimary),
              ),
              Text(
                'السعة الكلية النشطة: ${totalCap.toInt()} طلب',
                style: TextStyle(color: themeColor.secondaryText, fontSize: 13),
              ),
            ],
          ),
          // Right: Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Reset Day
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'تصفير اليوم بالكامل (البداية من الصفر)',
                onPressed: () => cubit.resetDay(),
              ),
              // Replay
              IconButton(
                icon: const Icon(Icons.replay_rounded),
                tooltip: 'إعادة نفس المحاكاة خطوة بخطوة',
                onPressed: state.bookings.isEmpty ? null : () => cubit.replaySimulation(),
              ),
              const SizedBox(width: 4),
              // Next Booking Step
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('الحجز التالي'),
                onPressed: (state.currentBookingIndex >= state.bookings.length || state.isContinuousMode)
                    ? null
                    : () {
                        final dec = cubit.processNextBooking();
                        if (dec != null) {
                          _showDecisionDialog(context, dec);
                        }
                      },
              ),
              // Play/Pause Continuous
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.isContinuousMode ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: Icon(state.isContinuousMode ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(state.isContinuousMode ? 'إيقاف مؤقت' : 'تشغيل مستمر'),
                onPressed: state.bookings.isEmpty
                    ? null
                    : () {
                        if (state.isContinuousMode) {
                          cubit.stopContinuousSimulation();
                        } else {
                          cubit.startContinuousSimulation();
                        }
                      },
              ),
            ],
          )
        ],
      ),
    );
  }

  // ============================================================================
  // WIDGET 2: RULES PIPELINE CONFIGURATION
  // ============================================================================
  Widget _buildRulesConfigurationCard(BuildContext context, DispatchLabState state) {
    final themeColor = context.themeColor;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
      ),
      color: themeColor.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.settings_input_component_rounded, color: themeColor.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'إعدادات محرك القواعد (Pipeline)',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: themeColor.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 12, color: themeColor.primary),
                      const SizedBox(width: 4),
                      Text(
                        'نشط ومقفل',
                        style: TextStyle(color: themeColor.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'قواعد المحرك مقفلة برمجياً لضمان التوزيع العادل والمستقر للفنيين.',
              style: TextStyle(fontSize: 12, color: themeColor.secondaryText),
            ),
            const Divider(height: 24),
            
            // Filters section
            Text(
              '1. مرحلة التصفية (Filtering):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: themeColor.textPrimary),
            ),
            const SizedBox(height: 8),
            if (state.activeFilterRules.isEmpty)
              Text('لا توجد قواعد تصفية نشطة.', style: TextStyle(fontSize: 12, color: themeColor.secondaryText))
            else
              ...state.activeFilterRules.map((filter) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 18),
                  title: Text(filter.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(filter.description, style: TextStyle(fontSize: 11, color: themeColor.secondaryText)),
                );
              }),
            
            const Divider(height: 24),
            
            // Rankings section
            Text(
              '2. مرحلة الترتيب (Ranking - بالترتيب):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: themeColor.textPrimary),
            ),
            const SizedBox(height: 8),
            
            if (state.activeRankingRules.isEmpty)
              Text('لا توجد قواعد ترتيب نشطة.', style: TextStyle(fontSize: 12, color: themeColor.secondaryText))
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(12),
                  color: themeColor.nestedCardBackground,
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: List.generate(state.activeRankingRules.length, (index) {
                    final rule = state.activeRankingRules[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: themeColor.primary.withValues(alpha: 0.1),
                          child: Text('${index + 1}', style: TextStyle(color: themeColor.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(rule.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(rule.description, style: TextStyle(fontSize: 10, color: themeColor.secondaryText)),
                      ),
                    );
                  }),
                ),
              ),

            const Divider(height: 24),
            
            // Tie-breaking section
            Text(
              '3. كسر التعادل النهائي (Tie Breaking):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: themeColor.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: themeColor.nestedCardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shuffle_rounded, color: themeColor.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.activeTieBreaker.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          'يستخدم لكسر التعادل عشوائياً عند التساوي التام في معايير الفرز.',
                          style: TextStyle(fontSize: 10, color: themeColor.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // WIDGET 3: SCENARIO MANAGEMENT
  // ============================================================================
  Widget _buildScenarioManagementCard(BuildContext context, DispatchLabState state) {
    final themeColor = context.themeColor;
    final cubit = context.read<DispatchLabCubit>();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
      ),
      color: themeColor.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science_rounded, color: themeColor.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'إدارة سيناريوهات الفحص والتشغيل',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor.textPrimary),
                ),
              ],
            ),
            const Divider(height: 24),
            // Scenario loading
            Text('تحميل سيناريو جاهز:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: themeColor.textPrimary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<DispatchLabScenario>(
              value: state.currentScenarioName != null
                  ? state.savedScenarios.firstWhere((s) => s.name == state.currentScenarioName, orElse: () => state.savedScenarios.first)
                  : null,
              hint: const Text('اختر سيناريو لتشغيله', style: TextStyle(fontSize: 13)),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: state.savedScenarios.map((scen) {
                return DropdownMenuItem<DispatchLabScenario>(
                  value: scen,
                  child: Text(scen.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: (scen) {
                if (scen != null) {
                  cubit.loadScenario(scen);
                }
              },
            ),
            
            const Divider(height: 24),
            
            // Booking generation controls
            Text('توليد الحجوزات يدوياً:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: themeColor.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor.nestedCardBackground,
                      foregroundColor: themeColor.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => cubit.generateBookings(10),
                    child: const Text('10 طلبات', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor.nestedCardBackground,
                      foregroundColor: themeColor.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => cubit.generateBookings(50),
                    child: const Text('50 طلب', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor.nestedCardBackground,
                      foregroundColor: themeColor.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => cubit.generateBookings(100),
                    child: const Text('100 طلب', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _customBookingCountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'عدد مخصص',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor.primary.withValues(alpha: 0.1),
                      foregroundColor: themeColor.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final val = int.tryParse(_customBookingCountController.text) ?? 10;
                      cubit.generateBookings(val);
                    },
                    child: const Text('توليد وتصفير', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Save Scenario name
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      foregroundColor: Colors.blue.shade800,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('حفظ الإعدادات الحالية كسيناريو جديد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showSaveScenarioDialog(context, cubit),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // WIDGET 4: VIRTUAL TECHNICIANS STATS TABLE
  // ============================================================================
  Widget _buildTechniciansTableCard(BuildContext context, DispatchLabState state) {
    final themeColor = context.themeColor;
    final cubit = context.read<DispatchLabCubit>();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
      ),
      color: themeColor.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.engineering_rounded, color: themeColor.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'إدارة بيانات الفنيين الافتراضيين',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor.textPrimary),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAddTechDialog(context, cubit),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة فني', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const Divider(height: 16),
            
            // Technicians scrollable list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.technicians.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final tech = state.technicians[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeColor.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: themeColor.unselectedItem.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Switch(
                              value: tech.isActive,
                              activeColor: themeColor.primary,
                              onChanged: (val) => cubit.toggleTechnicianActive(tech.id),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tech.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: tech.isActive ? themeColor.textPrimary : themeColor.secondaryText,
                                  decoration: tech.isActive ? null : TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // 1. Rating (نجمة وتحتها القيمة)
                                Column(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${tech.rating}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: themeColor.textPrimary),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                // 2. Capacity (أيقونة السعة وتحتها القيمة)
                                Column(
                                  children: [
                                    const Icon(Icons.flash_on_rounded, color: Colors.blue, size: 20),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${tech.dailyCapacity}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: themeColor.textPrimary),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                // 3. Occupancy (أيقونة الإشغال وتحتها القيمة)
                                Column(
                                  children: [
                                    Icon(
                                      Icons.donut_large_rounded, 
                                      color: tech.utilization > 1.0
                                          ? Colors.red
                                          : tech.utilization == 1.0
                                              ? Colors.green
                                              : themeColor.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${tech.currentOrders}/${tech.dailyCapacity}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: themeColor.textPrimary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, size: 20),
                                  color: themeColor.primary,
                                  onPressed: () => _showEditTechDialog(context, cubit, tech),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: themeColor.error, size: 20),
                                  onPressed: () => cubit.removeTechnician(tech.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (tech.lastAssignedOrderIndex != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'آخر طلب تم تعيينه: الحجز رقم ${tech.lastAssignedOrderIndex}',
                            style: TextStyle(fontSize: 10, color: themeColor.secondaryText),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // WIDGET 5: STAS AND COMPARATIVE SHARES
  // ============================================================================
  Widget _buildStatsAndSharesCard(BuildContext context, DispatchLabState state) {
    final themeColor = context.themeColor;
    
    final int totalBookingsProcessed = state.history.length;
    
    // Sum of capacities for expected share
    final int sumCapacities = state.technicians.where((t) => t.isActive).fold(0, (sum, t) => sum + t.dailyCapacity);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
      ),
      color: themeColor.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: themeColor.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'مقارنة الحصص التوزيعية (Expected vs Actual Share)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'يقارن الحصة الفعلية (التي تعينت للفني) بالحصة المتوقعة (بناءً على سعته الكلية النشطة).',
              style: TextStyle(fontSize: 12, color: themeColor.secondaryText),
            ),
            const Divider(height: 20),
            
            if (totalBookingsProcessed == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'قم بتشغيل المحاكاة لرؤية إحصائيات الحصص والعدالة التوزيعية.',
                    style: TextStyle(color: themeColor.secondaryText, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.technicians.length,
                itemBuilder: (context, index) {
                  final tech = state.technicians[index];
                  
                  // Expected Share %
                  final double expectedPct = (sumCapacities == 0 || !tech.isActive) 
                      ? 0.0 
                      : (tech.dailyCapacity / sumCapacities) * 100;
                  
                  // Actual Share %
                  final double actualPct = (totalBookingsProcessed == 0)
                      ? 0.0
                      : (tech.currentOrders / totalBookingsProcessed) * 100;

                  // Difference
                  final double diff = actualPct - expectedPct;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tech.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 13,
                                color: tech.isActive ? themeColor.textPrimary : themeColor.secondaryText,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'الفروقات: ',
                                  style: TextStyle(fontSize: 11, color: themeColor.secondaryText),
                                ),
                                Text(
                                  '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12, 
                                    fontWeight: FontWeight.bold,
                                    color: diff.abs() < 5.0
                                        ? Colors.green
                                        : diff > 0
                                            ? Colors.blue.shade700 // overallocation
                                            : Colors.orange.shade700, // underallocation
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Double progress bar: Top bar expected, Bottom bar actual
                        Column(
                          children: [
                            // Expected
                            Row(
                              children: [
                                SizedBox(
                                  width: 90, 
                                  child: Text('المتوقعة (${expectedPct.toStringAsFixed(1)}%):', style: TextStyle(fontSize: 10, color: themeColor.secondaryText))
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: expectedPct / 100,
                                      backgroundColor: themeColor.unselectedItem.withValues(alpha: 0.05),
                                      color: Colors.purple.shade400,
                                      minHeight: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            // Actual
                            Row(
                              children: [
                                SizedBox(
                                  width: 90, 
                                  child: Text('الفعلية (${actualPct.toStringAsFixed(1)}%):', style: TextStyle(fontSize: 10, color: themeColor.secondaryText))
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: actualPct / 100,
                                      backgroundColor: themeColor.unselectedItem.withValues(alpha: 0.05),
                                      color: themeColor.primary,
                                      minHeight: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // WIDGET 6: SIMULATION TIMELINE
  // ============================================================================
  Widget _buildTimelineCard(BuildContext context, DispatchLabState state) {
    final themeColor = context.themeColor;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
      ),
      color: themeColor.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timeline_rounded, color: themeColor.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'سجل توزيع الحجوزات (Timeline)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor.textPrimary),
                    ),
                  ],
                ),
                if (state.history.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: themeColor.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('طباعة السجل في الكونسول'),
                    onPressed: () => _printHistoryToConsole(state),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'اضغط على أي حجز لعرض لوحة القرار المفصلة (Decision Inspector).',
              style: TextStyle(fontSize: 12, color: themeColor.secondaryText),
            ),
            const Divider(height: 20),
            
            if (state.history.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'لا يوجد حركات توزيع بعد.',
                    style: TextStyle(color: themeColor.secondaryText, fontSize: 13),
                  ),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: state.history.length,
                  itemBuilder: (context, index) {
                    // Show in reverse order (newest first)
                    final decision = state.history[state.history.length - 1 - index];
                    final isAssigned = decision.selectedTechnician != null;

                    return Card(
                      elevation: 0,
                      color: themeColor.nestedCardBackground,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: themeColor.unselectedItem.withValues(alpha: 0.05)),
                      ),
                      child: InkWell(
                        onTap: () => _showDecisionDialog(context, decision),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: isAssigned ? themeColor.primary : themeColor.error,
                                child: Text(
                                  '#${decision.booking.sequenceNumber}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'حجز ${decision.booking.serviceName}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          isAssigned ? 'المُسند: ${decision.selectedTechnician!.name}' : 'فشل التعيين',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isAssigned ? themeColor.primary : themeColor.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      decision.reason,
                                      style: TextStyle(fontSize: 11, color: themeColor.secondaryText),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: themeColor.secondaryText),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // DIALOGS & PANELS
  // ============================================================================

  void _showAddTechDialog(BuildContext context, DispatchLabCubit cubit) {
    final count = cubit.state.technicians.length;
    final nextLetter = String.fromCharCode(65 + (count % 26)) + (count >= 26 ? '${(count / 26).floor() + 1}' : '');
    _techNameController.text = nextLetter;
    _techCapacityController.text = '${count + 1}';
    _techRatingController.text = '4.5';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة فني افتراضي جديد', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _techNameController,
                decoration: const InputDecoration(labelText: 'اسم الفني'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _techCapacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السعة اليومية للعمل (أوردر/يوم)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _techRatingController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'التقييم (من 0 إلى 5)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _techNameController.text.trim();
                final capacity = int.tryParse(_techCapacityController.text) ?? 5;
                final rating = double.tryParse(_techRatingController.text) ?? 4.5;
                if (name.isNotEmpty) {
                  cubit.addTechnician(name, capacity, rating);
                  Navigator.pop(context);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTechDialog(BuildContext context, DispatchLabCubit cubit, VirtualTechnician tech) {
    _techNameController.text = tech.name;
    _techCapacityController.text = tech.dailyCapacity.toString();
    _techRatingController.text = tech.rating.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تعديل بيانات الفني: ${tech.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _techNameController,
                decoration: const InputDecoration(labelText: 'الاسم الجديد'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _techCapacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السعة اليومية للعمل'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _techRatingController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'التقييم الحالي'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _techNameController.text.trim();
                final capacity = int.tryParse(_techCapacityController.text) ?? tech.dailyCapacity;
                final rating = double.tryParse(_techRatingController.text) ?? tech.rating;
                if (name.isNotEmpty) {
                  cubit.updateTechnician(tech.copyWith(
                    name: name,
                    dailyCapacity: capacity,
                    rating: rating,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('حفظ التعديلات'),
            ),
          ],
        );
      },
    );
  }

  void _showSaveScenarioDialog(BuildContext context, DispatchLabCubit cubit) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حفظ كسيناريو مخصص', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'اسم السيناريو الجديد',
              hintText: 'مثال: توزيع عادل - 5 فنيين',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  cubit.saveScenario(name);
                  Navigator.pop(context);
                }
              },
              child: const Text('حفظ السيناريو'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // WIDGET 7: DECISION INSPECTOR DIALOG
  // ============================================================================
  void _showDecisionDialog(BuildContext context, DispatchDecision decision) {
    final themeColor = context.themeColor;
    final isAssigned = decision.selectedTechnician != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: themeColor.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: themeColor.unselectedItem.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'فحص القرار بالتفصيل (Decision Inspector)',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: themeColor.textPrimary),
                            ),
                            Text(
                              'للحجز #${decision.booking.sequenceNumber} - خدمة ${decision.booking.serviceName}',
                              style: TextStyle(color: themeColor.secondaryText, fontSize: 12),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),
                  const Divider(),
                  
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      children: [
                        // Outcome Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isAssigned 
                                ? themeColor.primary.withValues(alpha: 0.08)
                                : themeColor.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isAssigned 
                                  ? themeColor.primary.withValues(alpha: 0.15)
                                  : themeColor.error.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAssigned 
                                    ? 'الفائز بالطلب: ${decision.selectedTechnician!.name}'
                                    : 'لم يتم تعيين فائز للطلب',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isAssigned ? themeColor.primary : themeColor.error,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                decision.reason,
                                style: TextStyle(fontSize: 13, color: themeColor.textPrimary, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Technicians Evaluation Pipeline Table
                        Text(
                          'تتبع تقييم الفنيين خطوة بخطوة:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: themeColor.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(themeColor.nestedCardBackground),
                            columns: const [
                              DataColumn(label: Text('اسم الفني', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('السعة المتبقية', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('نسبة الإشغال', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('التقييم', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('الانتظار', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('تتبع القرار والترتيب', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: decision.technicianDetails.map((details) {
                              final isWinner = isAssigned && details.technicianId == decision.selectedTechnician!.id;
                              
                              return DataRow(
                                color: WidgetStateProperty.resolveWith<Color?>((states) {
                                  if (isWinner) return themeColor.primary.withValues(alpha: 0.05);
                                  if (details.isExcluded) return Colors.red.withValues(alpha: 0.02);
                                  return null;
                                }),
                                cells: [
                                  // Name
                                  DataCell(
                                    Row(
                                      children: [
                                        if (isWinner)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 6.0),
                                            child: Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 18),
                                          ),
                                        Text(
                                          details.name,
                                          style: TextStyle(
                                            fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                                            color: details.isExcluded ? themeColor.secondaryText : themeColor.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status
                                  DataCell(
                                    Text(
                                      details.isExcluded ? 'مستبعد' : 'مؤهل (رقم ${details.finalRank})',
                                      style: TextStyle(
                                        color: details.isExcluded ? themeColor.error : Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  // Capacity
                                  DataCell(Text('${details.dailyCapacity - details.currentOrders} / ${details.dailyCapacity}')),
                                  // Utilization
                                  DataCell(Text('${(details.utilization * 100).toStringAsFixed(0)}%')),
                                  // Rating
                                  DataCell(Text('${details.rating} ★')),
                                  // Idle Time
                                  DataCell(
                                    Text(
                                      details.lastAssignedOrderIndex == null 
                                          ? 'من البداية' 
                                          : 'أوردر #${details.lastAssignedOrderIndex}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  // Explanation
                                  DataCell(
                                    Container(
                                      constraints: const BoxConstraints(maxWidth: 320),
                                      child: Text(
                                        details.isExcluded 
                                            ? 'مستبعد: ${details.exclusionReason}' 
                                            : details.rankReason,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isWinner ? themeColor.primary : themeColor.textPrimary,
                                          fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _printHistoryToConsole(DispatchLabState state) {
    final buffer = StringBuffer();
    buffer.writeln('================================================================================');
    buffer.writeln('DISPATCH SIMULATION HISTORY LOG');
    buffer.writeln('Scenario: ${state.currentScenarioName ?? "Custom Run"}');
    buffer.writeln('Total Bookings Processed: ${state.history.length}');
    buffer.writeln('Active Filters: ${state.activeFilterRules.map((f) => f.name).join(", ")}');
    buffer.writeln('Active Rankings: ${state.activeRankingRules.map((r) => r.name).join(" -> ")}');
    buffer.writeln('Tie Breaker: ${state.activeTieBreaker.name}');
    buffer.writeln('================================================================================');
    buffer.writeln();

    // 1. Technicians General Summary
    buffer.writeln('================================================================================');
    buffer.writeln('TECHNICIANS GENERAL SUMMARY (ملخص الفنيين العام)');
    buffer.writeln('================================================================================');
    buffer.writeln('Number of Active Technicians: ${state.technicians.where((t) => t.isActive).length}');
    for (final tech in state.technicians) {
      buffer.writeln('* ${tech.name} (ID: ${tech.id}): Capacity = ${tech.dailyCapacity}, Rating = ${tech.rating.toStringAsFixed(1)} نجوم, Active = ${tech.isActive}');
    }
    buffer.writeln('================================================================================');
    buffer.writeln();

    // 2. Entire Distribution Sequence Order
    buffer.writeln('================================================================================');
    buffer.writeln('DISTRIBUTION SEQUENCE ORDER (ترتيب التوزيع بالكامل):');
    buffer.writeln('================================================================================');
    final sequence = state.history.map((dec) {
      final winner = dec.selectedTechnician;
      return winner != null ? winner.name : 'تعذر التوزيع';
    }).toList();
    buffer.writeln('Sequence: ${sequence.join(" -> ")}');
    buffer.writeln('================================================================================');
    buffer.writeln();

    for (final decision in state.history) {
      final booking = decision.booking;
      final winner = decision.selectedTechnician;

      buffer.writeln('--------------------------------------------------------------------------------');
      buffer.writeln('الحجز #${booking.sequenceNumber}: ${booking.serviceName}');
      buffer.writeln('--------------------------------------------------------------------------------');
      if (winner != null) {
        final details = decision.technicianDetails.firstWhere((d) => d.technicianId == winner.id);
        final int ordersAfter = details.currentOrders + 1;
        final int remainingAfter = details.dailyCapacity - ordersAfter;
        buffer.writeln('- الفائز: ${winner.name} (ID: ${winner.id})');
        buffer.writeln('- السبب: ${decision.reason}');
        buffer.writeln('- حالة الفني بعد التعيين: الحجز رقم [$ordersAfter] للفني، المتبقي له [$remainingAfter] طلب (من أصل [${details.dailyCapacity}] سعة كلية).');
      } else {
        buffer.writeln('- النتيجة: تعذر التوزيع');
        buffer.writeln('- السبب: ${decision.reason}');
      }
      buffer.writeln();
    }

    buffer.writeln('================================================================================');
    buffer.writeln('FINAL SIMULATION STATISTICS');
    buffer.writeln('================================================================================');
    
    final int sumCapacities = state.technicians.where((t) => t.isActive).fold(0, (sum, t) => sum + t.dailyCapacity);
    final int totalProcessed = state.history.length;

    for (final tech in state.technicians) {
      final double expectedPct = (sumCapacities == 0 || !tech.isActive) ? 0.0 : (tech.dailyCapacity / sumCapacities) * 100;
      final double actualPct = totalProcessed == 0 ? 0.0 : (tech.currentOrders / totalProcessed) * 100;
      final double diff = actualPct - expectedPct;

      buffer.writeln('* ${tech.name} (Active: ${tech.isActive}):');
      buffer.writeln('  - Orders: ${tech.currentOrders}/${tech.dailyCapacity} (Utilization: ${(tech.utilization * 100).toStringAsFixed(0)}%)');
      buffer.writeln('  - Expected Share: ${expectedPct.toStringAsFixed(1)}%');
      buffer.writeln('  - Actual Share: ${actualPct.toStringAsFixed(1)}%');
      buffer.writeln('  - Difference: ${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)}%');
    }
    buffer.writeln('================================================================================');

    debugPrint(buffer.toString());
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمت طباعة السجل الكامل بنجاح في كونسول المطورين (Console)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
