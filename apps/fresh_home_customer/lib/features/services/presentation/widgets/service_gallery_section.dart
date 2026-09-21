import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared/shared.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';

class ServiceGallerySection extends StatelessWidget {
  final List<ServiceGalleryItemEntity>? gallery;

  const ServiceGallerySection({
    super.key,
    required this.gallery,
  });

  @override
  Widget build(BuildContext context) {
    if (gallery == null || gallery!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final themeColor = Theme.of(context).extension<ThemeColorExtension>();
    final themeText = Theme.of(context).extension<AppTextThemeExtension>();
    final primaryColor = themeColor?.primary ?? const Color(0xFF0091FF);
    final textPrimaryColor = themeColor?.textPrimary ?? const Color(0xFF1E293B);
    final secondaryTextColor = themeColor?.secondaryText ?? const Color(0xFF64748B);
    final cardBgColor = themeColor?.cardBackground ?? Colors.white;
    final items = gallery!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'معرض الأعمال والنماذج' : 'Work & Examples Gallery',
                      style: themeText?.titleSectionMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textPrimaryColor,
                            fontFamily: 'Cairo',
                          ) ??
                          TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textPrimaryColor,
                            fontFamily: 'Cairo',
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'صور حقيقية لأعمالنا لضمان أعلى جودة'
                          : 'Real photos from our certified services',
                      style: themeText?.textCaption.copyWith(
                            fontSize: 11,
                            color: secondaryTextColor,
                            fontFamily: 'Cairo',
                          ) ??
                          TextStyle(
                            fontSize: 11,
                            color: secondaryTextColor,
                            fontFamily: 'Cairo',
                          ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '${items.length} ${isArabic ? (items.length == 1 ? "صورة" : "صور") : (items.length == 1 ? "Photo" : "Photos")}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Horizontal Gallery Carousel
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];

              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => FullscreenGalleryViewer(
                        items: items,
                        initialIndex: index,
                        isArabic: isArabic,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image with Caching
                      CachedNetworkImage(
                        imageUrl: item.url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ShimmerLoading(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 18,
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: secondaryTextColor,
                            size: 32,
                          ),
                        ),
                      ),

                      // Gradient Overlay
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.75),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.caption?.isNotEmpty == true
                                      ? item.caption!
                                      : (isArabic ? 'معاينة النموذج' : 'View Sample'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.fullscreen_rounded,
                                  color: Colors.white,
                                  size: 16,
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
            },
          ),
        ),
      ],
    );
  }
}

class FullscreenGalleryViewer extends StatefulWidget {
  final List<ServiceGalleryItemEntity> items;
  final int initialIndex;
  final bool isArabic;

  const FullscreenGalleryViewer({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.isArabic,
  });

  @override
  State<FullscreenGalleryViewer> createState() => _FullscreenGalleryViewerState();
}

class _FullscreenGalleryViewerState extends State<FullscreenGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.items[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.items.length}',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Pinch-to-zoom interactive page viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (idx) {
              setState(() {
                _currentIndex = idx;
              });
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];

              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: item.url,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white38,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Caption Bar at bottom
          if (currentItem.caption?.isNotEmpty == true)
            Positioned(
              left: 20,
              right: 20,
              bottom: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Text(
                  currentItem.caption!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
