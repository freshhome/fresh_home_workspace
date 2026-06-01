import 'package:flutter/material.dart';
import 'package:shared/domain/user/enums/user_role.dart';

class UserRoleTag extends StatelessWidget {
  final UserRole role;
  const UserRoleTag({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final color = role.color;
    final label = role.translatedName(context);
    final icon = role.icon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
