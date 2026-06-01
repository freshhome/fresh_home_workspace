import 'package:flutter/material.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';

class InputValidator {
  // ✅ التحقق من صحة الوقت
  static String? validateTime(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validation_time_required ?? "يا ريت تدخل الوقت";
    }

    TimeOfDay? selectedTime = _parseTime(value);
    if (selectedTime == null) {
      return l10n?.validation_time_format ?? "تنسيق الوقت مش مظبوط";
    }

    if (!_isTimeInRange(selectedTime)) {
      return l10n?.validation_time_range ?? "الوقت لازم يكون بين 9 ص و 6 م";
    }

    return null;
  }

  static TimeOfDay? _parseTime(String timeText) {
    try {
      final timeParts = timeText.split(' ');
      if (timeParts.length != 2) return null;

      final time = timeParts[0].split(':');
      if (time.length != 2) return null;

      int hour = int.parse(time[0]);
      int minute = int.parse(time[1]);

      if (timeParts[1].toUpperCase() == "PM" && hour != 12) hour += 12;
      if (timeParts[1].toUpperCase() == "AM" && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  static bool _isTimeInRange(TimeOfDay time) {
    const startHour = 9;
    const endHour = 18;

    int selectedTimeInMinutes = time.hour * 60 + time.minute;
    int startTimeInMinutes = startHour * 60;
    int endTimeInMinutes = endHour * 60;

    return selectedTimeInMinutes >= startTimeInMinutes &&
        selectedTimeInMinutes <= endTimeInMinutes;
  }

  /// ✅Int التحقق من صحة الرقم 
  static String? validateNumberint(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validation_area_required ?? 'يا ريت تدخل المساحة';
    } else if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
      return l10n?.validation_number_invalid ?? 'يا ريت تدخل رقم صح';
    } else if (double.parse(value.trim()) <= 0) {
      return l10n?.validation_number_positive ?? 'لازم تدخل رقم أكبر من الصفر';
    }
    return null;
  }

  static String? validateAddressNumeric(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return null; // Allowed to be empty
    }
    if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
      return l10n?.validation_digits_only ?? 'يا ريت تدخل أرقام بس';
    }
    return null;
  }
  /// ✅double التحقق من صحة الرقم 

  static String? validateNumberDouble(String? value, {AppLocalizations? l10n}) {
  if (value == null || value.trim().isEmpty) {
    return l10n?.validation_area_required ?? 'يا ريت تدخل المساحة';
  } 
  if (!RegExp(r'^\d*\.?\d+$').hasMatch(value.trim())) {
    return l10n?.validation_number_invalid ?? 'يا ريت تدخل رقم صح';
  }
  if (double.tryParse(value.trim()) == null || double.parse(value.trim()) <= 0) {
    return l10n?.validation_number_positive ?? 'لازم تدخل رقم أكبر من الصفر';
  }
  return null;
}
  /// ✅ التحقق من التاريخ
  static String? validateDate(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validation_date_required ?? "يا ريت تدخل التاريخ";
    }

    DateTime? selectedDate = _parseDate(value);
    if (selectedDate == null) {
      return l10n?.validation_date_format ?? "تنسيق التاريخ مش مظبوط";
    }

    DateTime now = DateTime.now();
    DateTime lastDate = now.add(const Duration(days: 60));

    if (selectedDate.isBefore(now)) {
      return l10n?.validation_date_past ?? "مش هينفع تختار تاريخ قديم";
    }

    if (selectedDate.isAfter(lastDate)) {
      return l10n?.validation_date_too_far ?? "مش هينفع تختار تاريخ بعد 60 يوم من دلوقتي";
    }

    return null;
  }

  static DateTime? _parseDate(String dateText) {
    try {
      List<String> parts = dateText.split('-');
      if (parts.length != 3) return null;

      int year = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int day = int.parse(parts[2]);

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
/// ✅ لضبط صيغه التاريخ 

static DateTime? parseDate(String? dateText) {
  if (dateText == null || dateText.trim().isEmpty) return null;

  try {
    List<String> parts = dateText.split('-');
    if (parts.length != 3) return null;

    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int day = int.parse(parts[2]);

    // ✅ ضمان أن الشهر واليوم مكونين من رقمين
    String formattedMonth = month.toString().padLeft(2, '0');
    String formattedDay = day.toString().padLeft(2, '0');

    return DateTime.parse("$year-$formattedMonth-$formattedDay");
  } catch (e) {
    return null; // إرجاع null لو في خطأ في التحليل
  }
}

  /// ✅ التحقق من رقم الهاتف المصري
  static String? validateEgyptianPhone(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validation_phone_required ?? "يا ريت تدخل رقم الموبايل";
    }

    // إزالة أي مسافات في البداية أو النهاية
    String phone = value.trim();

    // التأكد من أن الرقم يحتوي فقط على أرقام
    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      return l10n?.validation_digits_only ?? "لازم تدخل أرقام بس";
    }

    // التحقق من طول الرقم (يجب أن يكون 11 رقمًا)
    if (phone.length != 11) {
      return l10n?.validation_phone_invalid ?? "رقم الموبايل لازم يكون 11 رقم";
    }

    // التحقق من أن الرقم يبدأ بمقدمة صحيحة لشبكات المحمول المصرية
    if (!RegExp(r'^(010|011|012|015)\d{8}$').hasMatch(phone)) {
      return l10n?.validation_phone_invalid ?? "يا ريت تدخل رقم موبايل مصري صح";
    }

    return null; // رقم صحيح
  }

    /// ✅ التحقق من اختيار قيمه من القايمة
static String? validateDropdownSelection(String? value, {AppLocalizations? l10n}) {
  if (value == null || value.trim().isEmpty) {
    return l10n?.validation_selection_required ?? "يا ريت تختار حاجة من القائمة";
  }
  return null; // الإدخال صحيح
}

    /// ✅ لا يمكن ان تكون القيمة فارغة

static String?  validateEmpty (String? value, {AppLocalizations? l10n}) {
  if (value == null || value.trim().isEmpty) {
    return l10n?.validation_required ?? "ماينفعش تسيب الخانة دي فاضية";
  }
  return null; // الإدخال صحيح
}


 /// ✅ التحقق من صحة البريد الإلكتروني
  static String? validateEmail(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validation_email_required ?? "يا ريت تدخل الإيميل";
    }

    // التحقق من التنسيق الصحيح للبريد الإلكتروني باستخدام regex
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
      return l10n?.validation_email_invalid ?? "يا ريت تدخل إيميل مظبوط";
    }

    return null; // الإدخال صحيح
  }


}
