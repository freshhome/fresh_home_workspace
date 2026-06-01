import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/constants/app_routes.dart';
import '../../domain/entities/notification.dart';

class NotificationRouter {
  static void navigate(BuildContext context, AppNotification notification) {
    final metadata = notification.metadata;
    final String? type = metadata['type'];
    final String? bookingId = metadata['booking_id'];

    if (bookingId != null) {
      // Navigate to booking details
      // Assuming we have a route like /orders/:id
      context.pushNamed(
        AppRoutes.orderDetails,
        pathParameters: {'id': bookingId},
      );
      return;
    }

    // Default handling based on type
    switch (type) {
      case 'offer':
        // context.pushNamed(AppRoutes.offers);
        break;
      case 'system':
        // Stay in notifications or go to a specific system page
        break;
      default:
        // Optional: Default navigation
        break;
    }
  }
}
