import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/widget/horizontal_date_picker.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/booking_flow_state.dart';
import '../../domain/booking_flow_config.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final TextEditingController _dateController = TextEditingController();
  String? dateWarningText;
  DateTime? nextAvailableSuggestion;
  bool _isInit = false;

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  DateTime? _parseManualDate(String text) {
    final clean = text.trim();
    final parts = clean.split(RegExp(r'[-\/]'));
    if (parts.length == 3) {
      int? day = int.tryParse(parts[0]);
      int? month = int.tryParse(parts[1]);
      int? year = int.tryParse(parts[2]);

      if (parts[0].length == 4) {
        year = int.tryParse(parts[0]);
        day = int.tryParse(parts[2]);
      }

      if (day != null && month != null && year != null) {
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 1000) {
          try {
            final date = DateTime(year, month, day);
            if (date.year == year && date.month == month && date.day == day) {
              return date;
            }
          } catch (_) {}
        }
      }
    }
    return null;
  }

  void _validateManualDate(String text, BookingFlowState state) {
    if (text.trim().isEmpty) {
      setState(() {
        dateWarningText = null;
        nextAvailableSuggestion = null;
      });
      _updateSchedule(context, null);
      return;
    }

    final parsedDate = _parseManualDate(text);
    if (parsedDate == null) {
      setState(() {
        dateWarningText = "صيغة التاريخ غير صحيحة. يرجى الإدخال بصيغة (يوم-شهر-سنة) مثل: 27-06-2026";
        nextAvailableSuggestion = null;
      });
      _updateSchedule(context, null);
      return;
    }

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final config = context.read<BookingFlowCubit>().config;
    final earliestDate = config.earliestSelectableDate;

    if (parsedDate.isBefore(earliestDate)) {
      setState(() {
        dateWarningText = config.mode == BookingFlowMode.admin
            ? "يرجى اختيار تاريخ اليوم أو تاريخ في المستقبل."
            : "يرجى اختيار تاريخ الغد أو تاريخ في المستقبل.";
        nextAvailableSuggestion = null;
      });
      _updateSchedule(context, null);
      return;
    }

    final diffDays = parsedDate.difference(todayDate).inDays;
    if (diffDays > 30) {
      setState(() {
        dateWarningText = "لا يمكن اختيار تاريخ بعد أكثر من شهر (30 يوماً) من تاريخ اليوم.";
        nextAvailableSuggestion = null;
      });
      _updateSchedule(context, null);
      return;
    }

    bool? isAvailable;
    for (final key in state.availabilityMap.keys) {
      if (key.year == parsedDate.year && key.month == parsedDate.month && key.day == parsedDate.day) {
        isAvailable = state.availabilityMap[key];
        break;
      }
    }

    if (isAvailable == false) {
      DateTime? foundNext;
      for (int d = 1; d <= 30; d++) {
        final searchDate = parsedDate.add(Duration(days: d));
        final diffFromToday = searchDate.difference(todayDate).inDays;
        if (diffFromToday > 30) {
          break;
        }

        bool? searchAvailable;
        for (final key in state.availabilityMap.keys) {
          if (key.year == searchDate.year && key.month == searchDate.month && key.day == searchDate.day) {
            searchAvailable = state.availabilityMap[key];
            break;
          }
        }

        if (searchAvailable != false) {
          foundNext = searchDate;
          break;
        }
      }

      setState(() {
        dateWarningText = "عذراً، هذا اليوم غير متوفر حالياً من قبل الفنيين.";
        nextAvailableSuggestion = foundNext;
      });
      _updateSchedule(context, null);
    } else {
      setState(() {
        dateWarningText = null;
        nextAvailableSuggestion = null;
      });
      _updateSchedule(context, parsedDate);
    }
  }

  void _updateSchedule(BuildContext context, DateTime? date, {String? time}) {
    final cubit = context.read<BookingFlowCubit>();
    if (date == null || date.year == 1900) {
      cubit.showScheduleError();
      return;
    }
    if (time == null) {
      final current = cubit.state.scheduledAt;
      final hour = current?.hour ?? 9;
      final minute = current?.minute ?? 0;
      cubit.updateSchedule(
          DateTime(date.year, date.month, date.day, hour, minute));
      return;
    }
    try {
      final timeDate = DateFormat('hh:mm a').parse(time);
      cubit.updateSchedule(DateTime(
          date.year, date.month, date.day, timeDate.hour, timeDate.minute));
    } catch (_) {
      cubit.updateSchedule(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingFlowCubit, BookingFlowState>(
      builder: (context, state) {
        final themeColor = context.themeColor;
        final themeText =
            Theme.of(context).extension<AppTextThemeExtension>()!;
        final l10n = AppLocalizations.of(context)!;
        final DateTime? dbDate = state.scheduledAt;
        final DateTime selectedDate = dbDate ?? DateTime(1900);

        if (!_isInit && dbDate != null) {
          _dateController.text = DateFormat('dd-MM-yyyy').format(dbDate);
          _isInit = true;
        }

        final String serviceLower =
            state.service?.name['en']?.toLowerCase().replaceAll(' ', '') ??
                'service';
        final availabilityMap = <String, Map<String, bool>>{};
        state.availabilityMap.forEach((date, isAvailable) {
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          availabilityMap[dateKey] = {serviceLower: isAvailable};
        });

        return RefreshIndicator(
          onRefresh: () =>
              context.read<BookingFlowCubit>().fetchAvailability(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service / Price summary card
                if (state.service != null)
                  _servicePriceSummary(
                    serviceName: state.service!.name[
                            Localizations.localeOf(context).languageCode] ??
                        '',
                    estimatedPrice:
                        state.price?.total.toStringAsFixed(0),
                    currency: l10n.pricing_currency_short,
                    themeColor: themeColor,
                    themeText: themeText,
                    l10n: l10n,
                  ),
                const SizedBox(height: 32),

                // Choose day
                Text(
                  l10n.schedule_choose_day,
                  style: themeText.titleSectionSmall.copyWith(
                      color: themeColor.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                const SizedBox(height: 16),

                // Date picker
                if (state.isLoadingAvailability)
                  const Center(child: CircularProgressIndicator())
                else if (state.availabilityError != null)
                  Center(
                    child: Text(state.availabilityError!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                  )
                else ...[
                  HorizontalDatePicker(
                    selectedDate: selectedDate,
                    firstDate: context.read<BookingFlowCubit>().config.earliestSelectableDate,
                    selectedService:
                        state.service?.name['en'] ?? 'Service',
                    availabilityMap: availabilityMap,
                    onDateSelected: (date, _) {
                      _updateSchedule(context, date);
                      _dateController.text = DateFormat('dd-MM-yyyy').format(date);
                      setState(() {
                        dateWarningText = null;
                        nextAvailableSuggestion = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'أو اكتب تاريخاً مخصصاً (يوم-شهر-سنة):',
                    style: themeText.textBodyPrimary.copyWith(
                      color: themeColor.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      hintText: 'مثال: 28-06-2026',
                      hintStyle: TextStyle(color: themeColor.textPrimary.withValues(alpha: 0.3)),
                      prefixIcon: Icon(Icons.edit_calendar_rounded, color: themeColor.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: themeColor.unselectedItem.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: themeColor.unselectedItem.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: themeColor.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (val) => _validateManualDate(val, state),
                  ),
                  if (dateWarningText != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dateWarningText!,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (nextAvailableSuggestion != null) ...[
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () {
                                final formatted = DateFormat('dd-MM-yyyy').format(nextAvailableSuggestion!);
                                _dateController.text = formatted;
                                _validateManualDate(formatted, state);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'أقرب موعد تالي متاح: ${DateFormat('EEEE، d MMMM', 'ar').format(nextAvailableSuggestion!)} (اختر هذا الموعد)',
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        color: Color(0xFF10B981),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],

                // Validation error
                if (state.errorMessage == 'error_select_schedule' &&
                    state.scheduledAt == null)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 8, bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline_rounded,
                            color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.validation_schedule_required,
                            style: themeText.textCaption.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ]),
                    ),
                  ),
                const SizedBox(height: 32),

                // Time slots
                Text(
                  l10n.schedule_available_times,
                  style: themeText.titleSectionSmall.copyWith(
                      color: themeColor.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                const SizedBox(height: 16),
                if (dbDate == null || dbDate.year == 1900)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "يرجى تحديد التاريخ أولاً لعرض الأوقات المتاحة",
                        style: themeText.textBodyPrimary.copyWith(
                          color: themeColor.textPrimary.withValues(alpha: 0.5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  _buildTimeSlots(
                      context, state, themeColor, themeText, selectedDate),
                const SizedBox(height: 24),

                // Info note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            themeColor.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline,
                        color: themeColor.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.schedule_selection_info,
                        style: themeText.textCaption
                            .copyWith(color: themeColor.textPrimary),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _servicePriceSummary({
    required String serviceName,
    String? estimatedPrice,
    required String currency,
    required ThemeColorExtension themeColor,
    required AppTextThemeExtension themeText,
    required AppLocalizations l10n,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [themeColor.cardShadow],
      ),
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.schedule_selected_service,
                style: themeText.textBodyPrimary.copyWith(
                    color: themeColor.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 4),
            Text(serviceName,
                style: themeText.textCaption.copyWith(
                    color: themeColor.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ]),
          if (estimatedPrice != null)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(l10n.schedule_estimated_price,
                  style: themeText.textBodyPrimary.copyWith(
                      color: themeColor.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 4),
              Text('$estimatedPrice $currency',
                  style: themeText.textCaption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: themeColor.primary,
                      fontSize: 13)),
            ]),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(
    BuildContext context,
    BookingFlowState state,
    ThemeColorExtension themeColor,
    AppTextThemeExtension themeText,
    DateTime selectedDate,
  ) {
    final cubit = context.read<BookingFlowCubit>();
    final isAdmin = cubit.config.mode == BookingFlowMode.admin;
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;
    
    int startHour = 9;
    int endHour = 18; // 6:00 PM
    
    if (isAdmin) {
      endHour = 23; // Admin can book until 11:00 PM
      if (isToday) {
        startHour = now.hour + 1;
      }
    } else {
      if (isToday) {
        startHour = now.hour + 1 > 9 ? now.hour + 1 : 9;
      }
    }
    
    final List<String> timeSlots = [];
    if (startHour <= endHour) {
      for (int i = startHour; i <= endHour; i++) {
        final dt = DateTime(2000, 1, 1, i, 0);
        timeSlots.add(DateFormat('hh:mm a').format(dt));
      }
    }

    if (timeSlots.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            l10n.schedule_no_times_available,
            style: themeText.textBodyPrimary.copyWith(color: themeColor.textPrimary.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final time = timeSlots[index];
        final String? currentTime = state.scheduledAt != null
            ? DateFormat('hh:mm a').format(state.scheduledAt!)
            : null;
        final bool isSelected = currentTime == time;

        return GestureDetector(
          onTap: () =>
              _updateSchedule(context, selectedDate, time: time),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? themeColor.buttonBackground
                  : themeColor.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? themeColor.buttonBackground
                    : themeColor.unselectedItem.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: themeColor.buttonBackground
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Text(
              time,
              style: themeText.textBodyPrimary.copyWith(
                color: isSelected
                    ? themeColor.buttonText
                    : themeColor.textPrimary,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }
}
