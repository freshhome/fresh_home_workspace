import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/presentation/theme/components/colors/theme_colors.dart';
import 'package:shared/shared.dart';
import 'package:shared_features/shared_features.dart';
import 'package:shared/presentation/dialogs/dialog_helper.dart';
import 'package:shared/presentation/utils/booking_status_helper.dart';
import 'package:shared/presentation/widgets/order_timeline_widget.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../cubit/my_orders_cubit.dart';
import '../cubit/edit_order_cubit.dart';
import '../widgets/status_badge.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Booking? order;
  final String? orderId;

  const OrderDetailsScreen({super.key, this.order, this.orderId});

  @override
  Widget build(BuildContext context) {
    final bookingRepo = GetIt.instance<BookingRepository>();

    final targetId = order?.id ?? orderId;

    if (targetId == null) {
      return const Scaffold(
        body: Center(child: Text('Error: No order ID provided')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<Either<dynamic, Booking>>(
        stream: bookingRepo.watchBooking(bookingId: targetId),
        builder: (context, snapshot) {
          // Resolve the current order — prefer real-time data
          Booking? mutableOrder = order;
          if (snapshot.hasData) {
            snapshot.data!.fold((_) {}, (liveBooking) {
              mutableOrder = liveBooking;
            });
          }

          final currentOrder = mutableOrder;

          if (currentOrder == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentDateTime = currentOrder.scheduledAt;
          final todayStart = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          );
          final isFutureOrToday = !currentDateTime.isBefore(todayStart);

          // Unified Lifecycle: Can edit/cancel only in early stages (before technician accepts)
          final canCancelOrEdit =
              isFutureOrToday &&
              (currentOrder.status == OrderStatus.created ||
                  currentOrder.status == OrderStatus.pending ||
                  currentOrder.status == OrderStatus.assigned);

          // Show technician details ONLY if they confirmed attendance (ready) or further
          final showTechnicianCard =
              currentOrder.technicianId != null &&
              (currentOrder.status == OrderStatus.ready ||
                  currentOrder.status == OrderStatus.onTheWay ||
                  currentOrder.status == OrderStatus.arrived ||
                  currentOrder.status == OrderStatus.inProgress);

          return BlocListener<EditOrderCubit, EditOrderState>(
            listener: (context, state) {
              if (state is EditOrderSuccess) {
                DialogHelper.showSuccess(
                  context,
                  message: AppLocalizations.of(
                    context,
                  )!.order_reactivate_success,
                  onOkPress: () {
                    context.read<MyOrdersCubit>().loadOrders();
                    Navigator.pop(context);
                  },
                );
              } else if (state is EditOrderFailure) {
                DialogHelper.showError(context, message: state.message);
              }
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  backgroundColor: ThemeColors.primaryLight,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      '#${currentOrder.displayId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ThemeColors.primaryLight,
                            ThemeColors.primaryLight.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Center(
                        child: Hero(
                          tag: 'order_icon_${currentOrder.id}',
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Image.network(
                              currentOrder.service.image,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.cleaning_services_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Summary
                        _buildSummarySection(context, currentOrder),
                        const SizedBox(height: 20),

                        // Interactive Quote Lock Timeline
                        InteractiveQuoteLockTimeline(booking: currentOrder),
                        const SizedBox(height: 20),

                        // Detailed Pricing Breakdown Card
                        PriceBreakdownCard(pricing: currentOrder.price),
                        const SizedBox(height: 20),

                        // Technician Card (real-time visible)
                        if (showTechnicianCard) ...[
                          _buildTechnicianCard(context, currentOrder),
                          const SizedBox(height: 20),
                        ],

                        // Order Timeline
                        OrderTimelineWidget(booking: currentOrder),
                        const SizedBox(height: 20),

                        // Service Details
                        _buildSectionHeader(
                          AppLocalizations.of(
                            context,
                          )!.order_service_details_section,
                          Icons.assignment_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoTile(
                          context,
                          'الخدمة',
                          currentOrder.service.name[Localizations.localeOf(
                                context,
                              ).languageCode] ??
                              '',
                          isTitle: true,
                        ),
                        _buildInfoTile(
                          context,
                          'التاريخ',
                          DateFormat(
                            'EEEE, dd MMM yyyy',
                            'ar',
                          ).format(currentDateTime),
                          onEdit: canCancelOrEdit
                              ? () async {
                                  final result = await context.pushNamed(
                                    AppRoutes.editSchedule,
                                    extra: currentOrder,
                                  );
                                  if (result == true && context.mounted) {
                                    context.read<MyOrdersCubit>().loadOrders();
                                    Navigator.pop(context);
                                  }
                                }
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Address Section
                        _buildSectionHeader(
                          AppLocalizations.of(context)!.order_contact_section,
                          Icons.location_on_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoTile(
                          context,
                          'العميل',
                          currentOrder.contact.name,
                        ),
                        _buildInfoTile(
                          context,
                          'رقم الهاتف',
                          currentOrder.contact.phone.join(' / '),
                        ),
                        _buildInfoTile(
                          context,
                          'العنوان',
                          '${currentOrder.address.governorate}, ${currentOrder.address.city}\n'
                              '${currentOrder.address.street}, مبنى ${currentOrder.address.buildingNumber}, '
                              'دور ${currentOrder.address.floorNumber}, شقة ${currentOrder.address.apartmentNumber}',
                          onEdit: canCancelOrEdit
                              ? () async {
                                  final result = await context.pushNamed(
                                    AppRoutes.editAddress,
                                    extra: currentOrder,
                                  );
                                  if (result == true && context.mounted) {
                                    context.read<MyOrdersCubit>().loadOrders();
                                    Navigator.pop(context);
                                  }
                                }
                              : null,
                        ),
                        const SizedBox(height: 32),

                        // Actions
                        if (canCancelOrEdit) ...[
                          _buildActionButton(
                            text: AppLocalizations.of(
                              context,
                            )!.order_action_cancel,
                            icon: Icons.cancel_outlined,
                            color: Colors.red.shade600,
                            isOutlined: true,
                            onPressed: () =>
                                _showCancelDialog(context, currentOrder),
                          ),
                        ] else if (BookingStatusHelper.isCancelled(
                          currentOrder.status,
                        )) ...[
                          BlocBuilder<EditOrderCubit, EditOrderState>(
                            builder: (context, state) {
                              return _buildActionButton(
                                text: AppLocalizations.of(
                                  context,
                                )!.order_action_rebook,
                                icon: Icons.repeat_rounded,
                                color: ThemeColors.secondaryLight,
                                onPressed: () => _handleRebookOrEdit(
                                  context,
                                  currentOrder,
                                  isEdit: false,
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTechnicianCard(BuildContext context, Booking currentOrder) {
    final themeColor = context.themeColor;
    final statusColor = BookingStatusHelper.getColor(currentOrder.status);
    final statusLabel = BookingStatusHelper.getLabel(currentOrder.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.08),
            statusColor.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.engineering_rounded,
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الفني المعين',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeColor.secondaryText,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'فريش هوم - فني متخصص',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: themeColor.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '4.8',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: themeColor.textPrimary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: Icons.phone_rounded,
                  label: 'اتصال',
                  color: themeColor.primary,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'واتساب',
                  color: const Color(0xFF25D366),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, Booking currentOrder) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.order_total_amount,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${currentOrder.price.total.toStringAsFixed(2)} جم',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: ThemeColors.primaryLight,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          StatusBadge(status: currentOrder.status),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ThemeColors.primaryLight),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String label,
    String value, {
    bool isTitle = false,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onEdit,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isTitle ? 18 : 15,
                      fontWeight: isTitle ? FontWeight.w800 : FontWeight.w600,
                      color: const Color(0xFF1F2937),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeColors.primaryLight.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: ThemeColors.primaryLight,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, size: 20),
              label: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, size: 20),
              label: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
    );
  }

  void _showCancelDialog(BuildContext context, Booking currentOrder) {
    DialogHelper.showConfirmation(
      context,
      title: AppLocalizations.of(context)!.order_cancel_confirm_title,
      desc: AppLocalizations.of(context)!.order_cancel_confirm_message,
      onConfirm: () async {
        await context.read<MyOrdersCubit>().cancelOrder(currentOrder.id);
        if (context.mounted) {
          DialogHelper.showSuccess(
            context,
            message: AppLocalizations.of(context)!.order_cancel_success_message,
            onOkPress: () => Navigator.pop(context),
          );
        }
      },
    );
  }

  void _handleRebookOrEdit(
    BuildContext context,
    Booking currentOrder, {
    required bool isEdit,
  }) {
    final bookedService = BookedService(
      id: currentOrder.service.id,
      subServiceId: currentOrder.service.subServiceId,
      name: currentOrder.service.name,
      image: currentOrder.service.image,
    );
    final userId =
        GetIt.instance<AuthLocalDataSource>().getCachedUser()?.uid ?? '';
    context.pushNamed(
      AppRoutes.bookingFlow,
      extra: {'service': bookedService, 'userId': userId, 'price': null},
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
