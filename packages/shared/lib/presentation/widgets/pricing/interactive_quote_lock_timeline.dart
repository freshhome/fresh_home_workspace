import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class InteractiveQuoteLockTimeline extends StatefulWidget {
  final Booking booking;
  final Duration lockDuration;

  const InteractiveQuoteLockTimeline({
    super.key,
    required this.booking,
    this.lockDuration = const Duration(minutes: 30),
  });

  @override
  State<InteractiveQuoteLockTimeline> createState() => _InteractiveQuoteLockTimelineState();
}

class _InteractiveQuoteLockTimelineState extends State<InteractiveQuoteLockTimeline> {
  Timer? _timer;
  late Duration _remaining;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    if (!_isExpired && _shouldRunTimer()) {
      _startTimer();
    }
  }

  bool _shouldRunTimer() {
    return widget.booking.status == OrderStatus.created ||
        widget.booking.status == OrderStatus.pending;
  }

  void _calculateRemaining() {
    if (!_shouldRunTimer()) {
      _remaining = Duration.zero;
      _isExpired = false;
      return;
    }
    final expiryTime = widget.booking.createdAt.add(widget.lockDuration);
    final difference = expiryTime.difference(DateTime.now());
    if (difference.isNegative) {
      _remaining = Duration.zero;
      _isExpired = true;
    } else {
      _remaining = difference;
      _isExpired = false;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _calculateRemaining();
        if (_isExpired) {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final isPermanentLock = widget.booking.status != OrderStatus.created &&
        widget.booking.status != OrderStatus.pending &&
        widget.booking.status != OrderStatus.cancelled &&
        widget.booking.status != OrderStatus.expired;

    Color stateColor;
    IconData stateIcon;
    String statusTitle;
    String statusDesc;

    if (isPermanentLock) {
      stateColor = Colors.green;
      stateIcon = Icons.verified_user_rounded;
      statusTitle = 'سعر مؤكد ونهائي (Price Locked)';
      statusDesc = 'تم تأكيد حجزك وتثبيت السعر نهائياً. لن يتأثر بأي تقلبات أو تحديثات.';
    } else if (widget.booking.status == OrderStatus.cancelled) {
      stateColor = Colors.grey;
      stateIcon = Icons.cancel_outlined;
      statusTitle = 'الحجز ملغى (Cancelled)';
      statusDesc = 'تم إلغاء هذا الطلب وبالتالي تم إبطال قفل السعر الخاص به.';
    } else if (_isExpired || widget.booking.status == OrderStatus.expired) {
      stateColor = themeColor.error;
      stateIcon = Icons.history_toggle_off_rounded;
      statusTitle = 'انتهت صلاحية قفل السعر (Quote Expired)';
      statusDesc = 'انتهت فترة الـ 30 دقيقة المخصصة لضمان هذا السعر. قد يختلف السعر عند التحديث.';
    } else {
      stateColor = themeColor.pricingLocked;
      stateIcon = Icons.lock_clock;
      final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
      final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
      statusTitle = 'قفل السعر نشط مؤقتاً ($minutes:$seconds)';
      statusDesc = 'السعر مضمون ومقفل بالكامل لمنع أي تحديثات أثناء معالجة الطلب.';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: stateColor.withValues(alpha: 0.25), width: 1.5),
      ),
      color: stateColor.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stateColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(stateIcon, color: stateColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusTitle,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: stateColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusDesc,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 20),

            // Timeline line
            Row(
              children: [
                _buildTimelineNode(
                  context,
                  label: 'إنشاء الحجز',
                  time: _formatDateTime(widget.booking.createdAt),
                  isCompleted: true,
                  isActive: true,
                ),
                _buildTimelineLine(isCompleted: true),
                _buildTimelineNode(
                  context,
                  label: 'ضمان السعر',
                  time: isPermanentLock
                      ? 'مؤكد'
                      : (_isExpired ? 'منتهي' : 'نشط (30 د)'),
                  isCompleted: isPermanentLock || (!_isExpired && _shouldRunTimer()),
                  isActive: !_isExpired || isPermanentLock,
                  isPending: _shouldRunTimer() && !_isExpired && !isPermanentLock,
                ),
                _buildTimelineLine(isCompleted: isPermanentLock),
                _buildTimelineNode(
                  context,
                  label: 'قبول الخدمة',
                  time: isPermanentLock
                      ? _formatDateTime(widget.booking.acceptedAt ?? widget.booking.updatedAt)
                      : 'قيد الانتظار',
                  isCompleted: isPermanentLock,
                  isActive: isPermanentLock,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineNode(
    BuildContext context, {
    required String label,
    required String time,
    required bool isCompleted,
    required bool isActive,
    bool isPending = false,
  }) {
    final themeColor = context.themeColor;
    Color nodeColor;
    if (isCompleted && isActive) {
      nodeColor = Colors.green;
    } else if (isPending) {
      nodeColor = themeColor.pricingLocked;
    } else if (!isActive) {
      nodeColor = Colors.grey.shade400;
    } else {
      nodeColor = themeColor.primary.withValues(alpha: 0.5);
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? nodeColor : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: nodeColor,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : (isPending
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: nodeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black87 : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
