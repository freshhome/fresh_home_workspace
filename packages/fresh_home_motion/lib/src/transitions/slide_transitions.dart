import 'package:flutter/widgets.dart';

/// Screen slide-in animation transitions for sheets and drawers.
class FHSlideSheetRouteBuilder<T> extends PageRouteBuilder<T> {
  /// The overlay page element.
  final WidgetBuilder sheetBuilder;

  FHSlideSheetRouteBuilder({
    required this.sheetBuilder,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => sheetBuilder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // SKELETON: Returns basic slide-in mock wrapper
            return child;
          },
        );
}
