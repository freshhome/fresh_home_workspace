import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  BuildContext? get context => navigatorKey.currentContext;

  void pop<T extends Object?>([T? result]) {
    if (context != null) {
      GoRouter.of(context!).pop(result);
    }
  }

  void push(String location, {Object? extra}) {
    if (context != null) {
      GoRouter.of(context!).push(location, extra: extra);
    }
  }

  void go(String location, {Object? extra}) {
    if (context != null) {
      GoRouter.of(context!).go(location, extra: extra);
    }
  }

  void pushReplacement(String location, {Object? extra}) {
    if (context != null) {
      GoRouter.of(context!).pushReplacement(location, extra: extra);
    }
  }
}
