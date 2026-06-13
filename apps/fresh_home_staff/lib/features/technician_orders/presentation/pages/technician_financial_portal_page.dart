import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:shared/shared.dart';

import '../../../finance/presentation/cubit/technician_finance_cubit.dart';
import '../../../finance/presentation/cubit/technician_finance_state.dart';
import '../../../finance/presentation/widgets/settlement_request_bottom_sheet.dart';
import '../../../finance/domain/entities/ledger_entry.dart';
import '../../../finance/domain/entities/settlement_request.dart';

class TechnicianFinancialPortalPage extends StatefulWidget {
  const TechnicianFinancialPortalPage({super.key});

  @override
  State<TechnicianFinancialPortalPage> createState() =>
      _TechnicianFinancialPortalPageState();
}

class _TechnicianFinancialPortalPageState extends State<TechnicianFinancialPortalPage> {
  @override
  void initState() {
    super.initState();
    // Load financial data on page entry
    Future.microtask(() {
      if (mounted) {
        context.read<TechnicianFinanceCubit>().loadFinancialData();
      }
    });
  }

  String _getEntryTypeLabel(String entryType, AppLocalizations l10n) {
    switch (entryType) {
      case 'order_earnings':
        return l10n.finance_entry_type_order_earnings;
      case 'company_commission_debit':
        return l10n.finance_entry_type_company_commission_debit;
      case 'cash_collection_debit':
        return l10n.finance_entry_type_cash_collection_debit;
      case 'manual_bonus':
        return l10n.finance_entry_type_manual_bonus;
      case 'manual_penalty':
        return l10n.finance_entry_type_manual_penalty;
      case 'manual_adjustment':
        return l10n.finance_entry_type_manual_adjustment;
      case 'settlement_reconciliation':
        return l10n.finance_entry_type_settlement_reconciliation;
      default:
        return entryType;
    }
  }

