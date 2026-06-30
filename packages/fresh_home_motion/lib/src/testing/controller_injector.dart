import 'package:flutter/widgets.dart';

/// Testing injector to pass mock animation controllers to components.
class FHControllerInjector {
  final AnimationController? controller;

  const FHControllerInjector({
    this.controller,
  });
}
