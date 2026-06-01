import 'package:flutter/material.dart';

/// دالة لاختيار الساعة
Future<void> pickHour(
  BuildContext context, {
  required TextEditingController controller,
}) async {
  final int? selectedHour = await showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("اختر الساعة"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: 10,
            itemBuilder: (context, index) {
              final int hour = 9 + index;
              final bool isAM = hour < 12;
              return ListTile(
                title: Text(
                    "${hour % 12 == 0 ? 12 : hour % 12}:00 ${isAM ? 'AM' : 'PM'}"),
                leading: Icon(isAM ? Icons.wb_sunny : Icons.nightlight_round),
                onTap: () => Navigator.of(context).pop(hour),
              );
            },
          ),
        ),
      );
    },
  );

  if (selectedHour != null) {
    controller.text =
        "${selectedHour % 12 == 0 ? 12 : selectedHour % 12}:00 ${selectedHour < 12 ? 'AM' : 'PM'}";
  }
}

/// دالة لاختيار التاريخ
Future<void> pickDate(
  BuildContext context, {
  required TextEditingController controller,
}) async {
  final DateTime now = DateTime.now();
  final DateTime firstAvailableDate = now.add(const Duration(days: 1)); // الغد
  final DateTime lastAvailableDate =
      now.add(const Duration(days: 60)); // بعد 60 يوم

  final DateTime? selectedDate = await showDatePicker(
    context: context,
    initialDate: firstAvailableDate, // الافتراضي الغد
    firstDate: firstAvailableDate,
    lastDate: lastAvailableDate,
    helpText: "اختر التاريخ",
    cancelText: "إلغاء",
    confirmText: "موافق",
    fieldLabelText: "التاريخ",
  );

  if (selectedDate != null) {
    controller.text =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
  }
}

///داله للأختيار من قائمه 

Future<void> pickDropdownOption(
  BuildContext context, {
  required String hint,
  required List<String> options,
  required TextEditingController controller,
  Function(String)? onSelectOption,
}) async {
  if (options.isEmpty) return;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          hint,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final option = options[index];
              return TextButton(
                onPressed: () {
                  onSelectOption?.call(option);
                  controller.text = option;
                  Navigator.pop(context);
                },
                child: Text(
                  option,
                  style: const TextStyle(fontSize: 16),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}