import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

/// Standardized Profile Header Avatar & Info Component.
class ProfileHeaderWidget extends StatelessWidget {
  final String fullName;
  final String email;
  final String? avatarUrl;
  final VoidCallback? onEditAvatar;

  const ProfileHeaderWidget({
    super.key,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.onEditAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>();
    final primaryColor = themeColor?.primary ?? const Color(0xFF1E3A8A);

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.1),
                border: Border.all(color: primaryColor, width: 2),
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? Image.network(avatarUrl!, fit: BoxFit.cover)
                    : Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: primaryColor,
                      ),
              ),
            ),
            if (onEditAvatar != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Semantics(
                  button: true,
                  label: 'تغيير الصورة الشخصية',
                  child: InkWell(
                    onTap: onEditAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          fullName.isNotEmpty ? fullName : 'مستخدم فريش هوم',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            email,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }
}
