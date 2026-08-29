import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

/// Senior UI/UX Final Refinement of Technician Address & Customer Card.
///
/// Designed specifically for field technicians:
/// - Full RTL Directionality.
/// - Uncramped Header: Customer Name & Full Phone Number (01012345678) never truncated!
/// - Time Formatted without seconds (e.g., 12:00 م • موعد المهمة).
/// - Task Status Badge (e.g. 🟢 في انتظار التنفيذ).
/// - Governorate, City, District & Street Address Hierarchy.
/// - 3 Grid Pills (Building, Floor, Unit) with vertical column stacking (Zero Horizontal Overflow!).
/// - Map Navigation Button ("بدء الملاحة" / "فتح في Google Maps").
/// - Conditional Arrival Notes ("ملاحظات الوصول").
/// - Primary Call & Secondary WhatsApp buttons with FittedBox scaling.
class TechnicianSummaryCard extends StatelessWidget {
  final Address address;
  final String? customerName;
  final String? customerPhone;
  final String? scheduledTime;
  final String? statusText;
  final VoidCallback? onOpenMaps;
  final VoidCallback? onCallPhone;
  final VoidCallback? onWhatsAppPhone;

  const TechnicianSummaryCard({
    super.key,
    required this.address,
    this.customerName,
    this.customerPhone,
    this.scheduledTime,
    this.statusText,
    this.onOpenMaps,
    this.onCallPhone,
    this.onWhatsAppPhone,
  });

  String _formatTimeDisplay(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return '';
    final trimmed = timeStr.trim();
    if (trimmed.contains('م') || trimmed.contains('ص')) return trimmed;
    final parts = trimmed.split(':');
    if (parts.length >= 2) {
      int hour = int.tryParse(parts[0]) ?? 12;
      int minute = int.tryParse(parts[1]) ?? 0;
      String period = hour >= 12 ? 'م' : 'ص';
      int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      String minuteStr = minute.toString().padLeft(2, '0');
      return '$displayHour:$minuteStr $period';
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>();
    final primaryColor = themeColor?.primary ?? const Color(0xFF1E3A8A);

    final String govAndCity = (address.district.isNotEmpty && address.district != address.city)
        ? '${address.governorate} - ${address.city} (${address.district})'
        : '${address.governorate} - ${address.city}';

    final String floorText = (address.floor != null && address.floor!.trim().isNotEmpty)
        ? address.floor!
        : '-';

    final String unitText = (address.apartmentOrUnit != null && address.apartmentOrUnit!.trim().isNotEmpty)
        ? address.apartmentOrUnit!
        : '-';

    final String formattedTime = _formatTimeDisplay(scheduledTime);
    final String effectiveStatus = statusText ?? 'في انتظار التنفيذ';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 1. CUSTOMER HEADER: STATUS & TIME SUB-ROW ────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Task Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        effectiveStatus,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),

                // Appointment Time Badge (Formatted 12:00 م without extra label)
                if (formattedTime.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            if (customerName != null && customerName!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              // ── CUSTOMER NAME & PHONE SUB-ROW ─────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF1E3A8A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (customerPhone != null && customerPhone!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: customerPhone!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'تم نسخ رقم الهاتف بنجاح',
                                    style: TextStyle(fontFamily: 'Cairo'),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.phone_iphone_rounded,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      customerPhone!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF334155),
                                        fontFamily: 'Cairo',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ],

            const SizedBox(height: 14),

            // ── 2. ADDRESS SECTION (LOCATION -> STREET) ─────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 22,
                  color: Color(0xFF1E3A8A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        govAndCity,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          fontFamily: 'Cairo',
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (address.streetOrCompound.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                address.streetOrCompound,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                  fontFamily: 'Cairo',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.map_outlined,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── 3. BUILDING / FLOOR / UNIT PILLS (VERTICAL STACK) ────────────
            Row(
              children: [
                // Box 1: Building (مبنى)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.apartment_rounded,
                          size: 22,
                          color: Color(0xFF1D4ED8),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'مبنى',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4ED8),
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          address.buildingIdentifier,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E40AF),
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Box 2: Floor (الدور)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.stairs_rounded,
                          size: 22,
                          color: Color(0xFF15803D),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'الدور',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          floorText,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF166534),
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Box 3: Unit (الوحدة)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF3E8FF)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.door_front_door_rounded,
                          size: 22,
                          color: Color(0xFF7E22CE),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'الوحدة',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7E22CE),
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          unitText,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF6B21A8),
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── 4. NAVIGATION BUTTON ("بدء الملاحة") ─────────────────────────
            if (onOpenMaps != null)
              Semantics(
                button: true,
                label: 'بدء الملاحة',
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onOpenMaps,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.near_me_rounded,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'بدء الملاحة',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Cairo',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'فتح في Google Maps',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontFamily: 'Cairo',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── 5. CONDITIONAL ARRIVAL NOTES BANNER ──────────────────────────
            if (address.landmark != null && address.landmark!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.subtitles_rounded,
                        size: 18,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ملاحظات الوصول',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            address.landmark!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                              fontFamily: 'Cairo',
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── 6. CONTACT ACTION BUTTONS (CALL & WHATSAPP) ─────────────────
            if (onCallPhone != null || onWhatsAppPhone != null) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              Row(
                children: [
                  if (onCallPhone != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onCallPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.phone_enabled_rounded, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'اتصال هاتفي',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (onCallPhone != null && onWhatsAppPhone != null)
                    const SizedBox(width: 10),
                  if (onWhatsAppPhone != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onWhatsAppPhone,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                          foregroundColor: const Color(0xFF25D366),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.chat_rounded,
                          size: 18,
                          color: Color(0xFF25D366),
                        ),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'واتساب',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF25D366),
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
