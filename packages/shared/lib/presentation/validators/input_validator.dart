import 'package:flutter/material.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';

class InputValidator {
  /// ✅ التحقق من صحة الاسم (الاسم الأول أو اسم العائلة)
  static String? validateName(String? value, {String? fieldName, AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      if (fieldName == 'firstName' || fieldName == 'الاسم الأول') {
        return l10n?.validation_first_name_required ?? "يرجى إدخال الاسم الأول";
      } else if (fieldName == 'lastName' || fieldName == 'اسم العائلة') {
        return l10n?.validation_last_name_required ?? "يرجى إدخال اسم العائلة";
      }
      return l10n?.validation_required ?? "يرجى إدخال ${fieldName ?? 'الاسم'}";
    }

    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return "يجب أن يتكون ${fieldName ?? 'الاسم'} من حرفين على الأقل";
    }

    if (!RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$').hasMatch(trimmed)) {
      return l10n?.validation_name_invalid ?? "يرجى إدخال اسم صحيح يتكون من حروف فقط";
    }

    return null;
  }

  /// ✅ التحقق من صحة كلمة المرور
  static String? validatePassword(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.isEmpty) {
      return l10n?.validation_password_required ?? "يرجى إدخال كلمة المرور";
    }

    if (value.length < 6) {
      return l10n?.validation_password_min_length ?? "يجب أن تتكون كلمة المرور من 6 خانات على الأقل";
    }

    return null;
  }

  /// ✅ التحقق من صحة البريد الإلكتروني
  static String? validateEmail(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validation_email_required ?? "يرجى إدخال البريد الإلكتروني";
    }

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
      return l10n?.validation_email_invalid ?? "يرجى إدخال بريد إلكتروني صحيح (مثال: name@example.com)";
    }

    return null;
  }

  /// ✅ لا يمكن أن تكون القيمة فارغة
  static String? validateEmpty(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validation_required ?? "لا يمكن ترك هذا الحقل فارغاً";
    }
    return null;
  }

  /// ✅ التحقق من صحة الوقت
  static String? validateTime(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validation_time_required ?? "يرجى إدخال الوقت";
    }

    TimeOfDay? selectedTime = _parseTime(value);
    if (selectedTime == null) {
      return l10n?.validation_time_format ?? "تنسيق الوقت غير صحيح";
    }

    if (!_isTimeInRange(selectedTime)) {
      return l10n?.validation_time_range ?? "يجب أن يكون الوقت بين 9 صباحاً و 6 مساءً";
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

  /// ✅ التحقق من صحة الرقم الصحيح Int
  static String? validateNumberint(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validation_area_required ?? 'يرجى إدخال المساحة';
    } else if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
      return l10n?.validation_number_invalid ?? 'يرجى إدخال رقم صحيح';
    } else if (double.parse(value.trim()) <= 0) {
      return l10n?.validation_number_positive ?? 'يجب إدخال رقم أكبر من الصفر';
    }
    return null;
  }

  static String? validateAddressNumeric(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
      return l10n?.validation_digits_only ?? 'يرجى إدخال أرقام فقط';
    }
    return null;
  }

  /// ✅ التحقق من صحة الرقم العشرية Double
  static String? validateNumberDouble(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validation_area_required ?? 'يرجى إدخال المساحة';
    } 
    if (!RegExp(r'^\d*\.?\d+$').hasMatch(value.trim())) {
      return l10n?.validation_number_invalid ?? 'يرجى إدخال رقم صحيح';
    }
    if (double.tryParse(value.trim()) == null || double.parse(value.trim()) <= 0) {
      return l10n?.validation_number_positive ?? 'يجب إدخال رقم أكبر من الصفر';
    }
    return null;
  }

  /// ✅ التحقق من التاريخ
  static String? validateDate(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validation_date_required ?? "يرجى إدخال التاريخ";
    }

    DateTime? selectedDate = _parseDate(value);
    if (selectedDate == null) {
      return l10n?.validation_date_format ?? "تنسيق التاريخ غير صحيح";
    }

    DateTime now = DateTime.now();
    DateTime lastDate = now.add(const Duration(days: 60));

    if (selectedDate.isBefore(now)) {
      return l10n?.validation_date_past ?? "لا يمكن اختيار تاريخ سابق";
    }

    if (selectedDate.isAfter(lastDate)) {
      return l10n?.validation_date_too_far ?? "لا يمكن اختيار تاريخ يتجاوز 60 يوماً من الآن";
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

  static DateTime? parseDate(String? dateText) {
    if (dateText == null || dateText.trim().isEmpty) return null;

    try {
      List<String> parts = dateText.split('-');
      if (parts.length != 3) return null;

      int year = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int day = int.parse(parts[2]);

      String formattedMonth = month.toString().padLeft(2, '0');
      String formattedDay = day.toString().padLeft(2, '0');

      return DateTime.parse("$year-$formattedMonth-$formattedDay");
    } catch (e) {
      return null;
    }
  }

  /// ✅ التحقق من رقم الهاتف المصري
  static String? validateEgyptianPhone(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validation_phone_required ?? "يرجى إدخال رقم الهاتف المحمول";
    }

    String phone = value.trim();

    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      return l10n?.validation_digits_only ?? "يجب إدخال أرقام فقط";
    }

    if (phone.length != 11) {
      return l10n?.validation_phone_invalid ?? "يجب أن يتكون رقم الهاتف المحمول من 11 رقماً";
    }

    if (!RegExp(r'^(010|011|012|015)\d{8}$').hasMatch(phone)) {
      return l10n?.validation_phone_invalid ?? "يرجى إدخال رقم هاتف مصري صحيح";
    }

    return null;
  }

  /// ✅ التحقق من اختيار قيمة من القائمة
  static String? validateDropdownSelection(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validation_selection_required ?? "يرجى اختيار عنصر من القائمة";
    }
    return null;
  }
}
