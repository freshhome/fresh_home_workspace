import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared/shared.dart';

const Color _emeraldColor = Color(0xFF059669);

class ServiceCustomerPreview extends StatefulWidget {
  final ServiceEntity service;
  final String? parentCategoryTitle;

  const ServiceCustomerPreview({
    super.key,
    required this.service,
    this.parentCategoryTitle,
  });

  @override
  State<ServiceCustomerPreview> createState() => _ServiceCustomerPreviewState();
}

class _ServiceCustomerPreviewState extends State<ServiceCustomerPreview> {
  bool _isArabic = true;

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final s = widget.service;
    final isBookable = s.isBookable;

    final title = (s.title[_isArabic ? 'ar' : 'en'] ?? '').trim().isNotEmpty
        ? s.title[_isArabic ? 'ar' : 'en']!
        : (_isArabic ? 'بدون عنوان' : 'Untitled Service');

    final description = (s.description[_isArabic ? 'ar' : 'en'] ?? '').trim().isNotEmpty
        ? s.description[_isArabic ? 'ar' : 'en']!
        : (_isArabic ? 'لا يوجد وصف مضاف' : 'No description provided');

    final gallery = s.gallery ?? [];
    final details = s.details ?? [];
    final exclusions = _isArabic
        ? (s.notIncluded?.ar.points ?? [])
        : (s.notIncluded?.en.points ?? []);
    final instructions = s.instructions?[_isArabic ? 'ar' : 'en'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Inspection & Language Control Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _emeraldColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: _emeraldColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isArabic ? "معاينة مباشرة كواجهة العميل" : "Live Customer App Preview",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: themeColor.textPrimary,
                        ),
                      ),
                      Text(
                        _isArabic
                            ? "تحقق من مظهر الخدمة قبل الاعتماد والنشر النهائي"
                            : "Inspect the final presentation before publishing",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: themeColor.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Language Switcher Chips
              Container(
                decoration: BoxDecoration(
                  color: themeColor.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.15)),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildLangChip("عربي", _isArabic, () => setState(() => _isArabic = true), themeColor),
                    _buildLangChip("EN", !_isArabic, () => setState(() => _isArabic = false), themeColor),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Centered Mobile Device Frame Mockup
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: themeColor.background,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: themeColor.unselectedItem.withValues(alpha: 0.25),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Directionality(
              textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Simulated Client AppBar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    color: themeColor.primary,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 12),
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),

                  // Mobile Content Scroll Area
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 650),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Paused or Active Status Banner
                          if (s.status == ServiceStatus.paused) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _isArabic
                                          ? "تنويه: ستتوفر هذه الخدمة قريباً للعملاء"
                                          : "Notice: Service will be available soon",
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // 2. Service Hero Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: themeColor.cardBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Service Icon/Image Badge
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: themeColor.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: themeColor.primary.withValues(alpha: 0.15)),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: s.image != null && s.image!.trim().isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: s.image!.trim(),
                                          fit: BoxFit.contain,
                                          errorWidget: (context, url, error) => Icon(
                                            Icons.cleaning_services_rounded,
                                            color: themeColor.primary,
                                            size: 32,
                                          ),
                                        )
                                      : Icon(Icons.cleaning_services_rounded, color: themeColor.primary, size: 32),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (widget.parentCategoryTitle != null && widget.parentCategoryTitle!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          margin: const EdgeInsets.only(bottom: 6),
                                          decoration: BoxDecoration(
                                            color: themeColor.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            widget.parentCategoryTitle!,
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: themeColor.primary,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: themeColor.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        description,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 12,
                                          color: themeColor.secondaryText,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 3. Price Indicator Card (If Bookable)
                          if (isBookable && s.price != null) ...[
                            _buildPriceCard(s.price!, themeColor),
                            const SizedBox(height: 14),
                          ],

                          // 4. Service Gallery Section
                          _buildGallerySection(gallery, themeColor),

                          const SizedBox(height: 14),

                          // 5. Inclusions / Service Details Section
                          if (isBookable && details.isNotEmpty) ...[
                            _buildInclusionsSection(details, themeColor),
                            const SizedBox(height: 14),
                          ],

                          // 6. Exclusions Section
                          if (isBookable && exclusions.isNotEmpty) ...[
                            _buildExclusionsSection(exclusions, themeColor),
                            const SizedBox(height: 14),
                          ],

                          // 7. Instructions Section
                          if (instructions.isNotEmpty) ...[
                            _buildInstructionsSection(instructions, themeColor),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Simulated Floating CTA Bottom Bar
                  if (isBookable)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeColor.cardBackground,
                        border: Border(top: BorderSide(color: themeColor.unselectedItem.withValues(alpha: 0.1))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: null, // Preview mode only
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor.primary,
                                disabledBackgroundColor: themeColor.primary,
                                disabledForegroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              child: Text(
                                _isArabic ? "حجز الخدمة (معاينة العميل)" : "Book Service (Client Preview)",
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLangChip(String label, bool isSelected, VoidCallback onTap, ThemeColorExtension themeColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : themeColor.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard(PriceEntity price, ThemeColorExtension themeColor) {
    String typeLabel = _isArabic ? "السعر الأساسي التقديري" : "Estimated Base Price";
    String unit = price.unit.trim().isNotEmpty ? price.unit.trim() : (_isArabic ? "ج.م" : "EGP");

    if (price.type == PricingMethod.fixed) {
      typeLabel = _isArabic ? "السعر الأساسي الثابت" : "Fixed Base Price";
    } else if (price.type == PricingMethod.perSquareMeter) {
      typeLabel = _isArabic ? "سعر المتر المربع" : "Price Per Square Meter";
      unit = _isArabic ? "ج.م / م²" : "EGP / m²";
    } else if (price.type == PricingMethod.perLinearMeter) {
      typeLabel = _isArabic ? "سعر المتر الطولي" : "Price Per Linear Meter";
      unit = _isArabic ? "ج.م / م" : "EGP / m";
    } else if (price.type == PricingMethod.inspection) {
      typeLabel = _isArabic ? "رسوم المعاينة الميدانية" : "Inspection Fee";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: themeColor.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                typeLabel,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: themeColor.secondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price.value.toStringAsFixed(price.value.truncateToDouble() == price.value ? 0 : 2),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: themeColor.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: themeColor.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.payments_rounded, color: themeColor.primary, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection(List<ServiceGalleryItemEntity> gallery, ThemeColorExtension themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_library_rounded, color: themeColor.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _isArabic ? "صور واقعية من تنفيذنا" : "Work & Examples Gallery",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: themeColor.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: themeColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${gallery.length} ${_isArabic ? (gallery.length == 1 ? 'صورة' : 'صور') : 'Photos'}",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: themeColor.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (gallery.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: themeColor.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
              ),
              child: Center(
                child: Text(
                  _isArabic ? "لم يتم رفع أي صور في المعرض بعد" : "No gallery images uploaded yet",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: themeColor.secondaryText,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: gallery.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = gallery[index];
                  return Container(
                    width: 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.black,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: item.url,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white54),
                        ),
                        if (item.caption != null && item.caption!.trim().isNotEmpty)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              color: Colors.black.withValues(alpha: 0.7),
                              child: Text(
                                item.caption!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInclusionsSection(List<DetailEntity> details, ThemeColorExtension themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: _emeraldColor, size: 18),
              const SizedBox(width: 8),
              Text(
                _isArabic ? "تفاصيل الخدمة (ما تشمله)" : "Service Inclusions",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: themeColor.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...details.map((detail) {
            final content = _isArabic ? detail.ar : detail.en;
            final title = content.title ?? '';
            final points = content.points ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeColor.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: themeColor.textPrimary,
                    ),
                  ),
                  if (points.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...points.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ", style: TextStyle(color: _emeraldColor, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  p,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: themeColor.secondaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExclusionsSection(List<String> exclusions, ThemeColorExtension themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                _isArabic ? "ما لا تشمله الخدمة (استثناءات)" : "Not Included (Exclusions)",
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...exclusions.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("✕ ", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                    Expanded(
                      child: Text(
                        p,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection(List<String> instructions, ThemeColorExtension themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, color: themeColor.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                _isArabic ? "تعليمات وإرشادات الخدمة" : "Booking Instructions",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: themeColor.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...instructions.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: themeColor.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          color: themeColor.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
