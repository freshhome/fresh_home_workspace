import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';

class CustomSlider extends StatefulWidget {
  final List<String> images;

  const CustomSlider({super.key, required this.images});

  @override
  State<CustomSlider> createState() => _CustomSliderState();
}

class _CustomSliderState extends State<CustomSlider> { // شيلنا التيكر بروفايدر مكسين
  late final PageController _pageController;
  Timer? _timer; // خليناه Nullable عشان نقدر نوقفه
  int _currentPage = 0;
  static const _autoScrollDuration = Duration(seconds: 4);
  static const _transitionDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer?.cancel(); // تأكيد إلغاء أي تايمر سابق
    _timer = Timer.periodic(_autoScrollDuration, (_) {
      if (!mounted) return;
      if (!_pageController.hasClients) return;
      
      // Prevent queuing animations when the widget is offstage (e.g., in another bottom nav tab)
      // This solves the Signal 3 ANR crash when returning to the Home tab.
      if (!TickerMode.of(context)) return;
      
      // لو المستخدم واقف في آخر صورة، يرجع للأول، غير كدة يروح للي بعدها
      final nextPage = (_currentPage >= widget.images.length - 1) ? 0 : _currentPage + 1;
      
      _pageController.animateToPage(
        nextPage,
        duration: _transitionDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoScroll() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          // Listener عشان نهندل لمس المستخدم
          child: Listener(
            onPointerDown: (_) => _stopAutoScroll(), // وقف التايمر لما يلمس
            onPointerUp: (_) => _startAutoScroll(),   // شغله تاني لما يسيب
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (_, index) => _buildSliderItem(index),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildIndicators(),
      ],
    );
  }

  Widget _buildSliderItem(int index) {
    final isCurrentPage = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: isCurrentPage ? 0 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          if (isCurrentPage)
             Theme.of(context).extension<ThemeColorExtension>()!.cardShadow,
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          widget.images[index],
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.error_outline, size: 40, color: Colors.red),
          ),
          // loadingBuilder... (نفس الكود القديم أو استخدم cached_network_image)
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.images.length, (index) {
        final isCurrentPage = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrentPage ? 12 : 8,
          height: isCurrentPage ? 12 : 8,
          decoration: BoxDecoration(
            // استخدمنا لون الثيم بدل الأزرق الصريح
            color: isCurrentPage 
                ? Theme.of(context).extension<ThemeColorExtension>()!.primary
                : Theme.of(context).extension<ThemeColorExtension>()!.unselectedItem,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}