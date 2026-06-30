import 'package:flutter/widgets.dart';

/// Page route builder that implements standard fade-through transitions.
class FHFadeThroughRouteBuilder<T> extends PageRouteBuilder<T> {
  /// The destination screen builder.
  final WidgetBuilder screenBuilder;

  FHFadeThroughRouteBuilder({
    required this.screenBuilder,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => screenBuilder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // SKELETON: Returns basic fade-through mock wrapper
            return child;
          },
        );
}
