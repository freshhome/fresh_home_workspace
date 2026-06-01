import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';

/// A professional horizontal date picker with service-based availability
/// 
/// Features:
/// - Multiple service support with different booking limits
/// - Visual availability indicators (red for unavailable, default for available)
/// - Smooth animations and transitions
/// - Horizontal scrolling with navigation buttons
/// - Professional, modern UI design
class HorizontalDatePicker extends StatefulWidget {
  /// Currently selected date
  final DateTime selectedDate;

  /// Currently selected service type
  final String selectedService;

  /// Callback when a date is selected
  /// Parameters: selectedDate, serviceType
  final Function(DateTime selectedDate, String serviceType) onDateSelected;

  /// Number of days to display (default: 15)
  final int daysCount;

  /// Availability map for each date and service
  /// Format: { "2025-12-29": { "cleaning": true, "maintenance": false, "pestControl": true } }
  /// true = available, false = unavailable (fully booked)
  final Map<String, Map<String, bool>> availabilityMap;

  /// The date to start counting from (default: tomorrow)
  final DateTime? firstDate;

  const HorizontalDatePicker({
    super.key,
    required this.selectedDate,
    required this.selectedService,
    required this.onDateSelected,
    required this.availabilityMap,
    this.daysCount = 15,
    this.firstDate,
  });

  @override
  State<HorizontalDatePicker> createState() => _HorizontalDatePickerState();
}

class _HorizontalDatePickerState extends State<HorizontalDatePicker> {
  late ScrollController _scrollController;
  final double _itemWidth = 70.0;
  final double _itemSpacing = 10.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Auto-scroll to selected date after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Auto-scroll to the selected date
  void _scrollToSelectedDate() {
    if (!_scrollController.hasClients) return;
    
    final now = DateTime.now();
    final daysDifference = widget.selectedDate.difference(now).inDays;
    
    if (daysDifference >= 0 && daysDifference < widget.daysCount) {
      final targetOffset = daysDifference * (_itemWidth + _itemSpacing);
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Scroll the list forward or backward
  void _scroll(bool forward) {
    if (!_scrollController.hasClients) return;
    
    final double offset = _scrollController.offset + (forward ? 250 : -250);
    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  /// Check if a date is available for the selected service
  bool _isDateAvailable(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final serviceAvailability = widget.availabilityMap[dateKey];
    
    if (serviceAvailability == null) {
      // If no data, assume UNavailable (Fail-Safe)
      return false;
    }
    
    // Convert service name to lowercase for consistency
    final serviceLower = widget.selectedService.toLowerCase().replaceAll(' ', '');
    return serviceAvailability[serviceLower] ?? false; // Fail-Safe
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;
    final themeText = Theme.of(context).extension<AppTextThemeExtension>()!;

    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Back navigation button
          _buildNavButton(
            forward: false,
            themeColor: themeColor,
          ),
          
          const SizedBox(width: 8),
          
          // Horizontal scrolling date list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: widget.daysCount,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final baseDate = widget.firstDate ?? DateTime.now().add(const Duration(days: 1));
                final date = baseDate.add(Duration(days: index));
                final isSelected = DateUtils.isSameDay(date, widget.selectedDate);
                final isAvailable = _isDateAvailable(date);
                
                return _buildDateCard(
                  date: date,
                  isSelected: isSelected,
                  isAvailable: isAvailable,
                  themeColor: themeColor,
                  themeText: themeText,
                );
              },
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Forward navigation button
          _buildNavButton(
            forward: true,
            themeColor: themeColor,
          ),
        ],
      ),
    );
  }

  /// Build individual date card
  Widget _buildDateCard({
    required DateTime date,
    required bool isSelected,
    required bool isAvailable,
    required ThemeColorExtension themeColor,
    required AppTextThemeExtension themeText,
  }) {
    // Determine card colors based on state
    Color cardColor;
    Color textColor;
    Color dateTextColor;
    
    if (!isAvailable) {
      // Unavailable: Red background
      cardColor = Colors.red.shade400;
      textColor = Colors.white;
      dateTextColor = Colors.white.withValues(alpha: 0.9);
    } else if (isSelected) {
      // Selected: Primary color
      cardColor = themeColor.primary;
      textColor = Colors.white;
      dateTextColor = Colors.white.withValues(alpha: 0.95);
    } else {
      // Available: Default card background
      cardColor = themeColor.cardBackground;
      textColor = themeColor.textPrimary;
      dateTextColor = themeColor.textPrimary.withValues(alpha: 0.6);
    }

    return GestureDetector(
      onTap: isAvailable 
        ? () => widget.onDateSelected(date, widget.selectedService)
        : null, // Disable tap for unavailable dates
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _itemWidth,
          height: isSelected ? 90 : 75,
          margin: EdgeInsets.only(right: _itemSpacing),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: themeColor.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      spreadRadius: 1,
                    ),
                  ]
                : !isAvailable
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
            border: !isAvailable
                ? Border.all(
                    color: Colors.red.shade600,
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Day number / Month (e.g., 29/12)
              Text(
                DateFormat('dd/MM').format(date),
                style: themeText.textCaption.copyWith(
                  color: dateTextColor,
                  fontSize: isSelected ? 16 : 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              
              const SizedBox(height: 6),
              
              // Weekday label (e.g., Mon, Tue)
              Text(
                DateFormat('E', Localizations.localeOf(context).languageCode)
                    .format(date),
                style: themeText.textBodyPrimary.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: isSelected ? 16 : 14,
                  letterSpacing: 0.3,
                ),
              ),
              
              // Availability indicator (Dynamic: متاح / غير متاح)
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: !isAvailable
                      ? Colors.white.withValues(alpha: 0.3)
                      : (isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAvailable 
                    ? AppLocalizations.of(context)!.schedule_availability_available
                    : AppLocalizations.of(context)!.schedule_availability_full,
                  style: themeText.textCaption.copyWith(
                    color: !isAvailable
                        ? Colors.white
                        : (isSelected ? Colors.white : Colors.green.shade700),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build navigation button (forward/back arrows)
  Widget _buildNavButton({
    required bool forward,
    required ThemeColorExtension themeColor,
  }) {
    return GestureDetector(
      onTap: () => _scroll(forward),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeColor.cardBackground,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: themeColor.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(
          forward ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
          size: 18,
          color: themeColor.primary,
        ),
      ),
    );
  }
}