  String _getStatusLabel(String status, AppLocalizations l10n) {
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'restricted':
        return Colors.orange;
      case 'blocked':
      default:
        return Colors.red;
    }
  }

  String _extractOrderNumber(String description) {
    final hashIndex = description.indexOf('#');
    if (hashIndex != -1) {
      return description.substring(hashIndex);
    }
    return '';
  }

  List<dynamic> _consolidateEntries(List<LedgerEntry> entries) {
    final List<dynamic> consolidated = [];
    final Map<String, List<LedgerEntry>> bookingGroups = {};
    
    // Group all entries by bookingId
    for (var entry in entries) {
      final bId = entry.bookingId;
      if (bId != null) {
        if (!bookingGroups.containsKey(bId)) {
          bookingGroups[bId] = [];
        }
        bookingGroups[bId]!.add(entry);
      } else {
        consolidated.add(entry);
      }
    }
    
    // Process booking groups
    bookingGroups.forEach((bId, group) {
      double netAmount = 0;
      for (var entry in group) {
        netAmount += (entry.credit - entry.debit);
      }
      
      // Sort group descending by date (most recent first)
      group.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final rep = group.first;
      
      consolidated.add({
        'isGrouped': true,
        'bookingId': bId,
        'netAmount': netAmount,
        'createdAt': rep.createdAt,
        'runningBalance': rep.runningBalance,
        'description': rep.description,
        'entries': group,
      });
    });
    
    // Sort all items by date descending
    consolidated.sort((a, b) {
      final DateTime dateA = a is LedgerEntry ? a.createdAt : (a as Map)['createdAt'] as DateTime;
      final DateTime dateB = b is LedgerEntry ? b.createdAt : (b as Map)['createdAt'] as DateTime;
      return dateB.compareTo(dateA);
    });
    
    return consolidated;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.finance_title,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<TechnicianFinanceCubit>().loadFinancialData(),
        child: BlocBuilder<TechnicianFinanceCubit, TechnicianFinanceState>(
          builder: (context, state) {
            if (state is TechnicianFinanceLoading || state is TechnicianFinanceInitial) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is TechnicianFinanceError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(fontFamily: 'Cairo', color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<TechnicianFinanceCubit>()
                          .loadFinancialData(),
                      child: Text(l10n.general_retry),
                    ),
                  ],
                ),
              );
            }

            if (state is TechnicianFinanceLoaded) {
              final account = state.account;
              final entries = state.ledgerEntries;
              final consolidatedList = _consolidateEntries(entries);
              final netBalance = account.netBalance;
              final isPositive = netBalance >= 0;
              final remainingLimit = account.debtLimit + netBalance;

              // Choose gradient based on netBalance and accountStatus (4 colors)
              List<Color> gradientColors;
              if (netBalance > 0) {
                // 1. Positive (+): Primary Blue
                gradientColors = [
                  themeColor.primary,
                  themeColor.primary.withValues(alpha: 0.85),
                ];
              } else if (netBalance == 0) {
                // 2. Zero (Neutral): Slate Grey
                gradientColors = [
                  const Color(0xFF64748B),
                  const Color(0xFF475569),
                ];
              } else if (account.accountStatus == 'blocked') {
                // 3. Negative & Blocked (exceeded limit): Warning Red
                gradientColors = [
                  const Color(0xFFEF4444),
                  const Color(0xFFB91C1C),
                ];
              } else {
                // 4. Negative & Within Limit: Amber/Orange
                gradientColors = [
                  const Color(0xFFF59E0B),
                  const Color(0xFFD97706),
                ];
              }

              // Debt consumption progress
              double progress = 0.0;
              if (netBalance < 0 && account.debtLimit > 0) {
                progress = (netBalance.abs() / account.debtLimit).clamp(0.0, 1.0);
              }

              // Dynamic action button config
              final String buttonLabel;
              final IconData buttonIcon;
              final Color buttonBgColor;
              final Color buttonFgColor;
              final BorderSide buttonBorder;

              if (netBalance > 0) {
                buttonLabel = locale == 'ar' ? 'طلب سحب الأرباح' : 'Withdraw Earnings';
                buttonIcon = Icons.arrow_downward_rounded;
                buttonBgColor = themeColor.primary;
                buttonFgColor = Colors.white;
                buttonBorder = BorderSide.none;
              } else if (netBalance < 0) {
                buttonLabel = locale == 'ar' ? 'سداد المديونية للشركة' : 'Pay Company Debt';
                buttonIcon = Icons.arrow_upward_rounded;
                buttonBgColor = Colors.white;
                buttonFgColor = const Color(0xFFEF4444);
                buttonBorder = const BorderSide(color: Color(0xFFEF4444), width: 1.5);
              } else {
                buttonLabel = locale == 'ar' ? 'طلب تسوية الحساب' : 'Request Settlement';
                buttonIcon = Icons.swap_horiz_rounded;
                buttonBgColor = Colors.white;
                buttonFgColor = themeColor.primary;
                buttonBorder = BorderSide(color: themeColor.primary, width: 1.5);
              }

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Financial Account Summary Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors.first.withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Status Badge Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isPositive
                                  ? l10n.finance_balance_owed_to_you
                                  : l10n.finance_amount_owed_to_company,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 4,
                                    backgroundColor: _getStatusColor(account.accountStatus),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getStatusLabel(account.accountStatus, l10n),
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Balance Display
                        Text(
                          '${netBalance.abs().toStringAsFixed(2)} ${locale == 'ar' ? 'ج.م' : 'EGP'}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Debt details & limits
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryStat(
                              title: l10n.finance_debt_limit,
                              val: '${account.debtLimit.toStringAsFixed(0)} ${locale == 'ar' ? 'ج.م' : 'EGP'}',
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white24,
                            ),
                            _buildSummaryStat(
                              title: l10n.finance_remaining_limit,
                              val: '${remainingLimit.toStringAsFixed(0)} ${locale == 'ar' ? 'ج.م' : 'EGP'}',
                            ),
                          ],
                        ),

                        // Progress Bar showing debt consumption
                        if (netBalance < 0) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                locale == 'ar' ? 'استهلاك حد الدين المسموح' : 'Debt Limit Consumed',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress >= 0.85
                                    ? const Color(0xFFEF4444)
                                    : progress >= 0.5
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF10B981),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],

                        // Status notification message inside the card
                        if (netBalance < 0 && account.accountStatus == 'restricted') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.finance_status_warning,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (netBalance < 0 && account.accountStatus == 'blocked') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.block_flipped,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.finance_status_blocked_desc,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Request Settlement Button
                  ElevatedButton.icon(
                    onPressed: () => SettlementRequestBottomSheet.show(
                      context,
                      cubit: context.read<TechnicianFinanceCubit>(),
                    ),
                    icon: Icon(buttonIcon, size: 20),
                    label: Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonBgColor,
                      foregroundColor: buttonFgColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: buttonBorder,
                      ),
                      elevation: buttonBgColor != Colors.white ? 2 : 0,
                      shadowColor: buttonBgColor != Colors.white ? buttonBgColor.withValues(alpha: 0.3) : null,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 3. Transactions List Header
                  Text(
                    l10n.finance_ledger_statement,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Ledger Entries Timeline
                  if (consolidatedList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          l10n.finance_ledger_empty,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    ...consolidatedList.map((item) => _buildLedgerEntryCard(
                          context,
                          item,
                          themeColor,
                          locale,
                          l10n,
                        )),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLedgerEntryCard(
    BuildContext context,
    dynamic item,
    ThemeColorExtension themeColor,
    String locale,
    AppLocalizations l10n,
  ) {
    final bool isGrouped = item is Map;
    final bool isCredit;
    final double value;
    final DateTime createdAt;
    final double runningBalance;
    final String title;
    final String description;
    final bool isSettlement;
    final String settlementRefId;
    
    if (isGrouped) {
      final double netAmount = item['netAmount'] as double;
      isCredit = netAmount > 0;
      value = netAmount.abs();
      createdAt = item['createdAt'] as DateTime;
      runningBalance = item['runningBalance'] as double;
      isSettlement = false;
      settlementRefId = '';
      
      final String rawDesc = item['description'] as String;
      final String orderNum = _extractOrderNumber(rawDesc);
      
      if (netAmount < 0) {
        title = locale == 'ar' ? 'مستحق من الطلب $orderNum' : 'Due from order $orderNum';
        description = locale == 'ar' ? 'عمولة الشركة المستقطعة (كاش)' : 'Company commission deduction (cash)';
      } else {
        title = locale == 'ar' ? 'أرباح الطلب $orderNum' : 'Earnings of order $orderNum';
        description = locale == 'ar' ? 'أرباحك الصافية من الخدمة' : 'Your net service earnings';
      }
    } else {
      final LedgerEntry entry = item as LedgerEntry;
      isCredit = entry.credit > 0;
      value = isCredit ? entry.credit : entry.debit;
      createdAt = entry.createdAt;
      runningBalance = entry.runningBalance;
      description = entry.description;
      isSettlement = entry.entryType == 'settlement_reconciliation';
      settlementRefId = entry.referenceId;
      
      if (entry.entryType == 'settlement_reconciliation') {
        title = locale == 'ar' ? 'تسوية مالية معتمدة' : 'Approved settlement';
      } else if (entry.entryType == 'manual_bonus') {
        title = locale == 'ar' ? 'حافز / مكافأة إدارية' : 'Administrative bonus';
      } else if (entry.entryType == 'manual_penalty') {
        title = locale == 'ar' ? 'خصم / جزاء إداري' : 'Administrative penalty';
      } else if (entry.entryType == 'manual_adjustment') {
        title = locale == 'ar' ? 'تعديل رصيد يدوي' : 'Manual balance adjustment';
      } else {
        title = _getEntryTypeLabel(entry.entryType, l10n);
      }
    }
    
    final String dateStr = DateFormat('yyyy-MM-dd • HH:mm', locale).format(createdAt);

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          right: locale == 'ar'
              ? BorderSide(color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444), width: 4)
              : BorderSide.none,
          left: locale != 'ar'
              ? BorderSide(color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444), width: 4)
              : BorderSide.none,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon representing the entry type (Arrow Down for Income, Arrow Up for Expense)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCredit
                    ? const Color(0xFF10B981).withValues(alpha: 0.08)
                    : const Color(0xFFEF4444).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 18,
              ),
            ),
            const SizedBox(width: 14),

            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 9, color: Colors.black38),
                  ),
                ],
              ),
            ),

            // Value & Running Balance Column
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isCredit ? "+" : "-"} ${value.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${runningBalance.toStringAsFixed(2)} ${locale == 'ar' ? 'ج.م' : 'EGP'}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                if (isSettlement) ...[
                  const SizedBox(width: 8),
                  Icon(
                    locale == 'ar' ? Icons.keyboard_arrow_left_rounded : Icons.keyboard_arrow_right_rounded,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    if (isSettlement) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showSettlementDetails(context, settlementRefId),
          child: card,
        ),
      );
    }
    return card;
  }

  Widget _buildSummaryStat({required String title, required String val}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showSettlementDetails(BuildContext context, String settlementId) {
    final l10n = AppLocalizations.of(context)!;
    final themeColor = context.themeColor;
    final locale = Localizations.localeOf(context).languageCode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: FutureBuilder<Either<Failure, SettlementRequest>>(
          future: context.read<TechnicianFinanceCubit>().getSettlementRequest(settlementId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    l10n.finance_error_generic,
                    style: const TextStyle(fontFamily: 'Cairo', color: Colors.red),
                  ),
                ),
              );
            }

            final result = snapshot.data!;
            return result.fold(
              (failure) => SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    failure.message,
                    style: const TextStyle(fontFamily: 'Cairo', color: Colors.red),
                  ),
                ),
              ),
              (request) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.finance_entry_type_settlement_reconciliation,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow(l10n.admin_finance_col_amount, '${request.amount.toStringAsFixed(2)} ${locale == 'ar' ? 'ج.م' : 'EGP'}'),
                      const SizedBox(height: 12),
                      _buildDetailRow(l10n.admin_finance_col_method, _getSettlementMethodText(request.method, l10n)),
                      const SizedBox(height: 12),
                      _buildDetailRow(l10n.admin_finance_col_status, _getSettlementStatusText(request.status)),
                      if (request.adminNotes != null && request.adminNotes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(locale == 'ar' ? 'ملاحظات الإدارة' : 'Admin Notes', request.adminNotes!),
                      ],
                      const SizedBox(height: 24),
                      if (request.proofImageUrl.isNotEmpty) ...[
                        Text(
                          l10n.finance_settlement_proof,
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 180,
                            color: Colors.grey.shade100,
                            child: Image.network(
                              request.proofImageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (request.adminProofUrl != null && request.adminProofUrl!.isNotEmpty) ...[
                        Text(
                          l10n.finance_admin_proof_label,
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 180,
                            color: Colors.grey.shade100,
                            child: Image.network(
                              request.adminProofUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          locale == 'ar' ? 'إغلاق' : 'Close',
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
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

  String _getSettlementStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }
}
