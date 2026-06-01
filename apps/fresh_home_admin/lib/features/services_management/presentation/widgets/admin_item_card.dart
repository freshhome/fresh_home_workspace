import 'package:flutter/material.dart';
import 'package:shared/shared.dart';



class AdminItemCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? status;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const AdminItemCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.status,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final bool isActive = status == 'active';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          themeColor.cardShadow,
        ],
        border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Image Section
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: themeColor.serviceIconBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.05)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: imageUrl != null && imageUrl!.isNotEmpty
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderIcon(context),
                              )
                            : _buildPlaceholderIcon(context),
                      ),
                    ),
                    if (status != null)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                            shape: BoxShape.circle,
                            border: Border.all(color: themeColor.cardBackground, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: (isActive ? Colors.green : Colors.orange).withValues(alpha: 0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Content Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: themeColor.textPrimary,
                          fontFamily: 'Cairo',
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: themeColor.unselectedItem,
                            fontFamily: 'Cairo',
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Actions Section
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_rounded,
                      color: const Color(0xFF2196F3),
                      onPressed: onEdit,
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                       icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFFF5252),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(BuildContext context) {
    return Center(
      child: Icon(
        Icons.cleaning_services_rounded,
        size: 30,
        color: context.themeColor.primary.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 18),
        onPressed: onPressed,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
