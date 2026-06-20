import 'package:flutter/material.dart';

class StarRatingWidget extends StatelessWidget {
  final double initialRating;
  final int maxRating;
  final double iconSize;
  final bool isReadOnly;
  final ValueChanged<int>? onRatingChanged;
  final Color filledColor;
  final Color emptyColor;

  const StarRatingWidget({
    super.key,
    required this.initialRating,
    this.maxRating = 5,
    this.iconSize = 24.0,
    this.isReadOnly = false,
    this.onRatingChanged,
    this.filledColor = Colors.amber,
    this.emptyColor = const Color(0xFFE2E8F0), // slate-200
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starValue = index + 1;
        Widget starIcon;

        // Determine which icon to display based on the rating value
        if (initialRating >= starValue) {
          starIcon = Icon(
            Icons.star_rounded,
            color: filledColor,
            size: iconSize,
          );
        } else if (initialRating >= starValue - 0.5) {
          starIcon = Icon(
            Icons.star_half_rounded,
            color: filledColor,
            size: iconSize,
          );
        } else {
          starIcon = Icon(
            Icons.star_border_rounded,
            color: emptyColor,
            size: iconSize,
          );
        }

        if (isReadOnly) {
          return starIcon;
        }

        // Interactive mode: tap gestures to update rating value
        return GestureDetector(
          onTap: () {
            if (onRatingChanged != null) {
              onRatingChanged!(starValue);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: starIcon,
          ),
        );
      }),
    );
  }
}
