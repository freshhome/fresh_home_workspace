import 'package:flutter/material.dart';
import 'package:shared/domain/user/enums/user_status.dart';

class UserStatusBadge extends StatelessWidget {
  final UserStatus status;
  const UserStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final label = status.translatedName(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
