import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/repositories/admin_finance_repository.dart';
import '../../domain/entities/monthly_financial_summary.dart';
import 'admin_reports_state.dart';

class AdminReportsCubit extends Cubit<AdminReportsState> {
  final AdminFinanceRepository _repository;

  AdminReportsCubit(this._repository) : super(AdminReportsInitial());

  Future<void> loadReports() async {
    emit(AdminReportsLoading());
    final summariesResult = await _repository.getMonthlyFinancialSummaries();
    final ledgerResult = await _repository.getLedgerEntries();

    summariesResult.fold(
      (failure) {
        debugPrint('🚨 [AdminReportsCubit.loadReports] Failed to fetch monthly summaries: ${failure.message}');
        emit(AdminReportsError(message: failure.message));
      },
      (summaries) {
        ledgerResult.fold(
          (failure) {
            debugPrint('🚨 [AdminReportsCubit.loadReports] Failed to fetch ledger entries: ${failure.message}');
            emit(AdminReportsError(message: failure.message));
          },
          (ledgerEntries) {
            emit(AdminReportsLoaded(
              summaries: summaries,
              ledgerEntries: ledgerEntries,
            ));
          },
        );
      },
    );
  }

  Future<void> refreshReports() async {
    final currentState = state;
    if (currentState is AdminReportsLoaded) {
      emit(currentState.copyWith(isActionInProgress: true));
    } else {
      emit(AdminReportsLoading());
    }

    final refreshResult = await _repository.refreshFinancialReports();

    refreshResult.fold(
      (failure) {
        debugPrint('🚨 [AdminReportsCubit.refreshReports] Failed to refresh: ${failure.message}');
        emit(AdminReportsError(message: failure.message));
      },
      (_) async {
        // Reload after refresh
        final summariesResult = await _repository.getMonthlyFinancialSummaries();
        final ledgerResult = await _repository.getLedgerEntries();

        summariesResult.fold(
          (failure) {
            debugPrint('🚨 [AdminReportsCubit.refreshReports] Reload summaries failed: ${failure.message}');
            emit(AdminReportsError(message: failure.message));
          },
          (summaries) {
            ledgerResult.fold(
              (failure) {
                debugPrint('🚨 [AdminReportsCubit.refreshReports] Reload ledger failed: ${failure.message}');
                emit(AdminReportsError(message: failure.message));
              },
              (ledgerEntries) {
                emit(AdminReportsLoaded(
                  summaries: summaries,
                  ledgerEntries: ledgerEntries,
                ));
                emit(const AdminReportsActionSuccess(message: 'تم تحديث التقارير المالية بنجاح'));
              },
            );
          },
        );
      },
    );
  }

