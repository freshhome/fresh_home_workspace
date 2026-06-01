import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'translations/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @profile_saved_addresses.
  ///
  /// In ar, this message translates to:
  /// **'العناوين المسجلة'**
  String get profile_saved_addresses;

  /// No description provided for @profile_saved_phones.
  ///
  /// In ar, this message translates to:
  /// **'أرقام الهاتف المسجلة'**
  String get profile_saved_phones;

  /// رسالة تحميل عامة
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get general_loading;

  /// عنوان رسالة خطأ
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get general_error;

  /// عنوان رسالة نجاح
  ///
  /// In ar, this message translates to:
  /// **'نجاح'**
  String get general_success;

  /// زر إلغاء
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get general_cancel;

  /// رقم آخر (للاختيار)
  ///
  /// In ar, this message translates to:
  /// **'رقم آخر'**
  String get general_another_number;

  /// زر التالي
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get general_next;

  /// زر السابق
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get general_back;

  /// زر ابداء الآن
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get general_get_started;

  /// زر حفظ
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get general_save;

  /// زر إضافة عام
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get general_add;

  /// زر تأكيد
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get general_confirm;

  /// نص أو عام
  ///
  /// In ar, this message translates to:
  /// **'أو'**
  String get general_or;

  /// رسالة خطأ عامة
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ ما'**
  String get general_something_wrong;

  /// رسالة نجاح عامة
  ///
  /// In ar, this message translates to:
  /// **'تمت العملية بنجاح'**
  String get general_operation_success;

  /// حالة قيد التنفيذ
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get general_in_progress;

  /// اسم التطبيق
  ///
  /// In ar, this message translates to:
  /// **'Fresh Home'**
  String get app_title;

  /// عنوان شريط التنقل السفلي للصفحة الرئيسية
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get nav_home;

  /// عنوان شريط التنقل السفلي لصفحة نقل البيانات
  ///
  /// In ar, this message translates to:
  /// **'نقل البيانات'**
  String get nav_data_transfer;

  /// عنوان شريط التنقل السفلي للملف الشخصي
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get nav_profile;

  /// عنوان شريط التنقل السفلي لإدارة المستخدمين
  ///
  /// In ar, this message translates to:
  /// **'إدارة المستخدمين'**
  String get nav_user_management;

  /// رسالة ترحيب شاشة الأون بوردنج
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا في Fresh Home'**
  String get onboarding_welcome_title;

  /// عنوان شاشة الإعدادات
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings_title;

  /// عنوان اختيار الثيم
  ///
  /// In ar, this message translates to:
  /// **'الثيم'**
  String get settings_theme;

  /// الوضع الفاتح
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get settings_theme_light;

  /// الوضع الداكن
  ///
  /// In ar, this message translates to:
  /// **'غامق'**
  String get settings_theme_dark;

  /// تبديل الوضع الداكن
  ///
  /// In ar, this message translates to:
  /// **'الوضع الداكن'**
  String get settings_dark_mode;

  /// اختيار اللغة
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get settings_language;

  /// اللغة العربية
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get settings_language_arabic;

  /// No description provided for @settings_header_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص التطبيق والتحكم في حسابك'**
  String get settings_header_subtitle;

  /// No description provided for @settings_section_preferences.
  ///
  /// In ar, this message translates to:
  /// **'التفضيلات'**
  String get settings_section_preferences;

  /// No description provided for @settings_section_account.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get settings_section_account;

  /// No description provided for @settings_section_admin.
  ///
  /// In ar, this message translates to:
  /// **'الإدارة'**
  String get settings_section_admin;

  /// No description provided for @settings_section_about.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get settings_section_about;

  /// No description provided for @settings_services_management.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الخدمات'**
  String get settings_services_management;

  /// No description provided for @settings_services_management_desc.
  ///
  /// In ar, this message translates to:
  /// **'إدارة وتعديل الفئات والخدمات الفرعية'**
  String get settings_services_management_desc;

  /// اللغة الإنجليزية
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get settings_language_english;

  /// زر تسجيل الخروج
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get settings_sign_out;

  /// رسالة تأكيد تسجيل الخروج
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في تسجيل الخروج؟'**
  String get settings_sign_out_confirmation;

  /// عنوان الملف الشخصي
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile_title;

  /// حقل الاسم الأول
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأول'**
  String get profile_first_name;

  /// حقل اسم العائلة
  ///
  /// In ar, this message translates to:
  /// **'اسم العائلة'**
  String get profile_last_name;

  /// زر حفظ الاسم
  ///
  /// In ar, this message translates to:
  /// **'حفظ الاسم'**
  String get profile_save_name;

  /// زر إضافة رقم هاتف
  ///
  /// In ar, this message translates to:
  /// **'إضافة رقم'**
  String get phone_add_button;

  /// قسم العناوين
  ///
  /// In ar, this message translates to:
  /// **'العناوين'**
  String get address_section_title;

  /// إضافة عنوان جديد
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان جديد'**
  String get address_add_new;

  /// حقل المحافظة
  ///
  /// In ar, this message translates to:
  /// **'المحافظة'**
  String get address_governorate;

  /// حقل المدينة
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get address_city;

  /// حقل الشارع
  ///
  /// In ar, this message translates to:
  /// **'الشارع'**
  String get address_street;

  /// حقل رقم المبنى
  ///
  /// In ar, this message translates to:
  /// **'رقم المبنى'**
  String get address_building_number;

  /// حقل رقم الشقة
  ///
  /// In ar, this message translates to:
  /// **'رقم الشقة'**
  String get address_apartment_number;

  /// حقل رقم الطابق
  ///
  /// In ar, this message translates to:
  /// **'رقم الطابق'**
  String get address_floor_number;

  /// زر إضافة عنوان
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان'**
  String get address_add_button;

  /// عنوان تعديل العنوان
  ///
  /// In ar, this message translates to:
  /// **'تعديل العنوان'**
  String get address_edit_title;

  /// عنوان شاشة تسجيل الدخول
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login_title;

  /// حقل البريد الإلكتروني
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get login_email_label;

  /// حقل كلمة المرور
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get login_password_label;

  /// رسالة ترحيب شاشة تسجيل الدخول
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك! سجّل الدخول واستمتع بخدماتنا بسهولة وأمان.'**
  String get login_intro_message;

  /// جملة ليس لديك حساب
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get login_dont_have_account;

  /// جملة لديك حساب بالفعل
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get login_already_have_account;

  /// زر إنشاء حساب
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get login_signup_button;

  /// زر تسجيل الدخول باستخدام جوجل
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول باستخدام جوجل'**
  String get login_sign_in_google;

  /// رسالة نجاح تسجيل الدخول
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول بنجاح'**
  String get login_success_message;

  /// عنوان شاشة إنشاء حساب
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get signup_title;

  /// رسالة نجاح إنشاء الحساب
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الحساب بنجاح'**
  String get signup_success_message;

  /// عنوان شاشة الترحيب
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا في Fresh Home'**
  String get onboarding_title_1;

  /// وصف شاشة الترحيب
  ///
  /// In ar, this message translates to:
  /// **'كل اللي بيتك محتاجه في مكان واحد! خدمات تنظيف، صيانة، وإبادة حشرية باحترافية وجودة عالية توصلك لحد باب بيتك.'**
  String get onboarding_description_1;

  /// عنوان شاشة خدمات متنوعة
  ///
  /// In ar, this message translates to:
  /// **'خدمات متنوعة لراحتكم'**
  String get onboarding_title_2;

  /// وصف شاشة خدمات متنوعة
  ///
  /// In ar, this message translates to:
  /// **'✔ فريق محترف في كل خدمة ✔ أسعار مناسبة وجودة عالية ✔ التزام بالمواعيد وسهولة في الحجز'**
  String get onboarding_description_2;

  /// عنوان شاشة احجز خدمتك في 3 خطوات
  ///
  /// In ar, this message translates to:
  /// **'احجز خدمتك في 3 خطوات'**
  String get onboarding_title_3;

  /// وصف شاشة احجز خدمتك في 3 خطوات
  ///
  /// In ar, this message translates to:
  /// **'1- اختر نوع الخدمة (تنظيف – صيانة – إبادة)\n2- حدّد الوقت والمكان\n3- استمتع براحة البال والنتيجة التي تتمناها'**
  String get onboarding_description_3;

  /// عنوان شاشة خلّي بيتك في أمان مع Fresh Home
  ///
  /// In ar, this message translates to:
  /// **'اجعل منزلك في أمان مع \nFresh Home'**
  String get onboarding_title_4;

  /// وصف شاشة خلّي بيتك في أمان مع Fresh Home
  ///
  /// In ar, this message translates to:
  /// **'آلاف العملاء جربوا خدماتنا وشعروا بالفرق. احجز خدمتك الآن وابدأ أول خطوة نحو بيت نظيف وآمن.'**
  String get onboarding_description_4;

  /// الإيميل غير صحيح
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير صحيح'**
  String get invalid_email;

  /// حساب متوقف
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب معطل'**
  String get user_disabled;

  /// حساب مفقود
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد حساب مسجل بهذا البريد الإلكتروني'**
  String get user_not_found;

  /// الباسورد غلط
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور غير صحيحة'**
  String get wrong_password;

  /// الإيميل مستخدم بالفعل
  ///
  /// In ar, this message translates to:
  /// **'هذا البريد الإلكتروني مستخدم بالفعل'**
  String get email_already_in_use;

  /// عملية غير مسموحة
  ///
  /// In ar, this message translates to:
  /// **'عملية إنشاء الحسابات غير مفعلة حالياً'**
  String get operation_not_allowed;

  /// الباسورد ضعيف
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور ضعيفة جداً'**
  String get weak_password;

  /// مشكلة في النت
  ///
  /// In ar, this message translates to:
  /// **'مشكلة في الاتصال بالإنترنت، يرجى التحقق من الشبكة'**
  String get network_request_failed;

  /// محاولات كتير
  ///
  /// In ar, this message translates to:
  /// **'محاولات عديدة، يرجى المحاولة بعد قليل'**
  String get too_many_requests;

  /// خطاء داخلي
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ داخلي، يرجى المحاولة مرة أخرى'**
  String get internal_error;

  /// بيانات الدخول غير صحيحة
  ///
  /// In ar, this message translates to:
  /// **'بيانات الدخول غير صحيحة'**
  String get invalid_credential;

  /// البريد الإلكتروني غير مفعل
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير مفعل'**
  String get email_not_verified;

  /// أعد إرسال التحقق
  ///
  /// In ar, this message translates to:
  /// **'أعد إرسال التحقق'**
  String get resend_verification;

  /// كود التحقق غير صحيح
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق غير صحيح'**
  String get invalid_verification_code;

  /// حصلت مشكلة في التحقق
  ///
  /// In ar, this message translates to:
  /// **'حدثت مشكلة أثناء عملية التحقق'**
  String get invalid_verification_id;

  /// التحقق الأمني فشل
  ///
  /// In ar, this message translates to:
  /// **'فشل التحقق الأمني، يرجى المحاولة مرة أخرى'**
  String get captcha_check_failed;

  /// الجلسة انتهت
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة، يرجى المحاولة مرة أخرى'**
  String get session_expired;

  /// تم الوصول للحد الأقصى
  ///
  /// In ar, this message translates to:
  /// **'تم الوصول للحد الأقصى، يرجى المحاولة لاحقاً'**
  String get quota_exceeded;

  /// الإيميل مطلوب
  ///
  /// In ar, this message translates to:
  /// **'الإيميل مطلوب'**
  String get missing_email;

  /// خطاء غير متوقع
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ غير متوقع'**
  String get unknown_error;

  /// No description provided for @booking_appbar_title.
  ///
  /// In ar, this message translates to:
  /// **'احجز خدمتك'**
  String get booking_appbar_title;

  /// No description provided for @booking_calculate_button.
  ///
  /// In ar, this message translates to:
  /// **'احسب'**
  String get booking_calculate_button;

  /// No description provided for @booking_confirm_button.
  ///
  /// In ar, this message translates to:
  /// **'أكد حجزك'**
  String get booking_confirm_button;

  /// No description provided for @pricing_area_label.
  ///
  /// In ar, this message translates to:
  /// **'مساحة البيت'**
  String get pricing_area_label;

  /// No description provided for @pricing_area_unit.
  ///
  /// In ar, this message translates to:
  /// **'متر مربع'**
  String get pricing_area_unit;

  /// No description provided for @pricing_base_price.
  ///
  /// In ar, this message translates to:
  /// **'السعر الأساسي'**
  String get pricing_base_price;

  /// No description provided for @pricing_service_fee.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف الخدمة'**
  String get pricing_service_fee;

  /// No description provided for @pricing_total_estimated.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي السعر التقديري'**
  String get pricing_total_estimated;

  /// No description provided for @pricing_currency.
  ///
  /// In ar, this message translates to:
  /// **'جنيه'**
  String get pricing_currency;

  /// No description provided for @pricing_currency_short.
  ///
  /// In ar, this message translates to:
  /// **'ج.م'**
  String get pricing_currency_short;

  /// No description provided for @schedule_selected_service.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة المختارة'**
  String get schedule_selected_service;

  /// No description provided for @schedule_estimated_price.
  ///
  /// In ar, this message translates to:
  /// **'السعر التقديري'**
  String get schedule_estimated_price;

  /// No description provided for @schedule_choose_day.
  ///
  /// In ar, this message translates to:
  /// **'اختار اليوم'**
  String get schedule_choose_day;

  /// No description provided for @schedule_choose_manually.
  ///
  /// In ar, this message translates to:
  /// **'اختار بنفسك'**
  String get schedule_choose_manually;

  /// No description provided for @schedule_available_times.
  ///
  /// In ar, this message translates to:
  /// **'المواعيد الموجودة'**
  String get schedule_available_times;

  /// No description provided for @schedule_availability_available.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get schedule_availability_available;

  /// No description provided for @schedule_availability_full.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get schedule_availability_full;

  /// No description provided for @address_details_title.
  ///
  /// In ar, this message translates to:
  /// **'بيانات العنوان'**
  String get address_details_title;

  /// No description provided for @address_contact_title.
  ///
  /// In ar, this message translates to:
  /// **'بيانات التواصل'**
  String get address_contact_title;

  /// No description provided for @phone_section_title.
  ///
  /// In ar, this message translates to:
  /// **'رقم التواصل'**
  String get phone_section_title;

  /// No description provided for @phone_primary_label.
  ///
  /// In ar, this message translates to:
  /// **'أساسي'**
  String get phone_primary_label;

  /// No description provided for @add_new_phone.
  ///
  /// In ar, this message translates to:
  /// **'إضافة رقم جديد'**
  String get add_new_phone;

  /// No description provided for @add_new_address.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان جديد'**
  String get add_new_address;

  /// No description provided for @address_select_governorate_first.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار المحافظة أولاً'**
  String get address_select_governorate_first;

  /// No description provided for @address_select_city.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار المنطقة'**
  String get address_select_city;

  /// No description provided for @address_governorate_label.
  ///
  /// In ar, this message translates to:
  /// **'المحافظة'**
  String get address_governorate_label;

  /// No description provided for @address_region_label.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get address_region_label;

  /// No description provided for @address_street_label.
  ///
  /// In ar, this message translates to:
  /// **'اسم الشارع'**
  String get address_street_label;

  /// No description provided for @address_street_hint.
  ///
  /// In ar, this message translates to:
  /// **'اسم الشارع'**
  String get address_street_hint;

  /// No description provided for @address_building_label.
  ///
  /// In ar, this message translates to:
  /// **'رقم العمارة'**
  String get address_building_label;

  /// No description provided for @address_floor_label.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get address_floor_label;

  /// No description provided for @address_apartment_label.
  ///
  /// In ar, this message translates to:
  /// **'رقم الشقة'**
  String get address_apartment_label;

  /// No description provided for @address_gov_cairo.
  ///
  /// In ar, this message translates to:
  /// **'القاهرة'**
  String get address_gov_cairo;

  /// No description provided for @address_gov_giza.
  ///
  /// In ar, this message translates to:
  /// **'الجيزة'**
  String get address_gov_giza;

  /// No description provided for @address_city_zamalek.
  ///
  /// In ar, this message translates to:
  /// **'الزمالك'**
  String get address_city_zamalek;

  /// No description provided for @address_city_garden_city.
  ///
  /// In ar, this message translates to:
  /// **'جاردن سيتي'**
  String get address_city_garden_city;

  /// No description provided for @address_city_maadi.
  ///
  /// In ar, this message translates to:
  /// **'المعادي'**
  String get address_city_maadi;

  /// No description provided for @address_city_heliopolis.
  ///
  /// In ar, this message translates to:
  /// **'مصر الجديدة'**
  String get address_city_heliopolis;

  /// No description provided for @address_city_fifth_settlement.
  ///
  /// In ar, this message translates to:
  /// **'التجمع الخامس'**
  String get address_city_fifth_settlement;

  /// No description provided for @address_city_new_cairo.
  ///
  /// In ar, this message translates to:
  /// **'القاهرة الجديدة'**
  String get address_city_new_cairo;

  /// No description provided for @address_city_rehab.
  ///
  /// In ar, this message translates to:
  /// **'الرحاب'**
  String get address_city_rehab;

  /// No description provided for @address_city_madinaty.
  ///
  /// In ar, this message translates to:
  /// **'مدينتي'**
  String get address_city_madinaty;

  /// No description provided for @address_city_nasr_city.
  ///
  /// In ar, this message translates to:
  /// **'مدينة نصر'**
  String get address_city_nasr_city;

  /// No description provided for @address_city_mokattam.
  ///
  /// In ar, this message translates to:
  /// **'المقطم'**
  String get address_city_mokattam;

  /// No description provided for @address_city_shorouk.
  ///
  /// In ar, this message translates to:
  /// **'الشروق'**
  String get address_city_shorouk;

  /// No description provided for @address_city_zayed.
  ///
  /// In ar, this message translates to:
  /// **'الشيخ زايد'**
  String get address_city_zayed;

  /// No description provided for @address_city_october.
  ///
  /// In ar, this message translates to:
  /// **'6 أكتوبر'**
  String get address_city_october;

  /// No description provided for @address_city_mohandessin.
  ///
  /// In ar, this message translates to:
  /// **'المهندسين'**
  String get address_city_mohandessin;

  /// No description provided for @address_city_dokki.
  ///
  /// In ar, this message translates to:
  /// **'الدقي'**
  String get address_city_dokki;

  /// No description provided for @address_city_agouza.
  ///
  /// In ar, this message translates to:
  /// **'العجوزة'**
  String get address_city_agouza;

  /// No description provided for @address_city_hadayek_ahram.
  ///
  /// In ar, this message translates to:
  /// **'حدائق الأهرام'**
  String get address_city_hadayek_ahram;

  /// No description provided for @address_city_haram.
  ///
  /// In ar, this message translates to:
  /// **'الهرم'**
  String get address_city_haram;

  /// No description provided for @address_city_faisal.
  ///
  /// In ar, this message translates to:
  /// **'فيصل'**
  String get address_city_faisal;

  /// No description provided for @address_city_imbaba.
  ///
  /// In ar, this message translates to:
  /// **'إمبابة'**
  String get address_city_imbaba;

  /// No description provided for @address_city_other.
  ///
  /// In ar, this message translates to:
  /// **'منطقة أخرى'**
  String get address_city_other;

  /// No description provided for @address_city_other_label.
  ///
  /// In ar, this message translates to:
  /// **'أدخل المنطقة أو الحي'**
  String get address_city_other_label;

  /// No description provided for @address_city_other_hint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب هنا...'**
  String get address_city_other_hint;

  /// No description provided for @address_full_name_label.
  ///
  /// In ar, this message translates to:
  /// **'اسمك بالكامل'**
  String get address_full_name_label;

  /// No description provided for @address_full_name_hint.
  ///
  /// In ar, this message translates to:
  /// **'أكتب اسمك هنا'**
  String get address_full_name_hint;

  /// No description provided for @address_phone_label.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get address_phone_label;

  /// No description provided for @address_landmark_label.
  ///
  /// In ar, this message translates to:
  /// **'علامة مميزة / ملاحظات (اختياري)'**
  String get address_landmark_label;

  /// No description provided for @address_landmark_hint.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات إضافية'**
  String get address_landmark_hint;

  /// No description provided for @manual_client_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم العميل'**
  String get manual_client_name;

  /// No description provided for @manual_client_phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get manual_client_phone;

  /// No description provided for @notifications_title.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get notifications_title;

  /// No description provided for @notifications_mark_all_read.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل كمقروء'**
  String get notifications_mark_all_read;

  /// No description provided for @notifications_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد تنبيهات حالياً'**
  String get notifications_empty;

  /// No description provided for @notifications_empty_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'خليك متابع، هنبعتلك كل جديد هنا'**
  String get notifications_empty_subtitle;

  /// No description provided for @notifications_tab_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get notifications_tab_all;

  /// No description provided for @notifications_tab_orders.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get notifications_tab_orders;

  /// No description provided for @notifications_tab_system.
  ///
  /// In ar, this message translates to:
  /// **'النظام'**
  String get notifications_tab_system;

  /// No description provided for @notifications_empty_orders.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد تنبيهات طلبات حالياً'**
  String get notifications_empty_orders;

  /// No description provided for @notifications_empty_system.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد تنبيهات للنظام حالياً'**
  String get notifications_empty_system;

  /// No description provided for @confirmation_area.
  ///
  /// In ar, this message translates to:
  /// **'المساحة'**
  String get confirmation_area;

  /// No description provided for @booking_success_close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get booking_success_close;

  /// No description provided for @confirmation_payment_method.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get confirmation_payment_method;

  /// No description provided for @confirmation_payment_cash.
  ///
  /// In ar, this message translates to:
  /// **'دفع كاش بعد الخدمة'**
  String get confirmation_payment_cash;

  /// No description provided for @booking_success_title.
  ///
  /// In ar, this message translates to:
  /// **'حجزك تم بنجاح!'**
  String get booking_success_title;

  /// No description provided for @booking_id_label.
  ///
  /// In ar, this message translates to:
  /// **'كود الحجز'**
  String get booking_id_label;

  /// No description provided for @booking_success_message.
  ///
  /// In ar, this message translates to:
  /// **'سنتواصل معك قريباً لتأكيد الموعد.'**
  String get booking_success_message;

  /// No description provided for @general_ok.
  ///
  /// In ar, this message translates to:
  /// **'موافق'**
  String get general_ok;

  /// No description provided for @confirmation_review_title.
  ///
  /// In ar, this message translates to:
  /// **'راجع طلبك'**
  String get confirmation_review_title;

  /// No description provided for @confirmation_service_type.
  ///
  /// In ar, this message translates to:
  /// **'نوع الخدمة'**
  String get confirmation_service_type;

  /// No description provided for @confirmation_delivery_time.
  ///
  /// In ar, this message translates to:
  /// **'ميعاد الخدمة'**
  String get confirmation_delivery_time;

  /// No description provided for @confirmation_no_address.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تحديد العنوان'**
  String get confirmation_no_address;

  /// No description provided for @error_pricing_data_unavailable.
  ///
  /// In ar, this message translates to:
  /// **'بيانات التسعير غير متوفرة'**
  String get error_pricing_data_unavailable;

  /// No description provided for @validation_time_required.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال الوقت'**
  String get validation_time_required;

  /// No description provided for @validation_time_format.
  ///
  /// In ar, this message translates to:
  /// **'تنسيق الوقت غير صحيح'**
  String get validation_time_format;

  /// No description provided for @validation_time_range.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يكون الوقت بين 9 صباحاً و 6 مساءً'**
  String get validation_time_range;

  /// No description provided for @validation_area_required.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال المساحة'**
  String get validation_area_required;

  /// No description provided for @validation_number_invalid.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال رقم صحيح'**
  String get validation_number_invalid;

  /// No description provided for @validation_number_positive.
  ///
  /// In ar, this message translates to:
  /// **'يجب إدخال رقم أكبر من الصفر'**
  String get validation_number_positive;

  /// No description provided for @validation_digits_only.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال أرقام فقط'**
  String get validation_digits_only;

  /// No description provided for @validation_date_required.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال التاريخ'**
  String get validation_date_required;

  /// No description provided for @validation_date_format.
  ///
  /// In ar, this message translates to:
  /// **'تنسيق التاريخ غير صحيح'**
  String get validation_date_format;

  /// No description provided for @validation_date_past.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن اختيار تاريخ قديم'**
  String get validation_date_past;

  /// No description provided for @validation_date_too_far.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن اختيار تاريخ يتجاوز 60 يوماً من الآن'**
  String get validation_date_too_far;

  /// No description provided for @validation_phone_required.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال رقم الهاتف'**
  String get validation_phone_required;

  /// No description provided for @validation_phone_invalid.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال رقم هاتف مصري صحيح'**
  String get validation_phone_invalid;

  /// No description provided for @validation_selection_required.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار عنصر من القائمة'**
  String get validation_selection_required;

  /// No description provided for @validation_required.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن ترك هذا الحقل فارغاً'**
  String get validation_required;

  /// No description provided for @validation_email_required.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال البريد الإلكتروني'**
  String get validation_email_required;

  /// No description provided for @validation_email_invalid.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال بريد إلكتروني صحيح'**
  String get validation_email_invalid;

  /// No description provided for @validation_schedule_required.
  ///
  /// In ar, this message translates to:
  /// **'برجاء اختيار اليوم المناسب وموعد الوصول'**
  String get validation_schedule_required;

  /// No description provided for @validation_address_selection_required.
  ///
  /// In ar, this message translates to:
  /// **'برجاء اختيار العنوان المناسب للمهمة'**
  String get validation_address_selection_required;

  /// No description provided for @validation_phone_selection_required.
  ///
  /// In ar, this message translates to:
  /// **'برجاء اختيار رقم التواصل المناسب'**
  String get validation_phone_selection_required;

  /// No description provided for @schedule_selection_info.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار اليوم والموعد المناسبين لوصول الفني.'**
  String get schedule_selection_info;

  /// No description provided for @error_incomplete_data.
  ///
  /// In ar, this message translates to:
  /// **'يرجى استكمال جميع البيانات'**
  String get error_incomplete_data;

  /// No description provided for @error_booking_id_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل في إنشاء رقم الحجز. حاول مرة أخرى.'**
  String get error_booking_id_failed;

  /// No description provided for @booking_step_progress.
  ///
  /// In ar, this message translates to:
  /// **'خطوة'**
  String get booking_step_progress;

  /// No description provided for @booking_step_1_title.
  ///
  /// In ar, this message translates to:
  /// **'المساحة'**
  String get booking_step_1_title;

  /// No description provided for @booking_step_2_title.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get booking_step_2_title;

  /// No description provided for @booking_step_3_title.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get booking_step_3_title;

  /// No description provided for @booking_step_4_title.
  ///
  /// In ar, this message translates to:
  /// **'التأكيد'**
  String get booking_step_4_title;

  /// No description provided for @booking_step_1_desc.
  ///
  /// In ar, this message translates to:
  /// **'المساحة والسعر'**
  String get booking_step_1_desc;

  /// No description provided for @booking_step_2_desc.
  ///
  /// In ar, this message translates to:
  /// **'اليوم والميعاد'**
  String get booking_step_2_desc;

  /// No description provided for @booking_step_3_desc.
  ///
  /// In ar, this message translates to:
  /// **'بيانات العنوان'**
  String get booking_step_3_desc;

  /// No description provided for @booking_step_4_desc.
  ///
  /// In ar, this message translates to:
  /// **'أكد حجزك'**
  String get booking_step_4_desc;

  /// رسالة نجاح إرسال بريد التحقق
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال بريد التحقق بنجاح'**
  String get verification_email_sent;

  /// وصف طلب تفعيل البريد
  ///
  /// In ar, this message translates to:
  /// **'يرجى التحقق من بريدك الإلكتروني والنقر على رابط التفعيل لتنشيط حسابك'**
  String get please_verify_email_desc;

  /// جملة نسيت كلمة المرور
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgot_password;

  /// No description provided for @forgot_password_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني لتلقي رابط إعادة تعيين كلمة المرور.'**
  String get forgot_password_subtitle;

  /// No description provided for @send_reset_link.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رابط الإعادة'**
  String get send_reset_link;

  /// No description provided for @password_reset_sent_success.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رابط إعادة تعيين كلمة المرور! يرجى التحقق من بريدك الإلكتروني.'**
  String get password_reset_sent_success;

  /// No description provided for @address_select_saved_or_add_new.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار عنوان مسجل أو إضافة عنوان جديد'**
  String get address_select_saved_or_add_new;

  /// No description provided for @address_select_saved_phone_or_add_new.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار رقم هاتف مسجل أو إضافة رقم جديد'**
  String get address_select_saved_phone_or_add_new;

  /// No description provided for @admin_header_badge.
  ///
  /// In ar, this message translates to:
  /// **'لوحة المسؤول'**
  String get admin_header_badge;

  /// No description provided for @admin_header_title.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الخدمات'**
  String get admin_header_title;

  /// No description provided for @admin_header_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'قم بإضافة وتعديل فئات الخدمات والخدمات الفرعية'**
  String get admin_header_subtitle;

  /// No description provided for @admin_add_category.
  ///
  /// In ar, this message translates to:
  /// **'إضافة فئة'**
  String get admin_add_category;

  /// No description provided for @admin_empty_categories.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فئات خدمات حالياً'**
  String get admin_empty_categories;

  /// No description provided for @admin_add_prompt.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على زر الإضافة للبدء'**
  String get admin_add_prompt;

  /// No description provided for @admin_service_status_active.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get admin_service_status_active;

  /// No description provided for @admin_service_status_inactive.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط'**
  String get admin_service_status_inactive;

  /// No description provided for @admin_service_status_draft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get admin_service_status_draft;

  /// No description provided for @admin_delete_confirm_title.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get admin_delete_confirm_title;

  /// No description provided for @admin_category_delete_content.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في حذف هذه الفئة؟ سيؤدي ذلك لحذف كافة الخدمات الفرعية المرتبطة بها.'**
  String get admin_category_delete_content;

  /// No description provided for @admin_delete_button.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get admin_delete_button;

  /// No description provided for @admin_no_title.
  ///
  /// In ar, this message translates to:
  /// **'بدون عنوان'**
  String get admin_no_title;

  /// No description provided for @admin_edit_advanced_details.
  ///
  /// In ar, this message translates to:
  /// **'تعديل التفاصيل المتقدمة'**
  String get admin_edit_advanced_details;

  /// No description provided for @admin_add_sub_service.
  ///
  /// In ar, this message translates to:
  /// **'إضافة خدمة فرعية'**
  String get admin_add_sub_service;

  /// No description provided for @admin_empty_sub_services.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد خدمات فرعية حالياً'**
  String get admin_empty_sub_services;

  /// No description provided for @admin_sub_services_badge.
  ///
  /// In ar, this message translates to:
  /// **'الخدمات الفرعية'**
  String get admin_sub_services_badge;

  /// No description provided for @admin_sub_services_header_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الخدمات الفرعية المتاحة لهذه الفئة'**
  String get admin_sub_services_header_subtitle;

  /// No description provided for @admin_sub_service_delete_content.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في حذف هذه الخدمة؟ لا يمكن التراجع عن هذا الإجراء.'**
  String get admin_sub_service_delete_content;

  /// No description provided for @admin_form_add_service.
  ///
  /// In ar, this message translates to:
  /// **'إضافة خدمة'**
  String get admin_form_add_service;

  /// No description provided for @admin_form_edit_service.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الخدمة'**
  String get admin_form_edit_service;

  /// No description provided for @admin_form_basic_info.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الأساسية'**
  String get admin_form_basic_info;

  /// No description provided for @admin_form_title_en.
  ///
  /// In ar, this message translates to:
  /// **'العنوان (English)'**
  String get admin_form_title_en;

  /// No description provided for @admin_form_title_ar.
  ///
  /// In ar, this message translates to:
  /// **'العنوان (العربية)'**
  String get admin_form_title_ar;

  /// No description provided for @admin_form_desc_section.
  ///
  /// In ar, this message translates to:
  /// **'وصف الخدمة'**
  String get admin_form_desc_section;

  /// No description provided for @admin_form_desc_en.
  ///
  /// In ar, this message translates to:
  /// **'الوصف (English)'**
  String get admin_form_desc_en;

  /// No description provided for @admin_form_desc_ar.
  ///
  /// In ar, this message translates to:
  /// **'الوصف (العربية)'**
  String get admin_form_desc_ar;

  /// No description provided for @admin_form_media_status.
  ///
  /// In ar, this message translates to:
  /// **'الوسائط والحالة'**
  String get admin_form_media_status;

  /// No description provided for @admin_form_image_url.
  ///
  /// In ar, this message translates to:
  /// **'رابط الصورة (URL)'**
  String get admin_form_image_url;

  /// No description provided for @admin_form_service_status.
  ///
  /// In ar, this message translates to:
  /// **'حالة الخدمة'**
  String get admin_form_service_status;

  /// No description provided for @admin_form_save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ البيانات'**
  String get admin_form_save;

  /// No description provided for @admin_validator_required.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get admin_validator_required;

  /// No description provided for @admin_editor_title.
  ///
  /// In ar, this message translates to:
  /// **'محرر التفاصيل'**
  String get admin_editor_title;

  /// No description provided for @admin_editor_header_badge.
  ///
  /// In ar, this message translates to:
  /// **'محرر التفاصيل'**
  String get admin_editor_header_badge;

  /// No description provided for @admin_editor_header_title.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل المتقدمة'**
  String get admin_editor_header_title;

  /// No description provided for @admin_editor_header_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة النقاط المستثناة وأقسام شرح الخدمة'**
  String get admin_editor_header_subtitle;

  /// No description provided for @admin_editor_section_excluded.
  ///
  /// In ar, this message translates to:
  /// **'ما لا تشمله الخدمة (Excluded)'**
  String get admin_editor_section_excluded;

  /// No description provided for @admin_editor_section_details.
  ///
  /// In ar, this message translates to:
  /// **'أقسام التفاصيل (Details Sections)'**
  String get admin_editor_section_details;

  /// No description provided for @admin_editor_add_section.
  ///
  /// In ar, this message translates to:
  /// **'إضافة قسم تفصيلي جديد'**
  String get admin_editor_add_section;

  /// No description provided for @admin_editor_save_changes.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get admin_editor_save_changes;

  /// No description provided for @admin_editor_empty_details.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أقسام تفصيلية حالياً'**
  String get admin_editor_empty_details;

  /// No description provided for @admin_editor_empty_details_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'أضف أقساماً لشرح محتوى الخدمة ومميزاتها'**
  String get admin_editor_empty_details_subtitle;

  /// No description provided for @admin_editor_section_index.
  ///
  /// In ar, this message translates to:
  /// **'قسم #'**
  String get admin_editor_section_index;

  /// No description provided for @admin_editor_ar_content.
  ///
  /// In ar, this message translates to:
  /// **'المحتوى العربي'**
  String get admin_editor_ar_content;

  /// No description provided for @admin_editor_en_content.
  ///
  /// In ar, this message translates to:
  /// **'English Content'**
  String get admin_editor_en_content;

  /// No description provided for @admin_editor_excluded_ar.
  ///
  /// In ar, this message translates to:
  /// **'النقاط المستثناة (العربية)'**
  String get admin_editor_excluded_ar;

  /// No description provided for @admin_editor_excluded_en.
  ///
  /// In ar, this message translates to:
  /// **'Excluded Points (English)'**
  String get admin_editor_excluded_en;

  /// No description provided for @admin_editor_field_title.
  ///
  /// In ar, this message translates to:
  /// **'العنوان / Title'**
  String get admin_editor_field_title;

  /// No description provided for @admin_editor_field_icon.
  ///
  /// In ar, this message translates to:
  /// **'الأيقونة (رابط أو اسم) / Icon'**
  String get admin_editor_field_icon;

  /// No description provided for @admin_editor_points_label.
  ///
  /// In ar, this message translates to:
  /// **'النقاط / Points:'**
  String get admin_editor_points_label;

  /// No description provided for @admin_editor_add_point.
  ///
  /// In ar, this message translates to:
  /// **'إضافة نقطة'**
  String get admin_editor_add_point;

  /// No description provided for @admin_editor_field_point.
  ///
  /// In ar, this message translates to:
  /// **'نقطة / Point'**
  String get admin_editor_field_point;

  /// No description provided for @admin_editor_section_price.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات التسعير (Pricing Settings)'**
  String get admin_editor_section_price;

  /// No description provided for @admin_editor_field_price_value.
  ///
  /// In ar, this message translates to:
  /// **'السعر الأساسي / Base Price'**
  String get admin_editor_field_price_value;

  /// No description provided for @admin_editor_field_price_unit.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة (ج.م، متر...) / Unit'**
  String get admin_editor_field_price_unit;

  /// No description provided for @admin_editor_pricing_method_label.
  ///
  /// In ar, this message translates to:
  /// **'طريقة التسعير / Pricing Method:'**
  String get admin_editor_pricing_method_label;

  /// No description provided for @admin_editor_method_m2.
  ///
  /// In ar, this message translates to:
  /// **'بالمتر المربع'**
  String get admin_editor_method_m2;

  /// No description provided for @admin_editor_method_ml.
  ///
  /// In ar, this message translates to:
  /// **'بالمتر الطولي'**
  String get admin_editor_method_ml;

  /// No description provided for @admin_editor_method_fixed.
  ///
  /// In ar, this message translates to:
  /// **'سعر ثابت'**
  String get admin_editor_method_fixed;

  /// No description provided for @admin_editor_method_unit.
  ///
  /// In ar, this message translates to:
  /// **'بالوحدة / العدد'**
  String get admin_editor_method_unit;

  /// No description provided for @admin_editor_price_options_label.
  ///
  /// In ar, this message translates to:
  /// **'خيارات التسعير الإضافية / Price Options:'**
  String get admin_editor_price_options_label;

  /// No description provided for @admin_editor_add_option.
  ///
  /// In ar, this message translates to:
  /// **'إضافة خيار تسعير'**
  String get admin_editor_add_option;

  /// No description provided for @admin_editor_field_option_label.
  ///
  /// In ar, this message translates to:
  /// **'اسم الخيار (مثلاً: غرفة صغيرة)'**
  String get admin_editor_field_option_label;

  /// No description provided for @admin_editor_field_option_price.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get admin_editor_field_option_price;

  /// No description provided for @admin_editor_save_button.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get admin_editor_save_button;

  /// No description provided for @general_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get general_retry;

  /// No description provided for @home_user_name_label.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم'**
  String get home_user_name_label;

  /// No description provided for @home_email_label.
  ///
  /// In ar, this message translates to:
  /// **'البريد الالكتروني'**
  String get home_email_label;

  /// No description provided for @home_login_design_test.
  ///
  /// In ar, this message translates to:
  /// **'تصميم تسجيل الدخول (تجريبي)'**
  String get home_login_design_test;

  /// No description provided for @home_our_services.
  ///
  /// In ar, this message translates to:
  /// **'خدماتنا'**
  String get home_our_services;

  /// No description provided for @home_popular_services.
  ///
  /// In ar, this message translates to:
  /// **'الخدمات الأكثر طلباً'**
  String get home_popular_services;

  /// No description provided for @home_price_start_from.
  ///
  /// In ar, this message translates to:
  /// **'السعر يبدأ من'**
  String get home_price_start_from;

  /// No description provided for @home_view_all.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get home_view_all;

  /// No description provided for @nav_my_orders.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get nav_my_orders;

  /// No description provided for @my_orders_title.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get my_orders_title;

  /// No description provided for @my_orders_tab_upcoming.
  ///
  /// In ar, this message translates to:
  /// **'القادمة'**
  String get my_orders_tab_upcoming;

  /// No description provided for @my_orders_tab_today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get my_orders_tab_today;

  /// No description provided for @my_orders_tab_history.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get my_orders_tab_history;

  /// No description provided for @my_orders_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات'**
  String get my_orders_empty;

  /// No description provided for @order_status_pending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get order_status_pending;

  /// No description provided for @order_status_confirmed.
  ///
  /// In ar, this message translates to:
  /// **'مؤكد'**
  String get order_status_confirmed;

  /// No description provided for @order_status_in_progress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get order_status_in_progress;

  /// No description provided for @order_status_completed.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get order_status_completed;

  /// No description provided for @order_status_cancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get order_status_cancelled;

  /// No description provided for @order_id_prefix.
  ///
  /// In ar, this message translates to:
  /// **'طلب #'**
  String get order_id_prefix;

  /// No description provided for @order_total_amount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ الإجمالي'**
  String get order_total_amount;

  /// No description provided for @order_service_details_section.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الخدمة'**
  String get order_service_details_section;

  /// No description provided for @order_service_label.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة'**
  String get order_service_label;

  /// No description provided for @order_date_label.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get order_date_label;

  /// No description provided for @order_time_label.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get order_time_label;

  /// No description provided for @order_contact_section.
  ///
  /// In ar, this message translates to:
  /// **'التواصل والعنوان'**
  String get order_contact_section;

  /// No description provided for @order_client_label.
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get order_client_label;

  /// No description provided for @order_phone_label.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get order_phone_label;

  /// No description provided for @order_full_address_label.
  ///
  /// In ar, this message translates to:
  /// **'العنوان الكامل'**
  String get order_full_address_label;

  /// No description provided for @order_action_edit_time.
  ///
  /// In ar, this message translates to:
  /// **'تعديل موعد الحجز'**
  String get order_action_edit_time;

  /// No description provided for @order_action_cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحجز'**
  String get order_action_cancel;

  /// No description provided for @order_action_reactivate.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تنشيط الطلب'**
  String get order_action_reactivate;

  /// No description provided for @order_action_rebook.
  ///
  /// In ar, this message translates to:
  /// **'إعادة حجز (تكرار الطلب)'**
  String get order_action_rebook;

  /// No description provided for @order_cancel_confirm_title.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحجز'**
  String get order_cancel_confirm_title;

  /// No description provided for @order_cancel_confirm_message.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في إلغاء هذا الحجز؟'**
  String get order_cancel_confirm_message;

  /// No description provided for @order_cancel_success_message.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الحجز بنجاح. يمكنك العثور عليه في سجل الطلبات.'**
  String get order_cancel_success_message;

  /// No description provided for @order_reactivate_success.
  ///
  /// In ar, this message translates to:
  /// **'تم إعادة تنشيط الطلب بنجاح'**
  String get order_reactivate_success;

  /// No description provided for @edit_schedule_success_datetime.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث التاريخ والوقت بنجاح إلى {date} في {time}'**
  String edit_schedule_success_datetime(Object date, Object time);

  /// No description provided for @edit_schedule_success_date.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث التاريخ بنجاح إلى {date}'**
  String edit_schedule_success_date(Object date);

  /// No description provided for @edit_schedule_success_time.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث وقت الحجز بنجاح إلى {time}'**
  String edit_schedule_success_time(Object time);

  /// No description provided for @technician_orders_title.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الفني'**
  String get technician_orders_title;

  /// No description provided for @technician_orders_tab_upcoming.
  ///
  /// In ar, this message translates to:
  /// **'القادمة'**
  String get technician_orders_tab_upcoming;

  /// No description provided for @technician_orders_tab_today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get technician_orders_tab_today;

  /// No description provided for @technician_orders_tab_history.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get technician_orders_tab_history;

  /// No description provided for @technician_orders_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد إمكانية للحجز حالياً من فضلك تواصل مع الإدارة لفتح إمكانية الحجز'**
  String get technician_orders_empty;

  /// No description provided for @technician_contact_customer.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع العميل'**
  String get technician_contact_customer;

  /// No description provided for @technician_contact_method.
  ///
  /// In ar, this message translates to:
  /// **'اختر وسيلة التواصل'**
  String get technician_contact_method;

  /// No description provided for @technician_contact_phone.
  ///
  /// In ar, this message translates to:
  /// **'اتصال هاتفي'**
  String get technician_contact_phone;

  /// No description provided for @technician_contact_whatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get technician_contact_whatsapp;

  /// No description provided for @technician_contact_btn.
  ///
  /// In ar, this message translates to:
  /// **'تواصل'**
  String get technician_contact_btn;

  /// No description provided for @tech_dashboard_title.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get tech_dashboard_title;

  /// No description provided for @tech_greeting_morning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير،'**
  String get tech_greeting_morning;

  /// No description provided for @tech_status_online.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get tech_status_online;

  /// No description provided for @tech_status_offline.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get tech_status_offline;

  /// No description provided for @tech_stats_jobs_today.
  ///
  /// In ar, this message translates to:
  /// **'عدد طلبات اليوم'**
  String get tech_stats_jobs_today;

  /// No description provided for @tech_stats_earnings.
  ///
  /// In ar, this message translates to:
  /// **'الدخل'**
  String get tech_stats_earnings;

  /// No description provided for @tech_stats_rating.
  ///
  /// In ar, this message translates to:
  /// **'التقييم'**
  String get tech_stats_rating;

  /// No description provided for @tech_stats_acceptance.
  ///
  /// In ar, this message translates to:
  /// **'نسبة القبول'**
  String get tech_stats_acceptance;

  /// No description provided for @tech_quick_tools_title.
  ///
  /// In ar, this message translates to:
  /// **'أدوات سريعة'**
  String get tech_quick_tools_title;

  /// No description provided for @tech_tool_wallet.
  ///
  /// In ar, this message translates to:
  /// **'المحفظة'**
  String get tech_tool_wallet;

  /// No description provided for @tech_tool_schedule.
  ///
  /// In ar, this message translates to:
  /// **'الجدول'**
  String get tech_tool_schedule;

  /// No description provided for @tech_tool_reviews.
  ///
  /// In ar, this message translates to:
  /// **'التقييمات'**
  String get tech_tool_reviews;

  /// No description provided for @tech_tool_support.
  ///
  /// In ar, this message translates to:
  /// **'الدعم'**
  String get tech_tool_support;

  /// No description provided for @tech_active_job_title.
  ///
  /// In ar, this message translates to:
  /// **'المهمة النشطة'**
  String get tech_active_job_title;

  /// No description provided for @tech_job_status_upcoming.
  ///
  /// In ar, this message translates to:
  /// **'قادمة'**
  String get tech_job_status_upcoming;

  /// No description provided for @tech_job_status_accepted.
  ///
  /// In ar, this message translates to:
  /// **'مقبولة'**
  String get tech_job_status_accepted;

  /// No description provided for @tech_job_status_in_progress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get tech_job_status_in_progress;

  /// No description provided for @tech_job_status_completed.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get tech_job_status_completed;

  /// No description provided for @tech_action_start_job.
  ///
  /// In ar, this message translates to:
  /// **'بدأ المهمة'**
  String get tech_action_start_job;

  /// No description provided for @tech_action_view_details.
  ///
  /// In ar, this message translates to:
  /// **'عرض التفاصيل'**
  String get tech_action_view_details;

  /// No description provided for @tech_action_accept.
  ///
  /// In ar, this message translates to:
  /// **'قبول الطلب'**
  String get tech_action_accept;

  /// No description provided for @tech_action_complete.
  ///
  /// In ar, this message translates to:
  /// **'إتمام المهمة'**
  String get tech_action_complete;

  /// No description provided for @tech_action_decline.
  ///
  /// In ar, this message translates to:
  /// **'اعتذار'**
  String get tech_action_decline;

  /// No description provided for @tech_status_timeline_assigned.
  ///
  /// In ar, this message translates to:
  /// **'أوردر جديد'**
  String get tech_status_timeline_assigned;

  /// No description provided for @tech_status_timeline_accepted.
  ///
  /// In ar, this message translates to:
  /// **'مقبول'**
  String get tech_status_timeline_accepted;

  /// No description provided for @tech_status_timeline_in_progress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get tech_status_timeline_in_progress;

  /// No description provided for @tech_status_timeline_completed.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get tech_status_timeline_completed;

  /// No description provided for @tech_details_customer_info.
  ///
  /// In ar, this message translates to:
  /// **'بيانات العميل'**
  String get tech_details_customer_info;

  /// No description provided for @tech_details_service_info.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الخدمة'**
  String get tech_details_service_info;

  /// No description provided for @tech_details_location_info.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الموقع'**
  String get tech_details_location_info;

  /// No description provided for @tech_details_timeline_title.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطلب'**
  String get tech_details_timeline_title;

  /// No description provided for @tech_details_decline_order.
  ///
  /// In ar, this message translates to:
  /// **'الاعتذار عن الطلب'**
  String get tech_details_decline_order;

  /// No description provided for @tech_action_on_the_way.
  ///
  /// In ar, this message translates to:
  /// **'أنا في الطريق'**
  String get tech_action_on_the_way;

  /// No description provided for @tech_status_timeline_on_the_way.
  ///
  /// In ar, this message translates to:
  /// **'في الطريق'**
  String get tech_status_timeline_on_the_way;

  /// No description provided for @tech_status_timeline_arrived.
  ///
  /// In ar, this message translates to:
  /// **'وصلت للموقع'**
  String get tech_status_timeline_arrived;

  /// No description provided for @tech_action_start_job_locked.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن البدء قبل الموعد'**
  String get tech_action_start_job_locked;

  /// No description provided for @tech_details_confirm_action.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الإجراء'**
  String get tech_details_confirm_action;

  /// No description provided for @profile_gender_label.
  ///
  /// In ar, this message translates to:
  /// **'الجنس'**
  String get profile_gender_label;

  /// No description provided for @gender_unspecified.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get gender_unspecified;

  /// No description provided for @gender_male.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get gender_male;

  /// No description provided for @gender_female.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get gender_female;

  /// No description provided for @error_occurred.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ ما'**
  String get error_occurred;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @role_client.
  ///
  /// In ar, this message translates to:
  /// **'عميل'**
  String get role_client;

  /// No description provided for @role_technician.
  ///
  /// In ar, this message translates to:
  /// **'فني'**
  String get role_technician;

  /// No description provided for @role_admin.
  ///
  /// In ar, this message translates to:
  /// **'مسؤول النظام'**
  String get role_admin;

  /// No description provided for @status_active.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get status_active;

  /// No description provided for @status_suspended.
  ///
  /// In ar, this message translates to:
  /// **'موقوف'**
  String get status_suspended;

  /// No description provided for @status_pending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get status_pending;

  /// No description provided for @status_banned.
  ///
  /// In ar, this message translates to:
  /// **'محظور'**
  String get status_banned;

  /// No description provided for @dialog_exit_title.
  ///
  /// In ar, this message translates to:
  /// **'الخروج من التطبيق'**
  String get dialog_exit_title;

  /// No description provided for @dialog_exit_message.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في إغلاق التطبيق؟'**
  String get dialog_exit_message;

  /// No description provided for @dialog_exit_confirm.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get dialog_exit_confirm;

  /// No description provided for @dialog_exit_cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get dialog_exit_cancel;

  /// No description provided for @smart_schedule_title.
  ///
  /// In ar, this message translates to:
  /// **'جدولي'**
  String get smart_schedule_title;

  /// No description provided for @workload.
  ///
  /// In ar, this message translates to:
  /// **'حجم العمل'**
  String get workload;

  /// No description provided for @capacity.
  ///
  /// In ar, this message translates to:
  /// **'السعة'**
  String get capacity;

  /// No description provided for @risk.
  ///
  /// In ar, this message translates to:
  /// **'المخاطرة'**
  String get risk;

  /// No description provided for @status_recommended.
  ///
  /// In ar, this message translates to:
  /// **'موصى به'**
  String get status_recommended;

  /// No description provided for @status_normal.
  ///
  /// In ar, this message translates to:
  /// **'طبيعي'**
  String get status_normal;

  /// No description provided for @status_restricted.
  ///
  /// In ar, this message translates to:
  /// **'محدود'**
  String get status_restricted;

  /// No description provided for @status_overloaded.
  ///
  /// In ar, this message translates to:
  /// **'مزدحم جداً'**
  String get status_overloaded;

  /// No description provided for @status_day_off.
  ///
  /// In ar, this message translates to:
  /// **'يوم راحة'**
  String get status_day_off;

  /// No description provided for @schedule_status_clear.
  ///
  /// In ar, this message translates to:
  /// **'خالٍ'**
  String get schedule_status_clear;

  /// No description provided for @schedule_status_available.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get schedule_status_available;

  /// No description provided for @schedule_status_full.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get schedule_status_full;

  /// No description provided for @admin_dashboard_title.
  ///
  /// In ar, this message translates to:
  /// **'متابعة أسطول العمليات'**
  String get admin_dashboard_title;

  /// No description provided for @utilization.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الإشغال'**
  String get utilization;

  /// No description provided for @total_capacity.
  ///
  /// In ar, this message translates to:
  /// **'السعة الكلية'**
  String get total_capacity;

  /// No description provided for @total_booked.
  ///
  /// In ar, this message translates to:
  /// **'المحجوز'**
  String get total_booked;

  /// No description provided for @available_slots.
  ///
  /// In ar, this message translates to:
  /// **'المتاح'**
  String get available_slots;

  /// No description provided for @technician_details_title.
  ///
  /// In ar, this message translates to:
  /// **'العمليات التفصيلية'**
  String get technician_details_title;

  /// No description provided for @tech_status_idle.
  ///
  /// In ar, this message translates to:
  /// **'متاح تماماً'**
  String get tech_status_idle;

  /// No description provided for @tech_status_healthy.
  ///
  /// In ar, this message translates to:
  /// **'ضغط معتدل'**
  String get tech_status_healthy;

  /// No description provided for @tech_status_full.
  ///
  /// In ar, this message translates to:
  /// **'ممتلئ'**
  String get tech_status_full;

  /// No description provided for @tech_status_blocked.
  ///
  /// In ar, this message translates to:
  /// **'محظور'**
  String get tech_status_blocked;

  /// No description provided for @tech_status_overloaded.
  ///
  /// In ar, this message translates to:
  /// **'مزدحم جداً'**
  String get tech_status_overloaded;

  /// No description provided for @action_reassign.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين فني'**
  String get action_reassign;

  /// No description provided for @action_reschedule.
  ///
  /// In ar, this message translates to:
  /// **'إعادة جدولة الموعد'**
  String get action_reschedule;

  /// No description provided for @action_force_status.
  ///
  /// In ar, this message translates to:
  /// **'فرض حالة الإشغال'**
  String get action_force_status;

  /// No description provided for @tech_action_success_reassigned.
  ///
  /// In ar, this message translates to:
  /// **'تم تحويل الحجز وتعيين فني آخر بنجاح.'**
  String get tech_action_success_reassigned;

  /// No description provided for @tech_action_success_rescheduled.
  ///
  /// In ar, this message translates to:
  /// **'تمت إعادة جدولة الموعد بنجاح.'**
  String get tech_action_success_rescheduled;

  /// No description provided for @tech_action_success_status_updated.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير حالة الفني بنجاح.'**
  String get tech_action_success_status_updated;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
