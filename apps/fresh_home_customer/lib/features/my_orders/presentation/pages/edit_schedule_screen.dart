import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fresh_home_customer/features/my_orders/presentation/cubit/edit_order_cubit.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/presentation/dialogs/dialog_helper.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';
import 'package:shared/presentation/widget/horizontal_date_picker.dart';
import 'package:go_router/go_router.dart';

class EditScheduleScreen extends StatefulWidget {
  final Booking order;

  const EditScheduleScreen({super.key, required this.order});

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  late DateTime _selectedDate;
  String? _selectedTime;

  DateTime _getDateTime() {
    return widget.order.scheduledAt;
  }

  @override
  void initState() {
    super.initState();
    final dateTime = _getDateTime();
    _selectedDate = dateTime;
    _selectedTime = DateFormat('hh:mm a').format(dateTime).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<EditOrderCubit, EditOrderState>(
      listener: (context, state) {
        if (state is EditOrderSuccess) {
          final currentDateTime = _getDateTime();
          final oldDate = DateFormat('yyyy-MM-dd').format(currentDateTime);
          final oldTime = DateFormat('hh:mm a').format(currentDateTime).toUpperCase();
          final newDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
          final newTime = _selectedTime;

          String successMessage = l10n.general_operation_success;
          if (oldDate != newDate && oldTime != newTime) {
            successMessage = l10n.edit_schedule_success_datetime(DateFormat('MMM dd').format(_selectedDate), newTime ?? '');
          } else if (oldDate != newDate) {
            successMessage = l10n.edit_schedule_success_date(DateFormat('EEEE, MMM dd').format(_selectedDate));
          } else if (oldTime != newTime) {
            successMessage = l10n.edit_schedule_success_time(newTime ?? '');
          }

          DialogHelper.showSuccess(
            context,
            message: successMessage,
            onOkPress: () => context.pop(true),
          );
        } else if (state is EditOrderFailure) {
          DialogHelper.showError(
            context,
            message: state.message,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.booking_appbar_title),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.schedule_choose_day,
                style: themeText.titleSectionSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              HorizontalDatePicker(
                selectedDate: _selectedDate,
                selectedService: widget.order.service.name[Localizations.localeOf(context).languageCode] ?? '',
                availabilityMap: const {},
                onDateSelected: (date, _) {
                  setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 32),
              Text(
                l10n.schedule_available_times,
                style: themeText.titleSectionSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTimeSlots(themeColor, themeText),
              const SizedBox(height: 48),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(20),
          child: BlocBuilder<EditOrderCubit, EditOrderState>(
            builder: (context, state) {
              return ElevatedButton(
                onPressed: state is EditOrderLoading
                    ? null
                    : () {
                        if (_selectedTime != null) {
                          // Parse selected time string (e.g. "09:00 AM") and combine with selected date
                          final timeParts = DateFormat('hh:mm a').parse(_selectedTime!);
                          final combinedDateTime = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            timeParts.hour,
                            timeParts.minute,
                          );
                          context.read<EditOrderCubit>().updateOrderSchedule(
                            orderId: widget.order.id,
                            scheduledAt: combinedDateTime,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: state is EditOrderLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        l10n.general_save,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlots(ThemeColorExtension themeColor, AppTextThemeExtension themeText) {
    final List<String> timeSlots = [
      '09:00 AM', '10:00 AM', '11:00 AM', 
      '12:00 PM', '01:00 PM', '02:00 PM', 
      '03:00 PM', '04:00 PM', '05:00 PM', 
      '06:00 PM',
    ];

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
        final bool isSelected = _selectedTime == time;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = time),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? themeColor.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? themeColor.primary : Colors.grey.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Text(
              time,
              style: themeText.textBodyPrimary.copyWith(
                color: isSelected ? Colors.white : const Color(0xFF333333),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }
}