  Future<void> exportLedgerToExcel() async {
    final currentState = state;
    if (currentState is! AdminReportsLoaded) return;

    emit(currentState.copyWith(isActionInProgress: true));
    try {
      final excel = Excel.createExcel();
      final sheet = excel.sheets[excel.getDefaultSheet()]!;

      // Set headers
      final List<CellValue?> headers = [
        TextCellValue('معرف القيد (ID)'),
        TextCellValue('اسم الفني (Technician)'),
        TextCellValue('نوع المعاملة (Type)'),
        TextCellValue('مدين (Debit)'),
        TextCellValue('دائن (Credit)'),
        TextCellValue('الرصيد الجاري (Balance)'),
        TextCellValue('البيان / الوصف (Description)'),
        TextCellValue('المرجع (Reference)'),
        TextCellValue('تاريخ المعاملة (Created At)'),
      ];

      sheet.appendRow(headers);

      for (final entry in currentState.ledgerEntries) {
        sheet.appendRow([
          TextCellValue(entry.id),
          TextCellValue(entry.technicianName),
          TextCellValue(entry.entryType),
          DoubleCellValue(entry.debit),
          DoubleCellValue(entry.credit),
          DoubleCellValue(entry.runningBalance),
          TextCellValue(entry.description),
          TextCellValue(entry.referenceType),
          TextCellValue(entry.createdAt.toIso8601String()),
        ]);
      }

      final excelBytes = excel.save();
      if (excelBytes != null) {
        await Printing.sharePdf(
          bytes: Uint8List.fromList(excelBytes),
          filename: 'general_ledger_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        );
        emit(const AdminReportsActionSuccess(message: 'تم تصدير ملف Excel بنجاح'));
      } else {
        emit(const AdminReportsError(message: 'فشل في حفظ ملف Excel'));
      }
    } catch (e, stackTrace) {
      debugPrint('🚨 [AdminReportsCubit.exportLedgerToExcel] Exception during export: $e\n$stackTrace');
      emit(AdminReportsError(message: 'خطأ أثناء التصدير: ${e.toString()}'));
    } finally {
      if (state is! AdminReportsError && state is! AdminReportsActionSuccess) {
        emit(currentState.copyWith(isActionInProgress: false));
      } else if (state is AdminReportsActionSuccess) {
        emit(currentState.copyWith(isActionInProgress: false));
      }
    }
  }

  Future<void> generateAndPrintMonthlyPdfReport(MonthlyFinancialSummary summary) async {
    final currentState = state;
    if (currentState is! AdminReportsLoaded) return;

    emit(currentState.copyWith(isActionInProgress: true));

    try {
      final pdf = pw.Document();
      final cairoRegular = await PdfGoogleFonts.cairoRegular();
      final cairoBold = await PdfGoogleFonts.cairoBold();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: cairoRegular,
            bold: cairoBold,
          ),
          build: (pw.Context context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header Logo & Company Info
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'فرش هوم - Fresh Home',
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue900,
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              'نظام إدارة الصيانة والخدمات المنزلية',
                              style: const pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'تقرير الأداء المالي الشهري',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue900,
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              'الشهر المستهدف: ${summary.monthYear}',
                              style: const pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.Divider(thickness: 2, color: PdfColors.blue900),
                    pw.SizedBox(height: 20),

                    // Introduction
                    pw.Text(
                      'الملخص العام للنظام المالي خلال هذا الشهر:',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.SizedBox(height: 15),

                    // Financial Grid Table
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(3),
                        1: const pw.FlexColumnWidth(2),
                      },
                      children: [
                        _buildTableHeaderRow(cairoBold),
                        _buildTableDataRow('صافي أرباح الشركة (Net Profit)', '${summary.totalCompanyNetProfit.toStringAsFixed(2)} ر.س'),
                        _buildTableDataRow('إجمالي العمولات المكتسبة (Commissions)', '${summary.totalCommissions.toStringAsFixed(2)} ر.س'),
                        _buildTableDataRow('المبالغ المحصلة كاش (Cash Collected)', '${summary.totalCashCollected.toStringAsFixed(2)} ر.س'),
                        _buildTableDataRow('المبالغ المحصلة أونلاين (Online Earnings)', '${summary.totalOnlineEarnings.toStringAsFixed(2)} ر.س'),
                        _buildTableDataRow('عمليات التسوية المعتمدة (Settlements)', '${summary.totalSettlementsApproved.toStringAsFixed(2)} ر.س'),
                      ],
                    ),
                    pw.SizedBox(height: 30),

                    // Cash vs Online Ratio Info
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ملاحظات التحليل والدفع:',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            '- يمثل إجمالي التدفق النقدي المحصل هذا الشهر: ${(summary.totalCashCollected + summary.totalOnlineEarnings).toStringAsFixed(2)} ر.س.',
                            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey900),
                          ),
                          pw.Text(
                            '- نسبة الدفع الإلكتروني تشكل: ${((summary.totalOnlineEarnings / (summary.totalCashCollected + summary.totalOnlineEarnings == 0 ? 1 : summary.totalCashCollected + summary.totalOnlineEarnings)) * 100).toStringAsFixed(1)}% من إجمالي الإيرادات.',
                            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey900),
                          ),
                        ],
                      ),
                    ),
                    pw.Spacer(),

                    // Footer signature
                    pw.Divider(thickness: 1, color: PdfColors.grey300),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'تاريخ إصدار التقرير: ${DateTime.now().toLocal().toString().substring(0, 16)}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                        ),
                        pw.Text(
                          'توقيع الإدارة المالية المعتمدة',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'monthly_financial_report_${summary.monthYear}.pdf',
      );
      emit(const AdminReportsActionSuccess(message: 'تم إنشاء تقرير PDF وعرض خيارات الطباعة بنجاح'));
    } catch (e, stackTrace) {
      debugPrint('🚨 [AdminReportsCubit.generateAndPrintMonthlyPdfReport] Exception generating PDF: $e\n$stackTrace');
      emit(AdminReportsError(message: 'خطأ أثناء إنشاء ملف PDF: ${e.toString()}'));
    } finally {
      if (state is! AdminReportsError && state is! AdminReportsActionSuccess) {
        emit(currentState.copyWith(isActionInProgress: false));
      } else if (state is AdminReportsActionSuccess) {
        emit(currentState.copyWith(isActionInProgress: false));
      }
    }
  }

  pw.TableRow _buildTableHeaderRow(pw.Font font) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blue900),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: pw.Text(
            'المؤشر المالي',
            style: pw.TextStyle(font: font, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: pw.Text(
            'القيمة المستحقة',
            style: pw.TextStyle(font: font, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  pw.TableRow _buildTableDataRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ),
      ],
    );
  }
}
