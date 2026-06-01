import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/domain/user/enums/user_status.dart';

class User {
  // id خاص ب قاعدة البيانات الخاصة بنا
  final int customId;
  // uid خاص ب Firebase (SupaBase)
  final String uid;
  // الاسم الأول
  final String firstName;
  // الاسم الأخير
  final String lastName;
  // البريد الالكتروني
  final String email;
  // حالة الحساب
  final UserStatus accountStatus;
  // الجنس
  final String gender;
  // مسار الصورة الشخصية
  final String? avatarUrl;
  // الصلاحيات
  final List<UserRole> roles;
  // أرقام الهواتف
  final List<String> phones;
  // تاريخ الاضافة
  final DateTime createdAt;
  // تاريخ التحديث
  final DateTime updatedAt;

  const User({
    required this.customId,
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.accountStatus,
    required this.gender,
    this.avatarUrl,
    required this.roles,
    this.phones = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // 🔹 Getters
  // 🔹 ارجاع الاسم الكامل
  String get fullName => '$firstName $lastName';
  // ارجاع الصلاحيات لو المستخدم عميل
  bool get isClient => roles.contains(UserRole.client);
  // ارجاع الصلاحيات لو المستخدم مهندس
  bool get isTechnician => roles.contains(UserRole.technician);
  // ارجاع الصلاحيات لو المستخدم ادمن
  bool get isAdmin => roles.contains(UserRole.admin);
}

