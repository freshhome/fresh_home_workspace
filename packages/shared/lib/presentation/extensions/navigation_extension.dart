import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension Navigation on BuildContext {
  /// ✅ تفتح صفحة جديدة باستخدام اسم الـ Route مع دعم الـ query params و extra
  void toNamed(
    String routeName, {
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
  }) {
    GoRouter.of(
      this,
    ).pushNamed(routeName, queryParameters: queryParameters, extra: extra);
  }

  /// ✅ تبدل الصفحة الحالية بصفحة جديدة (Replace)
  void pushReplacementNamed(
    String routeName, {
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
  }) {
    GoRouter.of(this).pushReplacementNamed(
      routeName,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// ✅ تفتح صفحة جديدة وتمسح كل اللي قبلها من الـ Stack (Go)
  void goNamed(
    String routeName, {
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
  }) {
    GoRouter.of(
      this,
    ).goNamed(routeName, queryParameters: queryParameters, extra: extra);
  }

  /// ✅ تنتقل لمسار محدد (Path) وتمسح الـ Stack
  void toPath(String path, {Object? extra}) {
    GoRouter.of(this).go(path, extra: extra);
  }

  /// ✅ (Compatibility) تفتح صفحة جديدة وتمسح الـ Stack
  /// يتم استخدام goNamed لتحقيق نفس النتيجة مع GoRouter
  void pushNamedAndRemoveUntil(
    String routeName, {
    Object? extra,
    Map<String, String> queryParameters = const <String, String>{},
    bool Function(Route<dynamic>)? predicate,
  }) {
    GoRouter.of(
      this,
    ).goNamed(routeName, extra: extra, queryParameters: queryParameters);
  }

  /// ✅ للخروج من الصفحة الحالية
  void pop<T>([T? result]) {
    if (canPop()) {
      GoRouter.of(this).pop(result);
    }
  }

  /// ✅ التحقق من إمكانية الرجوع
  bool canPop() {
    return GoRouter.of(this).canPop();
  }
}
