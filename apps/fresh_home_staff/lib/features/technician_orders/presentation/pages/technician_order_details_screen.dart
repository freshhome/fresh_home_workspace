import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:shared_features/shared_features.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/dynamic_field.dart';
import '../cubit/technician_orders_cubit.dart';
import '../cubit/technician_orders_state.dart';
import '../widgets/status_timeline.dart';
import '../widgets/status_badge.dart';

class TechnicianOrderDetailsScreen extends StatefulWidget {
  final Booking? order;
  final String? bookingId;
  final bool showSensitiveDetails;

  const TechnicianOrderDetailsScreen({
    super.key,
    this.order,
    this.bookingId,
    this.showSensitiveDetails = false,
  });

  @override
  State<TechnicianOrderDetailsScreen> createState() => _TechnicianOrderDetailsScreenState();
}

class _TechnicianOrderDetailsScreenState extends State<TechnicianOrderDetailsScreen> {
  SubServiceEntity? _subService;
  bool _loadingService = false;
  final Map<String, dynamic> _dynamicInputs = {};
  final List<String> _selectedOptions = [];
  final Map<String, dynamic> _originalInputs = {};
  final List<String> _originalSelectedOptions = [];
  BookingPricing? _calculatedPricing;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TechnicianOrdersCubit>().loadOrders();
        _loadServiceDetails();
      }
    });
  }

  Future<void> _loadServiceDetails() async {
    final booking = widget.order;
    if (booking == null || booking.service.subServiceId.isEmpty) return;
    setState(() => _loadingService = true);
    final useCase = GetIt.instance<GetServiceByIdUseCase>();
    final result = await useCase(booking.service.subServiceId);
    result.fold(
      (failure) {
        debugPrint('❌ [TechnicianOrderDetails] Error loading service: ${failure.message}');
        if (mounted) setState(() => _loadingService = false);
      },
      (service) {
        if (mounted) {
          setState(() {
            _subService = ServiceMapper.serviceToSubServiceEntity(service);
            _loadingService = false;
            // Pre-fill measurements if booking has pricing inputs
            if (booking.pricingInputs != null) {
              _dynamicInputs.addAll(booking.pricingInputs!);
              if (_originalInputs.isEmpty) {
                _originalInputs.addAll(booking.pricingInputs!);
              }
              if (booking.pricingInputs!['selected_options'] != null) {
                final list = List<String>.from(booking.pricingInputs!['selected_options'] as List);
                _selectedOptions.addAll(list);
                if (_originalSelectedOptions.isEmpty) {
                  _originalSelectedOptions.addAll(list);
                }
              }
            }
            _calculatedPricing = booking.price;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return BlocListener<TechnicianOrdersCubit, TechnicianOrdersState>(
      listener: (context, state) {
        if (state is TechnicianOrdersLoaded && state.transitionError != null) {
          debugPrint('❌ [TechnicianOrderDetails] Action Failed: ${state.transitionError}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.transitionError!, style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: themeColor.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<TechnicianOrdersCubit, TechnicianOrdersState>(
        builder: (context, state) {
          final isLoaded = state is TechnicianOrdersLoaded;
          final isTransitioning = isLoaded && state.isTransitioning;

          if (widget.order == null && !isLoaded) {
            return Scaffold(
              appBar: AppBar(title: const Text('جاري التحميل...')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          Booking? currentOrder = widget.order;
          if (isLoaded) {
            final allOrders = [
              ...state.todayOrders,
              ...state.upcomingGroups.expand((g) => g.orders),
              ...state.historyGroups.expand((g) => g.orders),
            ];
            currentOrder = allOrders.firstWhere(
              (o) => o.id == (widget.order?.id ?? widget.bookingId),
              orElse: () => widget.order!,
            );
          }

          if (currentOrder == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('الطلب غير موجود')),
            );
          }

          // Reveal sensitive data ONLY if 'ready' or further in the lifecycle
          final bool canShowSensitive = currentOrder.status == OrderStatus.ready || 
                                       currentOrder.status == OrderStatus.onTheWay || 
                                       currentOrder.status == OrderStatus.arrived || 
                                       currentOrder.status == OrderStatus.inProgress ||
                                       currentOrder.status == OrderStatus.pendingInspection;

          return Stack(
            children: [
              Scaffold(
                backgroundColor: themeColor.background,
                appBar: AppBar(
                  title: const Text(
                    "تفاصيل الأوردر",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: themeColor.primary,
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                body: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Order Header Card (ID & Status Badge)
                          _buildOrderHeaderCard(context, currentOrder),
                          const SizedBox(height: 16),
                          
                          // 2. Request Details Card
                          _buildRequestDetailsCard(context, currentOrder),
                          const SizedBox(height: 16),
                          
                          _buildInspectionCard(context, currentOrder),
                          
                          // Financial Details & Transparency for Technician
                          // _buildFinancialSection(context, currentOrder),
                          // const SizedBox(height: 16),
                          
                          // 3. Customer Details Card
                          _buildCustomerInfoCard(context, currentOrder, canShowSensitive),
                          const SizedBox(height: 16),

                          // 4. Status Timeline (Vertical at bottom)
                          StatusTimeline(currentStatus: currentOrder.status, isVertical: true),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildActionSection(
                          context, currentOrder, isTransitioning),
                    ),
                  ],
                ),
              ),
              if (isTransitioning)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── ORDER HEADER CARD ──────────────────────────────────────────────────
  Widget _buildOrderHeaderCard(BuildContext context, Booking order) {
    final themeColor = context.themeColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [themeColor.cardShadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "رقم الأوردر",
                style: TextStyle(
                  fontSize: 12,
                  color: themeColor.secondaryText,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "#${order.displayId}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: themeColor.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          StatusBadge(status: order.status),
        ],
      ),
    );
  }

  // ── REQUEST DETAILS CARD ────────────────────────────────────────────────
  Widget _buildRequestDetailsCard(BuildContext context, Booking order) {
    final themeColor = context.themeColor;
    final locale = Localizations.localeOf(context).languageCode;
    final timeStr = DateFormat('hh:mm a', locale).format(order.scheduledAt);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [themeColor.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "تفاصيل الطلب",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: themeColor.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            context, 
            Icons.cleaning_services_rounded, 
            "نوع الخدمة", 
            order.service.name[locale] ?? ''
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),
          _buildDetailRow(
            context, 
            Icons.access_time_rounded, 
            "موعد الوصول المتوقع", 
            timeStr
          ),
          
          if (_subService != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 0.5),
            ),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                iconColor: themeColor.primary,
                collapsedIconColor: themeColor.secondaryText,
                title: Text(
                  "تفاصيل الخدمة المضافة",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: themeColor.primary,
                    fontFamily: 'Cairo',
                  ),
                ),
                leading: Icon(Icons.info_outline_rounded, color: themeColor.primary, size: 20),
                childrenPadding: const EdgeInsets.only(top: 8, bottom: 12),
                children: _buildServiceComponentsList(context, order),
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),
          _buildDetailRow(
            context, 
            Icons.payment_rounded, 
            "طريقة التحصيل المطلوبة", 
            order.paymentMethod?.toLowerCase() == 'instapay'
                ? 'تحويل إنستا باي (InstaPay)'
                : order.paymentMethod?.toLowerCase() == 'vodafone_cash'
                    ? 'تحويل فودافون كاش (Vodafone Cash)'
                    : 'نقداً (كاش)',
            isHighlighted: false,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),
          _buildDetailRow(
            context, 
            Icons.payments_rounded, 
            "إجمالي السعر التقديري", 
            "${order.price.total.toStringAsFixed(0)} ج.م",
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildServiceComponentsList(BuildContext context, Booking order) {
    final themeColor = context.themeColor;
    final locale = Localizations.localeOf(context).languageCode;
    final List<Widget> items = [];

    if (_subService == null) return items;

    // 1. Dynamic fields
    for (final field in _subService!.price.fields) {
      final val = _dynamicInputs[field.id];
      if (val != null) {
        String displayVal = '';
        if (field.type == DynamicFieldType.toggle) {
          if (val == true) {
            displayVal = field.label[locale] ?? field.label['ar'] ?? field.id;
          } else {
            continue;
          }
        } else if (field.type == DynamicFieldType.number) {
          final num numVal = val as num;
          if (numVal > 0) {
            displayVal = "${field.label[locale] ?? field.label['ar'] ?? field.id}: ${numVal.toStringAsFixed(0)} ${field.unit ?? ''}";
          } else {
            continue;
          }
        } else {
          displayVal = "${field.label[locale] ?? field.label['ar'] ?? field.id}: $val";
        }

        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 16, color: themeColor.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayVal,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: themeColor.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // 2. Extra options
    for (final option in _subService!.price.options) {
      final key = option.key ?? '';
      if (_selectedOptions.contains(key)) {
        final label = option.label?[locale] ?? option.label?['ar'] ?? key;
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 16, color: themeColor.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: themeColor.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (items.isEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "لا توجد إضافات أو خيارات محددة",
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: themeColor.secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return items;
  }

  // ── CUSTOMER INFO CARD ──────────────────────────────────────────────────
  Widget _buildCustomerInfoCard(BuildContext context, Booking order, bool canShowSensitive) {
    final themeColor = context.themeColor;
    final phone = order.contact.phone.isNotEmpty ? order.contact.phone.first : '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [themeColor.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "تفاصيل العميل",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: themeColor.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 20),
          
          if (canShowSensitive) ...[
            // Name
            _buildDetailRow(context, Icons.person_rounded, "اسم العميل", order.contact.name),
            const SizedBox(height: 16),
            
            // Address
            _buildDetailRow(
              context, 
              Icons.location_on_rounded, 
              "عنوان العميل", 
              "${order.address.city}, ${order.address.street}, مبنى ${order.address.buildingNumber}, دور ${order.address.floorNumber}, شقة ${order.address.apartmentNumber}",
            ),
            const SizedBox(height: 16),
            
            // Phone with Copy
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(context, Icons.phone_iphone_rounded, "رقم الهاتف", phone),
                ),
                Material(
                  color: themeColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () {
                       Clipboard.setData(ClipboardData(text: phone));
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(
                           content: Text("تم نسخ رقم الهاتف بنجاح", style: TextStyle(fontFamily: 'Cairo')),
                           behavior: SnackBarBehavior.floating,
                         ),
                       );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.copy_rounded, size: 18, color: themeColor.primary),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Call & WhatsApp Buttons
            Row(
              children: [
                Expanded(
                  child: _buildContactButton(
                    context,
                    "اتصال هاتفي",
                    Icons.phone_enabled_rounded,
                    themeColor.primary,
                    () => _launchPhone(phone),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactButton(
                    context,
                    "واتساب",
                    Icons.chat_rounded,
                    const Color(0xFF25D366),
                    () => _launchWhatsApp(phone),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Privacy Placeholder
            _buildPrivacyPlaceholder(context),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {bool isHighlighted = false}) {
    final themeColor = context.themeColor;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHighlighted ? themeColor.primary.withValues(alpha: 0.1) : themeColor.unselectedItem.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: isHighlighted ? themeColor.primary : themeColor.secondaryText),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, 
                style: TextStyle(
                  fontSize: 11, 
                  color: themeColor.secondaryText, 
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                )
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.bold,
                  color: isHighlighted ? themeColor.primary : themeColor.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label, 
            style: const TextStyle(
              fontFamily: 'Cairo', 
              fontWeight: FontWeight.w900,
              fontSize: 14,
            )
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPlaceholder(BuildContext context) {
    final themeColor = context.themeColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: themeColor.warning.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_rounded, color: themeColor.warning, size: 32),
          const SizedBox(height: 12),
          Text(
            "بيانات العميل مخفية",
            style: TextStyle(
              fontSize: 16, 
              color: themeColor.warning, 
              fontWeight: FontWeight.w900, 
              fontFamily: 'Cairo'
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "سيتم فتح بيانات التواصل والعنوان الكامل بمجرد تأكيد موعد الطلب لليوم.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12, 
              color: themeColor.warning.withValues(alpha: 0.8), 
              fontWeight: FontWeight.bold, 
              fontFamily: 'Cairo'
            ),
          ),
        ],
      ),
    );
  }

  // ── ACTION SECTION ─────────────────────────────────────────────────────
  Widget _buildActionSection(BuildContext context, Booking currentOrder, bool isLoading) {
    final themeColor = context.themeColor;
    final l10n = AppLocalizations.of(context)!;

    String actionLabel = '';
    OrderStatus? nextStatus;
    IconData actionIcon = Icons.help_outline;
    Color actionColor = themeColor.primary;


    switch (currentOrder.status) {
      case OrderStatus.assigned:
        actionLabel = l10n.tech_action_accept;
        nextStatus = OrderStatus.accepted;
        actionIcon = Icons.check_circle_outline_rounded;
        actionColor = const Color(0xFF10B981);
        break;
      case OrderStatus.accepted:
        final bool isToday = DateUtils.isSameDay(currentOrder.scheduledAt, DateTime.now());
        if (isToday) {
          actionLabel = "تأكيد حضور اليوم ✅";
          nextStatus = OrderStatus.ready;
          actionIcon = Icons.how_to_reg_rounded;
          actionColor = const Color(0xFF10B981);
        } else {
          nextStatus = null;
        }
        break;
      case OrderStatus.ready:
        actionLabel = l10n.tech_action_on_the_way;
        nextStatus = OrderStatus.onTheWay;
        actionIcon = Icons.directions_car_rounded;
        actionColor = const Color(0xFFF59E0B);
        break;
      case OrderStatus.onTheWay:
        actionLabel = "لقد وصلت للموقع";
        nextStatus = OrderStatus.arrived;
        actionIcon = Icons.location_on_rounded;
        actionColor = const Color(0xFF06B6D4);
        break;
      case OrderStatus.arrived:
        final isInspection = _subService != null &&
            (_subService!.price.type == PricingMethod.inspection ||
                _subService!.price.fields.isNotEmpty);
        if (isInspection) {
          nextStatus = null;
        } else {
          actionLabel = l10n.tech_action_start_job;
          nextStatus = OrderStatus.inProgress;
          actionIcon = Icons.play_circle_outline_rounded;
          actionColor = const Color(0xFF3B82F6);
        }
        break;
      case OrderStatus.inProgress:
        actionLabel = l10n.tech_action_complete;
        nextStatus = OrderStatus.completed;
        actionIcon = Icons.task_alt_rounded;
        actionColor = const Color(0xFF8B5CF6);
        break;
      default:
        return const SizedBox.shrink();
    }

    final targetStatus = nextStatus;

    if (targetStatus == null && !currentStatusCanDecline(currentOrder)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: themeColor.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (currentStatusCanDecline(currentOrder))
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => _showCancelDialog(context, currentOrder),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: themeColor.error,
                      side: BorderSide(color: themeColor.error.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(l10n.tech_action_decline, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            if (targetStatus != null)
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _handleAction(context, currentOrder, targetStatus),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shadowColor: actionColor.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ).copyWith(elevation: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.pressed) ? 2 : 6)),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(actionIcon, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              actionLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Cairo',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool currentStatusCanDecline(Booking order) {
    final bool isToday = DateUtils.isSameDay(order.scheduledAt, DateTime.now());
    if (isToday) {
      return order.status == OrderStatus.assigned || order.status == OrderStatus.accepted;
    } else {
      return order.status == OrderStatus.accepted;
    }
  }

  void _handleAction(BuildContext context, Booking currentOrder, OrderStatus nextStatus) {
    if (nextStatus == OrderStatus.completed) {
      _showCompleteOrderCashDialog(context, currentOrder);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    String title = l10n.tech_details_confirm_action;
    String desc = "";

    switch (nextStatus) {
      case OrderStatus.accepted:
        desc = "هل أنت متأكد من رغبتك في قبول هذا الطلب؟ سيتم إخطار العميل ببدء التجهيز.";
        break;
      case OrderStatus.ready:
        desc = "هل تؤكد حضورك لتنفيذ هذا الطلب اليوم؟ سيتم الآن فتح بيانات العميل والعنوان الكامل لك.";
        break;
      case OrderStatus.onTheWay:
        desc = "هل أنت متوجه إلى موقع العميل الآن؟ سيصل إشعار للعميل بذلك.";
        break;
      case OrderStatus.arrived:
        desc = "هل وصلت بالفعل لموقع العميل؟";
        break;
      case OrderStatus.inProgress:
        desc = "هل تود بدء العمل الفعلي على هذا الطلب الآن؟";
        break;
      case OrderStatus.completed:
        desc = "هل تم إنهاء كافة المهام المطلوبة بنجاح؟";
        break;
      default:
        break;
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.bottomSlide,
      title: title,
      desc: desc,
      titleTextStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18),
      descTextStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
      btnOkText: "تأكيد",
      btnCancelText: "تراجع",
      btnOkColor: context.themeColor.primary,
      btnOkOnPress: () {
        final authCubit = context.read<AuthCubit>();
        context.read<TechnicianOrdersCubit>().transitionOrder(
          booking: currentOrder,
          newStatus: nextStatus,
          technicianId: authCubit.userId ?? currentOrder.technicianId ?? '',
        );
      },
      btnCancelOnPress: () {},
    ).show();
  }

  void _showCancelDialog(BuildContext context, Booking currentOrder) {
    final l10n = AppLocalizations.of(context)!;
    
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: l10n.tech_details_decline_order,
      desc: "يرجى العلم أن هذا الإجراء سيقوم بإلغاء التكليف الخاص بك لهذا الطلب.",
      titleTextStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18),
      descTextStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
      btnOkText: "تأكيد الاعتذار",
      btnCancelText: "تراجع",
      btnOkColor: context.themeColor.error,
      btnOkOnPress: () {
        final authCubit = context.read<AuthCubit>();
        context.read<TechnicianOrdersCubit>().transitionOrder(
          booking: currentOrder,
          newStatus: OrderStatus.pending, // Transition back to pending (Rejection)
          technicianId: authCubit.userId ?? currentOrder.technicianId ?? '',
          reason: "TECH_REJECTED",
          actorRole: "technician",
          notes: "Technician declined assignment through the app",
        );
      },
      btnCancelOnPress: () {},
    ).show();
  }

  Future<void> _launchPhone(String phone) async {
    if (phone.isEmpty) return;
    final Uri url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // Try direct launch if canLaunchUrl fails (common on Android 11+)
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching phone: $e');
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    
    // Clean phone number (keep only digits)
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Ensure it starts with country code (e.g., 20 for Egypt)
    if (!cleanPhone.startsWith('2') && cleanPhone.length == 11 && cleanPhone.startsWith('01')) {
       cleanPhone = '2$cleanPhone';
    }

    final Uri url = Uri.parse('https://wa.me/$cleanPhone');
    
    try {
      // On some Android devices, canLaunchUrl returns false even if WhatsApp is installed
      // if the manifest queries are not perfect. Using externalApplication mode is safer.
      final bool launched = await launchUrl(
        url, 
        mode: LaunchMode.externalApplication
      );
      
      if (!launched) {
        debugPrint('Could not launch WhatsApp URL');
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  // Widget _buildFinancialSection(BuildContext context, Booking order) {
  //   final themeColor = context.themeColor;
  //   final locale = Localizations.localeOf(context).languageCode;
  // 
  //   final basePriceVal = order.price.basePrice;
  //   final extraFeesVal = order.price.extraFees;
  //   final discountVal = order.price.discount;
  //   final totalVal = order.price.total;
  //   final metadata = order.price.metadata ?? {};
  //   final subtotalVal = (metadata['subtotal'] ?? basePriceVal).toDouble();
  // 
  //   // Commissionable amount based on pre-discount subtotal + extra fees
  //   final baseCommissionableAmount = subtotalVal + extraFeesVal;
  // 
  //   // Retrieve platform commission and technician payout directly from metadata, fallback to standard 80/20 split
  //   final commissionRateVal = (metadata['commission_rate'] ?? 0.20).toDouble();
  //   final platformCommissionVal = (metadata['platform_commission'] ?? (baseCommissionableAmount * commissionRateVal)).toDouble();
  //   final bonusesVal = 0.0; // default 0
  //   final technicianPayoutVal = (metadata['technician_payout'] ?? (baseCommissionableAmount * (1.0 - commissionRateVal))).toDouble() + bonusesVal;
  // 
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.stretch,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
  //         child: Text(
  //           "البيانات المالية والأرباح",
  //           style: TextStyle(
  //             fontSize: 16,
  //             fontWeight: FontWeight.w900,
  //             color: themeColor.textPrimary,
  //             fontFamily: 'Cairo',
  //           ),
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       EarningsLedgerCard(
  //         orderId: order.displayId,
  //         serviceName: order.service.name[locale] ?? '',
  //         date: order.scheduledAt,
  //         earnings: technicianPayoutVal,
  //         status: order.status.name,
  //       ),
  //       const SizedBox(height: 16),
  //       CommissionBreakdownCard(
  //         customerPaid: totalVal,
  //         technicianEarnings: technicianPayoutVal,
  //         platformCommission: platformCommissionVal,
  //       ),
  //       if (bonusesVal > 0) ...[
  //         const SizedBox(height: 16),
  //         BonusHighlightCard(
  //           bonusAmount: bonusesVal,
  //           title: "حافز الأداء المتميز",
  //           description: "حافز الأداء المتميز للطلب",
  //         ),
  //       ],
  //       const SizedBox(height: 16),
  //       CustomerPaidSummary(
  //         basePrice: basePriceVal,
  //         extraFees: extraFeesVal,
  //         customerDiscount: discountVal,
  //         customerPaid: totalVal,
  //       ),
  //     ],
  //   );
  // }

  // ── 5. POST-INSPECTION CARD & HELPERS ───────────────────────────────────

  Widget _buildInspectionCard(BuildContext context, Booking order) {
    final themeColor = context.themeColor;
    if (_subService == null) {
      if (_loadingService) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [themeColor.cardShadow],
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // Check if this service is inspection-based or has dynamic inputs
    final isInspection = _subService!.price.type == PricingMethod.inspection || 
                         _subService!.price.fields.isNotEmpty;
    if (!isInspection) return const SizedBox.shrink();

    // Show only in arrived or pendingInspection status
    final showCard = order.status == OrderStatus.arrived || 
                     order.status == OrderStatus.pendingInspection;
    if (!showCard) return const SizedBox.shrink();

    final computedFieldIds = _subService!.computedFields?.map((cf) => cf.id).toSet() ?? {};
    final filteredFields = _subService!.price.fields
        .where((f) => !computedFieldIds.contains(f.id))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [themeColor.cardShadow],
        border: Border.all(
          color: themeColor.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.assignment_turned_in_rounded, color: themeColor.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                "المعاينة وتأكيد التسعير",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: themeColor.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "يرجى إدخال القياسات والخيارات الفعلية لمعاينة الموقع لحساب السعر النهائي للعميل والمستحقات الخاصة بك.",
            style: TextStyle(
              fontSize: 13,
              color: themeColor.secondaryText,
              height: 1.5,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: themeColor.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "التعديل متاح للإضافة فقط. لتعديل أو إلغاء أي خدمة سابقة، يرجى التواصل مع الإدارة.",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: themeColor.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          DynamicFormRenderer(
            fields: filteredFields,
            values: _dynamicInputs,
            options: _subService!.price.options,
            selectedOptions: _selectedOptions,
            onFieldChanged: (key, value) {
              final originalVal = _originalInputs[key];
              if (originalVal != null) {
                final double origNum = (originalVal is num) ? originalVal.toDouble() : 0.0;
                final double newNum = (value is num) ? value.toDouble() : 0.0;
                if (newNum < origNum) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "حظر الإجراء: التعديل متاح للإضافة فقط. لتعديل أو إلغاء الخدمات السابقة، اتصل بالإدارة.",
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
              }
              setState(() {
                if (value == null) {
                  _dynamicInputs.remove(key);
                } else {
                  _dynamicInputs[key] = value;
                }
                _calculatedPricing = null;
              });
            },
            onOptionToggled: (optionKey) {
              if (_originalSelectedOptions.contains(optionKey) && _selectedOptions.contains(optionKey)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "حظر الإجراء: التعديل متاح للإضافة فقط. لتعديل أو إلغاء الخدمات السابقة، اتصل بالإدارة.",
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              setState(() {
                if (_selectedOptions.contains(optionKey)) {
                  _selectedOptions.remove(optionKey);
                } else {
                  _selectedOptions.add(optionKey);
                }
                _dynamicInputs['selected_options'] = _selectedOptions;
                _calculatedPricing = null;
              });
            },
          ),

          const SizedBox(height: 24),

          if (_calculatedPricing == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCalculating ? null : () => _calculatePrice(context),
                icon: _isCalculating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.calculate_rounded),
                label: Text(
                  _isCalculating ? "جاري الحساب..." : "حساب السعر النهائي",
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            )
          else ...[
            _buildPayoutBreakdownCard(context),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _submitInspectionQuote(context, order),
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text(
                  "حفظ السعر وبدء الخدمة",
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPayoutBreakdownCard(BuildContext context) {
    final themeColor = context.themeColor;
    if (_calculatedPricing == null) return const SizedBox.shrink();

    final subtotal = (_calculatedPricing!.metadata?['subtotal'] ?? _calculatedPricing!.basePrice).toDouble();
    final extraFees = _calculatedPricing!.extraFees;
    final discount = _calculatedPricing!.discount;
    final total = _calculatedPricing!.total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: themeColor.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "تفاصيل الحساب المتوقعة",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: themeColor.primary,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow("سعر الخدمة الأساسي", "${subtotal.toStringAsFixed(2)} ج.م", themeColor),
          if (extraFees > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow("رسوم إضافية", "${extraFees.toStringAsFixed(2)} ج.م", themeColor),
          ],
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow("الخصم المطبق", "- ${discount.toStringAsFixed(2)} ج.م", themeColor, isDiscount: true),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 0.5),
          ),
          _buildPriceRow(
            "إجمالي السعر المتوقع للعميل",
            "${total.toStringAsFixed(2)} ج.م",
            themeColor,
            isBold: true,
            textColor: themeColor.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value,
    ThemeColorExtension themeColor, {
    bool isBold = false,
    bool isDiscount = false,
    Color? textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? themeColor.textPrimary : themeColor.secondaryText,
              fontFamily: 'Cairo',
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: textColor ?? (isDiscount ? Colors.redAccent : themeColor.textPrimary),
            fontFamily: 'Cairo',
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _calculatePrice(BuildContext context) async {
    if (_subService == null) return;

    setState(() {
      _isCalculating = true;
    });

    final calculatePriceUseCase = GetIt.instance<CalculatePriceUseCase>();
    final result = await calculatePriceUseCase(
      CalculatePriceParams(
        priceEntity: _subService!.price,
        subServiceId: _subService!.id,
        pricingInputs: _dynamicInputs,
        selectedOptions: _selectedOptions,
      ),
    );

    if (mounted) {
      setState(() {
        _isCalculating = false;
      });

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "فشل حساب السعر: ${failure.message}",
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        },
        (pricing) {
          setState(() {
            _calculatedPricing = pricing;
          });
        },
      );
    }
  }

  void _submitInspectionQuote(BuildContext context, Booking order) {
    if (_calculatedPricing == null) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.bottomSlide,
      title: "تأكيد التسعير وبدء الخدمة",
      desc: "هل أنت متأكد من حفظ هذا التسعير والبدء في تنفيذ الخدمة الآن؟ سيتم إرسال إشعار للعميل بالفاتورة النهائية.",
      titleTextStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18),
      descTextStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
      btnOkText: "حفظ وبدء",
      btnCancelText: "تراجع",
      btnOkColor: const Color(0xFF10B981),
      btnOkOnPress: () {
        final authCubit = context.read<AuthCubit>();
        final technicianId = authCubit.userId ?? order.technicianId ?? '';
        
        context.read<TechnicianOrdersCubit>().submitPostInspectionQuote(
              booking: order,
              dynamicInputs: _dynamicInputs,
              pricing: _calculatedPricing!,
              technicianId: technicianId,
            );
      },
      btnCancelOnPress: () {},
    ).show();
  }

  void _showCompleteOrderCashDialog(BuildContext context, Booking currentOrder) {
    final themeColor = context.themeColor;
    final totalAmount = currentOrder.price.total;
    final requiredAmount = totalAmount.toInt();

    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isConfirmed = false;
    bool isValidInput = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: themeColor.cardBackground,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    )
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Icon and Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Color(0xFF10B981),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "تأكيد التحصيل وإتمام الطلب",
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Subtitle
                        Text(
                          "يرجى التأكد من استلام المبلغ المطلوب نقداً من العميل قبل تأكيد إتمام المهمة.",
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: themeColor.secondaryText,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Required Amount Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "المبلغ المطلوب تحصيله كاش",
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "$requiredAmount ج.م",
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF10B981),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (totalAmount != requiredAmount) ...[
                                const SizedBox(height: 6),
                                Text(
                                  "المبلغ الإجمالي مع الكسور: ${totalAmount.toStringAsFixed(2)} ج.م",
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Input label
                        const Text(
                          "أدخل القيمة المستلمة للمطابقة:",
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Custom Styled TextFormField
                        TextFormField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: themeColor.primary,
                          ),
                          decoration: InputDecoration(
                            hintText: "أدخل القيمة هنا",
                            hintStyle: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[400],
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: themeColor.primary,
                                width: 2.0,
                              ),
                            ),
                            errorStyle: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onChanged: (val) {
                            final entered = int.tryParse(val);
                            setModalState(() {
                              isValidInput = entered == requiredAmount;
                            });
                          },
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "يرجى إدخال المبلغ للمطابقة";
                            }
                            final entered = int.tryParse(val);
                            if (entered == null) {
                              return "يرجى إدخال رقم صحيح";
                            }
                            if (entered != requiredAmount) {
                              return "المبلغ غير مطابق لقيمة الطلب ($requiredAmount ج.م)";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Confirmation Switch Card (Interactive & Premium)
                        InkWell(
                          onTap: () {
                            setModalState(() {
                              isConfirmed = !isConfirmed;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isConfirmed
                                  ? const Color(0xFF10B981).withValues(alpha: 0.05)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isConfirmed ? const Color(0xFF10B981) : Colors.grey[200]!,
                                width: isConfirmed ? 2.0 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isConfirmed ? const Color(0xFF10B981) : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isConfirmed ? const Color(0xFF10B981) : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 14,
                                    color: isConfirmed ? Colors.white : Colors.transparent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    "أؤكد استلام كامل المبلغ نقداً من العميل",
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  "تراجع",
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (isValidInput && isConfirmed)
                                    ? () {
                                        if (formKey.currentState!.validate()) {
                                          Navigator.pop(dialogContext);
                                          final authCubit = context.read<AuthCubit>();
                                          context.read<TechnicianOrdersCubit>().completeOrderWithCash(
                                                booking: currentOrder,
                                                technicianId: authCubit.userId ?? currentOrder.technicianId ?? '',
                                                collectedAmount: requiredAmount.toDouble(),
                                              );
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  disabledBackgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: Colors.grey[400],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "تأكيد وإتمام الطلب",
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
