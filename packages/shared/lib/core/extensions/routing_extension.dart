import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension RoutingExtension on BuildContext {
  GoRouterState get routerState => GoRouterState.of(this);
}
