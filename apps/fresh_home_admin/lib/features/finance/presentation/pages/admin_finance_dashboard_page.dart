import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared/shared.dart';
import '../../domain/entities/admin_technician_account.dart';
import '../cubit/admin_finance_cubit.dart';
import '../cubit/admin_finance_state.dart';
import '../cubit/admin_reports_cubit.dart';
import '../cubit/admin_reports_state.dart';
import '../../domain/entities/admin_settlement_request.dart';
import '../../domain/entities/admin_financial_case.dart';

typedef ThemeColor = ThemeColorExtension;

class AdminFinanceDashboardPage extends StatefulWidget {
  const AdminFinanceDashboardPage({super.key});

  @override
  State<AdminFinanceDashboardPage> createState() => _AdminFinanceDashboardPageState();
}

class _AdminFinanceDashboardPageState extends State<AdminFinanceDashboardPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedTechnicianId;
  String _selectedAdjustmentType = 'bonus';

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final l10n = AppLocalizations.of(context)!;
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: themeColor.background,
        appBar: AppBar(
          title: Text(
            l10n.admin_finance_title,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: themeColor.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
            tabs: [
              Tab(text: l10n.admin_finance_tab_settlements),
              Tab(text: l10n.admin_finance_tab_balances),
              Tab(text: l10n.admin_finance_tab_adjustments),
              Tab(text: l10n.admin_finance_tab_cases),
              Tab(text: l10n.admin_finance_tab_reports),
            ],
          ),
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocConsumer<AdminFinanceCubit, AdminFinanceState>(
            listenWhen: (previous, current) => current is AdminFinanceActionSuccess || current is AdminFinanceError,
            listener: (context, state) {
              if (state is AdminFinanceActionSuccess) {
                String msg = '';
                if (state.message == 'settlement_approved_success') {
                  msg = 'تمت الموافقة على طلب التسوية وتحديث الحسابات بنجاح.';
                } else if (state.message == 'settlement_rejected_success') {
                  msg = 'تم رفض طلب التسوية بنجاح.';
                } else if (state.message == 'financial_case_resolved_success') {
                  msg = l10n.admin_finance_success_resolve;
                } else if (state.message == 'adjustment_created_success') {
                  msg = l10n.admin_finance_success_adjustment;
                } else if (state.message == 'admin_finance_success_debt') {
                  msg = l10n.admin_finance_success_debt;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: Colors.green,
                  ),
                );
                // Clear Form after successful adjustment
                if (state.message == 'adjustment_created_success') {
                  _amountController.clear();
                  _reasonController.clear();
                  _notesController.clear();
                  setState(() {
                    _selectedTechnicianId = null;
                    _selectedAdjustmentType = 'bonus';
                  });
                }
              } else if (state is AdminFinanceError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            buildWhen: (previous, current) =>
                current is AdminFinanceLoading ||
                current is AdminFinanceLoaded ||
                (current is AdminFinanceError && previous is AdminFinanceInitial),
            builder: (context, state) {
              if (state is AdminFinanceLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is AdminFinanceError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 72, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.read<AdminFinanceCubit>().loadFinancialData(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (state is AdminFinanceLoaded) {
                return Stack(
                  children: [
                    TabBarView(
                      children: [
                        _buildSettlementTab(context, state, themeColor, l10n, isMobile),
                        _buildBalancesTab(context, state, themeColor, l10n, isMobile),
                        _buildAdjustmentTab(context, state, themeColor, l10n, isMobile),
                        _buildCasesTab(context, state, themeColor, l10n, isMobile),
                        _buildReportsTab(context, themeColor, l10n, isMobile),
                      ],
                    ),
                    if (state.isActionInProgress)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  // ── Settlements Tab ────────────────────────────────────────────────────────
  Widget _buildSettlementTab(
    BuildContext context,
    AdminFinanceLoaded state,
    ThemeColor themeColor,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    final pendingRequests = state.settlementRequests.where((r) => r.status == 'pending').toList();
    final historyRequests = state.settlementRequests.where((r) => r.status != 'pending').toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('الطلبات المعلقة (${pendingRequests.length})', Icons.pending_actions_rounded, themeColor),
          const SizedBox(height: 12),
          isMobile
              ? _buildSettlementCards(context, pendingRequests, true, themeColor, l10n, state.technicianAccounts)
              : _buildSettlementTable(context, pendingRequests, true, themeColor, l10n, state.technicianAccounts),
          const SizedBox(height: 32),
          _buildSectionHeader('سجل طلبات التسوية المعالجة', Icons.history_toggle_off_rounded, themeColor),
          const SizedBox(height: 12),
          isMobile
              ? _buildSettlementCards(context, historyRequests, false, themeColor, l10n, state.technicianAccounts)
              : _buildSettlementTable(context, historyRequests, false, themeColor, l10n, state.technicianAccounts),
        ],
      ),
    );
  }

  Widget _buildSettlementCards(
    BuildContext context,
    List<AdminSettlementRequest> requests,
    bool isPending,
    ThemeColor themeColor,
    AppLocalizations l10n,
    List<AdminTechnicianAccount> accounts,
  ) {
    if (requests.isEmpty) {
      return Card(
        color: themeColor.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  isPending ? 'لا توجد طلبات تسوية معلقة حالياً.' : 'سجل تسويات فارغ.',
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final request = requests[index];
        final isPayment = request.requestType == 'payment';
        final String initials = request.technicianName.isNotEmpty
            ? request.technicianName.trim().split(' ').map((e) => e.isEmpty ? '' : e[0]).take(2).join()
            : 'F';

        return Container(
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: themeColor.primary.withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: themeColor.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(
                request.technicianName,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${request.amount.toStringAsFixed(2)} ج.م',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: themeColor.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isPayment ? Colors.green.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isPayment ? Colors.green.shade200 : Colors.blue.shade200),
                      ),
                      child: Text(
                        isPayment ? 'سداد مديونية' : 'سحب مستحقات',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isPayment ? Colors.green.shade700 : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(request.status, themeColor),
                  const SizedBox(height: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
                ],
              ),
              children: [
                const Divider(height: 1, indent: 14, endIndent: 14, color: Colors.black12),
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('طريقة التحويل:', _getSettlementMethodText(request.method, l10n)),
                      const SizedBox(height: 6),
                      _buildDetailRow('تاريخ الطلب:', DateFormat('yyyy/MM/dd HH:mm').format(request.createdAt)),
                      if (request.adminNotes != null && request.adminNotes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildDetailRow('ملاحظات الإدارة:', request.adminNotes!),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (request.proofImageUrl.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () => _viewProofDialog(context, request.proofImageUrl, themeColor),
                              icon: const Icon(Icons.receipt_long_rounded, size: 14),
                              label: Text(l10n.admin_finance_btn_view_proof, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                                foregroundColor: Colors.blue.shade800,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          if (request.adminProofUrl != null) ...[
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              onPressed: () => _viewProofDialog(context, request.adminProofUrl!, themeColor, title: l10n.finance_admin_proof_label),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                              label: Text(l10n.finance_admin_proof_label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade50,
                                foregroundColor: Colors.green.shade800,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                          if (isPending) ...[
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              onPressed: () => _confirmApproveSettlement(context, request, accounts),
                              icon: const Icon(Icons.check_circle_rounded, size: 14),
                              label: Text(l10n.admin_finance_btn_approve, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              onPressed: () => _rejectSettlementDialog(context, request, themeColor),
                              icon: const Icon(Icons.cancel_rounded, size: 14),
                              label: Text(l10n.admin_finance_btn_reject, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementTable(
    BuildContext context,
    List<AdminSettlementRequest> requests,
    bool isPending,
    ThemeColor themeColor,
    AppLocalizations l10n,
    List<AdminTechnicianAccount> accounts,
  ) {
    if (requests.isEmpty) {
      return Card(
        color: themeColor.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  isPending ? 'لا توجد طلبات تسوية معلقة حالياً.' : 'سجل تسويات فارغ.',
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      color: themeColor.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 360,
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 700,
            headingRowColor: WidgetStateProperty.all(themeColor.primary.withValues(alpha: 0.04)),
            headingRowHeight: 48,
            dataRowHeight: 60,
            columns: [
              DataColumn2(label: Text(l10n.admin_finance_col_technician, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.L),
              DataColumn2(label: Text(l10n.admin_finance_col_amount, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.S),
              DataColumn2(label: Text(l10n.admin_finance_col_method, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.S),
              DataColumn2(label: Text(l10n.admin_finance_col_date, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.M),
              DataColumn2(label: Text(l10n.admin_finance_col_status, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.S),
              DataColumn2(label: Text(l10n.admin_finance_col_action, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.L),
            ],
            rows: requests.map((request) {
              return DataRow(
                cells: [
                  DataCell(Text(request.technicianName, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600))),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${request.amount.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: request.requestType == 'payment' ? Colors.green.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: request.requestType == 'payment' ? Colors.green.shade200 : Colors.blue.shade200),
                          ),
                          child: Text(
                            request.requestType == 'payment' ? 'سداد مديونية' : 'سحب مستحقات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: request.requestType == 'payment' ? Colors.green.shade700 : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(_getSettlementMethodText(request.method, l10n), style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
                  DataCell(Text(DateFormat('yyyy/MM/dd HH:mm').format(request.createdAt), style: const TextStyle(fontSize: 12))),
                  DataCell(_buildStatusBadge(request.status, themeColor)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (request.proofImageUrl.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.receipt_long_rounded, color: Colors.blue),
                            tooltip: l10n.admin_finance_btn_view_proof,
                            onPressed: () => _viewProofDialog(context, request.proofImageUrl, themeColor),
                          ),
                        if (request.adminProofUrl != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                            tooltip: l10n.admin_finance_col_admin_proof,
                            onPressed: () => _viewProofDialog(context, request.adminProofUrl!, themeColor, title: l10n.finance_admin_proof_label),
                          ),
                        ],
                        if (isPending) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                            tooltip: l10n.admin_finance_btn_approve,
                            onPressed: () => _confirmApproveSettlement(context, request, accounts),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent),
                            tooltip: l10n.admin_finance_btn_reject,
                            onPressed: () => _rejectSettlementDialog(context, request, themeColor),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Balances Tab ───────────────────────────────────────────────────────────
  Widget _buildBalancesTab(
    BuildContext context,
    AdminFinanceLoaded state,
    ThemeColor themeColor,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    if (state.technicianAccounts.isEmpty) {
      return const Center(
        child: Text('لا توجد بيانات حسابات مالية للفنيين.', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
      );
    }

    if (isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(l10n.admin_finance_tab_balances, Icons.account_balance_wallet_rounded, themeColor),
            const SizedBox(height: 12),
            _buildBalancesCards(context, state, themeColor, l10n),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: themeColor.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader(l10n.admin_finance_tab_balances, Icons.account_balance_wallet_rounded, themeColor),
              const SizedBox(height: 12),
              Expanded(
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 8,
                  minWidth: 800,
                  headingRowColor: WidgetStateProperty.all(themeColor.primary.withValues(alpha: 0.04)),
                  headingRowHeight: 48,
                  dataRowHeight: 56,
                  columns: [
                    DataColumn2(label: Text(l10n.admin_finance_col_technician, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.L),
                    DataColumn2(label: Text(l10n.admin_finance_col_net_balance, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.M),
                    DataColumn2(label: Text(l10n.admin_finance_col_owed_to_company, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.M),
                    DataColumn2(label: Text(l10n.admin_finance_col_owed_to_technician, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.M),
                    DataColumn2(label: Text(l10n.admin_finance_col_debt_limit, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.S),
                    DataColumn2(label: Text(l10n.admin_finance_col_status, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.S),
                  ],
                  rows: state.technicianAccounts.map((account) {
                    final netColor = account.netBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700;
                    final statusColor = account.accountStatus == 'active'
                        ? Colors.green
                        : account.accountStatus == 'restricted'
                            ? Colors.orange
                            : Colors.red;

                    return DataRow(
                      cells: [
                        DataCell(Text(account.technicianName, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600))),
                        DataCell(
                          Text(
                            '${account.netBalance.toStringAsFixed(2)} ج.م',
                            style: TextStyle(fontWeight: FontWeight.bold, color: netColor, fontSize: 13),
                          ),
                        ),
                        DataCell(Text('${account.amountOwedToCompany.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 13))),
                        DataCell(Text('${account.amountOwedToTechnician.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 13))),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${account.debtLimit.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.blue),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: l10n.admin_finance_btn_edit_debt,
                                onPressed: () => _editDebtLimitDialog(context, account, themeColor),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _getAccountStatusText(account.accountStatus, l10n),
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 11),
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
      ),
    );
  }

  Widget _buildBalancesCards(
    BuildContext context,
    AdminFinanceLoaded state,
    ThemeColor themeColor,
    AppLocalizations l10n,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.technicianAccounts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final account = state.technicianAccounts[index];
        final netColor = account.netBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700;
        final statusColor = account.accountStatus == 'active'
            ? Colors.green
            : account.accountStatus == 'restricted'
                ? Colors.orange
                : Colors.red;
        final String initials = account.technicianName.isNotEmpty
            ? account.technicianName.trim().split(' ').map((e) => e.isEmpty ? '' : e[0]).take(2).join()
            : 'F';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: themeColor.primary.withValues(alpha: 0.1),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: themeColor.primary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      account.technicianName,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _getAccountStatusText(account.accountStatus, l10n),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.admin_finance_col_net_balance, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                '${account.netBalance.toStringAsFixed(2)} ج.م',
                                style: TextStyle(fontWeight: FontWeight.bold, color: netColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.admin_finance_col_debt_limit, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '${account.debtLimit.toStringAsFixed(2)} ج.م',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => _editDebtLimitDialog(context, account, themeColor),
                                    child: const Icon(Icons.edit_rounded, size: 14, color: Colors.blue),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 14, color: Colors.black12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.admin_finance_col_owed_to_company, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                '${account.amountOwedToCompany.toStringAsFixed(2)} ج.م',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.admin_finance_col_owed_to_technician, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                '${account.amountOwedToTechnician.toStringAsFixed(2)} ج.م',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Manual Adjustment Tab ─────────────────────────────────────────────────
  Widget _buildAdjustmentTab(
    BuildContext context,
    AdminFinanceLoaded state,
    ThemeColor themeColor,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    // Unique list of technicians from accounts
    final technicians = state.technicianAccounts.map((acc) => {
      'id': acc.technicianId,
      'name': acc.technicianName,
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: isMobile ? 12 : 24,
        right: isMobile ? 12 : 24,
        top: isMobile ? 12 : 24,
        bottom: (isMobile ? 12 : 24) + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            color: themeColor.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 16 : 24)),
            elevation: isMobile ? 1.5 : 3,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune_rounded, color: themeColor.primary, size: isMobile ? 24 : 28),
                        const SizedBox(width: 12),
                        Text(
                          'إنشاء تسوية مالية يدوية',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تسوية يدوية لإضافة مكافأة أو خصم أو تسوية خاصة لمديونية فني محدد، وسيتم إقرارها فوراً.',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: isMobile ? 11 : 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),

                    // dropdown selects technician
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTechnicianId,
                      style: TextStyle(fontFamily: 'Cairo', color: themeColor.primary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: l10n.admin_finance_field_select_technician,
                        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: technicians.map((tech) {
                        return DropdownMenuItem<String>(
                          value: tech['id'],
                          child: Text(tech['name']!, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedTechnicianId = val),
                      validator: (val) => val == null ? 'يرجى اختيار الفني' : null,
                    ),
                    const SizedBox(height: 14),

                    // dropdown adjustment type
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAdjustmentType,
                      style: TextStyle(fontFamily: 'Cairo', color: themeColor.primary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: l10n.admin_finance_field_adjustment_type,
                        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        DropdownMenuItem(value: 'bonus', child: Text(l10n.admin_finance_type_bonus, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
                        DropdownMenuItem(value: 'penalty', child: Text(l10n.admin_finance_type_penalty, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
                        DropdownMenuItem(value: 'adjustment', child: Text(l10n.admin_finance_type_adjustment, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
                      ],
                      onChanged: (val) => setState(() => _selectedAdjustmentType = val ?? 'bonus'),
                    ),
                    const SizedBox(height: 14),

                    // amount field
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'المبلغ (جنيه مصري)',
                        hintText: '0.00',
                        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'يرجى إدخال المبلغ';
                        final numVal = double.tryParse(val);
                        if (numVal == null) return 'يرجى إدخال رقم صحيح';
                        if (numVal <= 0) return 'يجب أن يكون المبلغ أكبر من صفر';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // reason field
                    TextFormField(
                      controller: _reasonController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: l10n.admin_finance_field_reason,
                        hintText: 'اكتب سبب التسوية بالتفصيل...',
                        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'يرجى إدخال سبب التسوية' : null,
                    ),
                    const SizedBox(height: 14),

                    // notes field
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: l10n.admin_finance_field_notes,
                        hintText: 'أي ملاحظات إضافية (اختياري)...',
                        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<AdminFinanceCubit>().createAdjustment(
                                technicianId: _selectedTechnicianId!,
                                amount: double.parse(_amountController.text),
                                adjustmentType: _selectedAdjustmentType,
                                reason: _reasonController.text,
                                notes: _notesController.text,
                              );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        l10n.admin_finance_btn_submit_adjustment,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Financial Cases Tab ────────────────────────────────────────────────────
  Widget _buildCasesTab(
    BuildContext context,
    AdminFinanceLoaded state,
    ThemeColor themeColor,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    final pendingCases = state.financialCases.where((c) => c.status != 'resolved' && c.status != 'dismissed').toList();
    final closedCases = state.financialCases.where((c) => c.status == 'resolved' || c.status == 'dismissed').toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('نزاعات مالية معلقة ومفتوحة (${pendingCases.length})', Icons.report_problem_rounded, themeColor),
          const SizedBox(height: 12),
          isMobile
              ? _buildCasesCards(context, pendingCases, true, themeColor, l10n)
              : _buildCasesTable(context, pendingCases, true, themeColor, l10n),
          const SizedBox(height: 32),
          _buildSectionHeader('نزاعات مالية تمت تسويتها وإغلاقها', Icons.task_alt_rounded, themeColor),
          const SizedBox(height: 12),
          isMobile
              ? _buildCasesCards(context, closedCases, false, themeColor, l10n)
              : _buildCasesTable(context, closedCases, false, themeColor, l10n),
        ],
      ),
    );
  }

  Widget _buildCasesCards(
    BuildContext context,
    List<AdminFinancialCase> cases,
    bool isPending,
    ThemeColor themeColor,
    AppLocalizations l10n,
  ) {
    if (cases.isEmpty) {
      return Card(
        color: themeColor.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.rule_folder_outlined, size: 40, color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  isPending ? 'لا توجد نزاعات مالية مفتوحة حالياً.' : 'سجل تسويات النزاعات فارغ.',
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cases.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final c = cases[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: themeColor.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'حجز #${c.bookingId.substring(0, 8)}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: themeColor.primary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getCaseTypeText(c.discrepancyType),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(c.status, themeColor),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('الفني المبلغ:', c.reportedByName),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow('المبلغ المتوقع:', '${c.expectedAmount.toStringAsFixed(2)} ج.م'),
                  ),
                  Expanded(
                    child: _buildDetailRow('المبلغ المحصل:', '${c.collectedAmount.toStringAsFixed(2)} ج.م'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'وصف النزاع:',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                c.description,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.black87),
              ),
              if (c.resolutionNotes != null && c.resolutionNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'تفاصيل الحل:',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  c.resolutionNotes!,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.green),
                ),
              ],
              if (isPending) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _resolveCaseDialog(context, c, themeColor, l10n),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: Text(l10n.admin_finance_btn_resolve_case, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCasesTable(
    BuildContext context,
    List<AdminFinancialCase> cases,
    bool isPending,
    ThemeColor themeColor,
    AppLocalizations l10n,
  ) {
    if (cases.isEmpty) {
      return Card(
        color: themeColor.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.rule_folder_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  isPending ? 'لا توجد نزاعات مالية مفتوحة حالياً.' : 'سجل تسويات النزاعات فارغ.',
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      color: themeColor.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 360,
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 850,
            headingRowColor: WidgetStateProperty.all(themeColor.primary.withValues(alpha: 0.04)),
            headingRowHeight: 48,
            dataRowHeight: 56,
            columns: [
              const DataColumn2(label: Text('رقم الحجز', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.S),
              DataColumn2(label: Text('مبلغ متوقع', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.S),
              DataColumn2(label: Text('مبلغ محصل', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.S),
              DataColumn2(label: Text(l10n.admin_finance_col_technician, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.M),
              const DataColumn2(label: Text('نوع الفرق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.M),
              DataColumn2(label: Text(l10n.admin_finance_col_case_desc, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.L),
              DataColumn2(label: Text(l10n.admin_finance_col_status, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.S),
              DataColumn2(label: Text(l10n.admin_finance_col_action, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), size: ColumnSize.M),
            ],
            rows: cases.map((c) {
              return DataRow(
                cells: [
                  DataCell(Text(c.bookingId.substring(0, 8), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  DataCell(Text('${c.expectedAmount.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 13))),
                  DataCell(Text('${c.collectedAmount.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 13))),
                  DataCell(Text(c.reportedByName, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
                  DataCell(Text(_getCaseTypeText(c.discrepancyType), style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
                  DataCell(Text(c.description, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                  DataCell(_buildStatusBadge(c.status, themeColor)),
                  DataCell(
                    isPending
                      ? ElevatedButton(
                          onPressed: () => _resolveCaseDialog(context, c, themeColor, l10n),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(l10n.admin_finance_btn_resolve_case, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      : Text(c.resolutionNotes ?? '', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Helper UI Builders & Text Converters ───────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon, ThemeColor themeColor) {
    return Row(
      children: [
        Icon(icon, color: themeColor.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, ThemeColor themeColor) {
    Color badgeColor = Colors.grey;
    String text = status;

    switch (status) {
      case 'pending':
      case 'pending_review':
        badgeColor = Colors.orange;
        text = 'معلق';
        break;
      case 'approved':
      case 'resolved':
        badgeColor = Colors.green;
        text = 'مقبول / تم الحل';
        break;
      case 'rejected':
      case 'dismissed':
        badgeColor = Colors.red;
        text = 'مرفوض / ملغى';
        break;
      case 'in_investigation':
        badgeColor = Colors.blue;
        text = 'قيد التحقيق';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 11),
      ),
    );
  }

  String _getSettlementMethodText(String method, AppLocalizations l10n) {
    switch (method) {
      case 'vodafone_cash':
        return l10n.finance_settlement_method_vodafone_cash;
      case 'instapay':
        return l10n.finance_settlement_method_instapay;
      case 'bank_transfer':
        return l10n.finance_settlement_method_bank_transfer;
      case 'cash_handover':
        return l10n.finance_settlement_method_cash_handover;
      default:
        return l10n.finance_settlement_method_other;
    }
  }

  String _getAccountStatusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'active':
        return l10n.finance_status_active;
      case 'restricted':
        return l10n.finance_status_restricted;
      case 'blocked':
        return l10n.finance_status_blocked;
      default:
        return status;
    }
  }

  String _getCaseTypeText(String type) {
    switch (type) {
      case 'refused_full_payment':
        return 'رفض الدفع بالكامل';
      case 'partial_completion':
        return 'إتمام جزئي للطلب';
      case 'admin_approved_discount':
        return 'خصم موافق عليه';
      case 'pricing_dispute':
        return 'خلاف على السعر';
      case 'collection_discrepancy':
        return 'فرق تحصيل نقدي';
      default:
        return type;
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _viewProofDialog(BuildContext context, String imageUrl, ThemeColor themeColor, {String? title}) {
    final bool isValidUrl = imageUrl.isNotEmpty && imageUrl.startsWith('http');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title ?? 'إثبات التحويل المالي',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: isValidUrl
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImageErrorView();
                          },
                        )
                      : _buildImageErrorView(),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageErrorView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_rounded, size: 64, color: Colors.redAccent),
            SizedBox(height: 12),
            Text(
              'تعذر تحميل صورة الإثبات',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            SizedBox(height: 4),
            Text(
              'الرابط غير صالح أو الملف غير موجود بـ Supabase',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmApproveSettlement(
    BuildContext context,
    AdminSettlementRequest request,
    List<AdminTechnicianAccount> accounts,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isPayout = request.requestType == 'withdrawal';
    File? pickedImage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final ImagePicker picker = ImagePicker();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              isPayout ? l10n.admin_finance_payout_proof_title : l10n.admin_finance_approve_title,
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isPayout
                        ? l10n.admin_finance_payout_proof_desc
                        : 'هل أنت متأكد من رغبتك في الموافقة على طلب التسوية للفني ${request.technicianName} بمبلغ ${request.amount.toStringAsFixed(2)} ج.م؟',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  if (isPayout) ...[
                    const SizedBox(height: 16),
                    if (pickedImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.file(pickedImage!, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    OutlinedButton.icon(
                      onPressed: () async {
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            pickedImage = File(image.path);
                          });
                        }
                      },
                      icon: Icon(pickedImage == null ? Icons.upload_file_rounded : Icons.change_circle_rounded),
                      label: Text(
                        pickedImage == null ? l10n.finance_settlement_proof_select : 'تغيير صورة الإثبات',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
              ),
              ElevatedButton(
                onPressed: (isPayout && pickedImage == null)
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                        context.read<AdminFinanceCubit>().approveSettlement(
                              request.id,
                              proofImage: pickedImage,
                            );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                ),
                child: Text(l10n.admin_finance_btn_approve, style: const TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editDebtLimitDialog(
    BuildContext context,
    AdminTechnicianAccount account,
    ThemeColor themeColor,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final limitController = TextEditingController(text: account.debtLimit.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.admin_finance_edit_debt_title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تعديل حد الدين للفني: ${account.technicianName}', style: const TextStyle(fontFamily: 'Cairo')),
              const SizedBox(height: 16),
              TextFormField(
                controller: limitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.admin_finance_edit_debt_label,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'يرجى إدخال قيمة صحيحة';
                  final numVal = double.tryParse(val);
                  if (numVal == null) return 'يرجى إدخال رقم';
                  if (numVal < 0) return 'يجب أن يكون حد الدين أكبر من أو يساوي صفر';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newLimit = double.parse(limitController.text);
                Navigator.of(ctx).pop();
                context.read<AdminFinanceCubit>().updateTechnicianDebtLimit(account.id, newLimit);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: themeColor.primary, foregroundColor: Colors.white),
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _rejectSettlementDialog(BuildContext context, AdminSettlementRequest request, ThemeColor themeColor) {
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض طلب التسوية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('أدخل سبب رفض طلب التسوية للفني ${request.technicianName}:', style: const TextStyle(fontFamily: 'Cairo')),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'سبب الرفض',
                  hintText: 'اكتب سبب الرفض هنا...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'يرجى إدخال سبب الرفض' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final notes = notesController.text;
                Navigator.of(ctx).pop();
                context.read<AdminFinanceCubit>().rejectSettlement(request.id, notes);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('رفض الطلب', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _resolveCaseDialog(
    BuildContext context,
    AdminFinancialCase financialCase,
    ThemeColor themeColor,
    AppLocalizations l10n,
  ) {
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.admin_finance_btn_resolve_case, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('يرجى كتابة تفاصيل الحل والإجراء المتخذ لإغلاق هذا النزاع المالي:', style: TextStyle(fontFamily: 'Cairo')),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: l10n.admin_finance_field_resolution_notes,
                  hintText: 'اكتب ملخص الإجراء المتخذ...',
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'يرجى إدخال ملاحظات الحل' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final notes = notesController.text;
                Navigator.of(ctx).pop();
                context.read<AdminFinanceCubit>().resolveCase(financialCase.id, notes);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: themeColor.primary, foregroundColor: Colors.white),
            child: const Text('إغلاق وحل القضية', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab(
    BuildContext context,
    ThemeColor themeColor,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    return BlocConsumer<AdminReportsCubit, AdminReportsState>(
      listener: (context, state) {
        if (state is AdminReportsActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AdminReportsError) {
          debugPrint('❌ [AdminFinanceDashboardPage - AdminReportsError]: ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AdminReportsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminReportsError && state is! AdminReportsLoaded) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
                const SizedBox(height: 10),
                Text(state.message, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () => context.read<AdminReportsCubit>().loadReports(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          );
        }

        if (state is AdminReportsLoaded) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReportsHeader(context, state, themeColor, l10n, isMobile),
                    const SizedBox(height: 16),
                    _buildKPIsGrid(context, state, themeColor, l10n, isMobile),
                    const SizedBox(height: 24),
                    if (isMobile) ...[
                      _buildProfitGrowthCard(context, state, themeColor, l10n, isMobile),
                      const SizedBox(height: 16),
                      _buildPaymentRatioCard(context, state, themeColor, l10n, isMobile),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildProfitGrowthCard(context, state, themeColor, l10n, isMobile)),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _buildPaymentRatioCard(context, state, themeColor, l10n, isMobile)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildSectionHeader('ملخص الأشهر والتقارير الرسمية (PDF)', Icons.picture_as_pdf_rounded, themeColor),
                    const SizedBox(height: 12),
                    _buildMonthlySummariesList(context, state, themeColor, l10n, isMobile),
                  ],
                ),
              ),
              if (state.isActionInProgress)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildReportsHeader(
    BuildContext context,
    AdminReportsLoaded state,
    ThemeColor themeColor,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionHeader(l10n.admin_finance_reports_refresh_btn, Icons.analytics_rounded, themeColor),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.read<AdminReportsCubit>().refreshReports(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.admin_finance_reports_refresh_btn, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor.primary.withValues(alpha: 0.1),
                foregroundColor: themeColor.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => context.read<AdminReportsCubit>().exportLedgerToExcel(),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: Text(l10n.admin_finance_reports_export_ledger, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade50,
                foregroundColor: Colors.green.shade800,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPIsGrid(
    BuildContext context,
    AdminReportsLoaded state,
    ThemeColor themeColor,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    double totalCompanyProfit = state.summaries.fold(0.0, (sum, s) => sum + s.totalCompanyNetProfit);
    
    final financeState = context.read<AdminFinanceCubit>().state;
    double totalOwedToCompany = 0.0;
    double totalOwedToTechnician = 0.0;
    if (financeState is AdminFinanceLoaded) {
      totalOwedToCompany = financeState.technicianAccounts.fold(0.0, (sum, a) => sum + a.amountOwedToCompany);
      totalOwedToTechnician = financeState.technicianAccounts.fold(0.0, (sum, a) => sum + a.amountOwedToTechnician);
    }

    final kpis = [
      _KPICardData(
        title: l10n.admin_finance_reports_company_profit,
        value: '${totalCompanyProfit.toStringAsFixed(2)} ر.س',
        icon: Icons.trending_up_rounded,
        color: Colors.green,
      ),
      _KPICardData(
        title: l10n.admin_finance_reports_total_debt,
        value: '${totalOwedToCompany.toStringAsFixed(2)} ر.س',
        icon: Icons.assignment_late_rounded,
        color: Colors.redAccent,
      ),
      _KPICardData(
        title: l10n.admin_finance_reports_tech_earnings,
        value: '${totalOwedToTechnician.toStringAsFixed(2)} ر.س',
        icon: Icons.people_alt_rounded,
        color: Colors.blue,
      ),
    ];

    return isMobile
        ? Column(
            children: kpis.map((kpi) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildKPICard(kpi, themeColor),
            )).toList(),
          )
        : Row(
            children: kpis.map((kpi) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildKPICard(kpi, themeColor),
              ),
            )).toList(),
          );
  }

  Widget _buildKPICard(_KPICardData kpi, ThemeColor themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: kpi.color.withValues(alpha: 0.1),
            child: Icon(kpi.icon, color: kpi.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kpi.title,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  kpi.value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitGrowthCard(
    BuildContext context,
    AdminReportsLoaded state,
    ThemeColor themeColor,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    final summaries = state.summaries.reversed.toList();
    
    if (summaries.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: themeColor.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('لا توجد بيانات كافية للرسم البياني.', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
        ),
      );
    }

    final List<FlSpot> spots = [];
    for (int i = 0; i < summaries.length; i++) {
      spots.add(FlSpot(i.toDouble(), summaries[i].totalCompanyNetProfit));
    }

    double maxY = summaries.fold(100.0, (maxVal, s) => s.totalCompanyNetProfit > maxVal ? s.totalCompanyNetProfit : maxVal);
    maxY = (maxY * 1.2).ceilToDouble();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.admin_finance_reports_profit_growth,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < summaries.length) {
                          final monthParts = summaries[index].monthYear.split('-');
                          final label = monthParts.length > 1 ? monthParts[1] : summaries[index].monthYear;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (summaries.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: themeColor.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: themeColor.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRatioCard(
    BuildContext context,
    AdminReportsLoaded state,
    ThemeColor themeColor,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    double totalCash = state.summaries.fold(0.0, (sum, s) => sum + s.totalCashCollected);
    double totalOnline = state.summaries.fold(0.0, (sum, s) => sum + s.totalOnlineEarnings);
    double total = totalCash + totalOnline;

    bool isEmpty = total == 0;
    double cashPercent = isEmpty ? 50 : (totalCash / total) * 100;
    double onlinePercent = isEmpty ? 50 : (totalOnline / total) * 100;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.admin_finance_reports_revenue_ratio,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: Colors.orange,
                          value: cashPercent,
                          title: '${cashPercent.toStringAsFixed(1)}%',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Colors.blue,
                          value: onlinePercent,
                          title: '${onlinePercent.toStringAsFixed(1)}%',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('كاش', Colors.orange, '${totalCash.toStringAsFixed(0)} ر.س'),
                    const SizedBox(height: 12),
                    _buildLegendItem('أونلاين', Colors.blue, '${totalOnline.toStringAsFixed(0)} ر.س'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String amount) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
            Text(amount, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlySummariesList(
    BuildContext context,
    AdminReportsLoaded state,
    ThemeColor themeColor,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    if (state.summaries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: themeColor.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('لا توجد تقارير شهرية متوفرة حالياً.', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.summaries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final summary = state.summaries[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شهر: ${summary.monthYear}',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        Text('صافي الأرباح: ${summary.totalCompanyNetProfit.toStringAsFixed(2)} ر.س', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('التسويات المعتمدة: ${summary.totalSettlementsApproved.toStringAsFixed(2)} ر.س', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.read<AdminReportsCubit>().generateAndPrintMonthlyPdfReport(summary),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: Text(l10n.admin_finance_reports_print_summary, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KPICardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KPICardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
