import 'package:flutter/material.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/theme/components/colors/theme_color_extension.dart';
import 'package:shared/presentation/theme/components/text_theme/app_text_theme_extension.dart';

extension SelectionThemeContext on BuildContext {
  AppTextThemeExtension get themeText => Theme.of(this).extension<AppTextThemeExtension>()!;
}

class SelectionField extends StatefulWidget {
  final String? value;
  final String hint;
  final IconData? icon;
  final VoidCallback onTap;
  final String? Function(String?)? validator;

  const SelectionField({
    super.key,
    this.value,
    required this.hint,
    this.icon,
    required this.onTap,
    this.validator,
  });

  @override
  State<SelectionField> createState() => _SelectionFieldState();
}

class _SelectionFieldState extends State<SelectionField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void didUpdateWidget(SelectionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      // Synchronize FormField value and trigger validation after the current build frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fieldKey.currentState?.didChange(widget.value);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final themeText = context.themeText;
    final bool hasValue = widget.value != null;

    return FormField<String>(
      key: _fieldKey,
      validator: widget.validator,
      initialValue: widget.value,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: hasValue ? themeColor.cardBackground : themeColor.nestedCardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: state.hasError
                        ? themeColor.error
                        : (hasValue ? themeColor.primary : themeColor.unselectedItem.withValues(alpha: 0.1)),
                    width: hasValue ? 1.5 : 1,
                  ),
                  boxShadow: hasValue
                      ? [
                          BoxShadow(
                            color: themeColor.primary.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasValue ? themeColor.primary.withValues(alpha: 0.1) : themeColor.unselectedItem.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon!,
                          color: hasValue ? themeColor.primary : themeColor.secondaryText,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.value ?? widget.hint,
                            maxLines: 2,
                            style: themeText.textBodyPrimary.copyWith(
                              color: hasValue ? themeColor.textPrimary : themeColor.textPrimary.withValues(alpha: 0.5),
                              fontWeight: hasValue ? FontWeight.w900 : FontWeight.bold,
                              fontSize: hasValue ? 14 : 13,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: hasValue ? themeColor.primary : themeColor.secondaryText,
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: Text(
                  state.errorText ?? '',
                  style: TextStyle(color: themeColor.error, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

class SelectionSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selectedValue;

  const SelectionSheet({
    super.key,
    required this.title,
    required this.items,
    this.selectedValue,
  });

  @override
  State<SelectionSheet> createState() => _SelectionSheetState();
}

class _SelectionSheetState extends State<SelectionSheet> {
  late List<String> _filteredItems;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filter(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final themeText = context.themeText;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: themeColor.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: themeColor.unselectedItem.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: themeText.titleSectionMedium.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: themeColor.unselectedItem.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: l10n.booking_search_region,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: themeColor.unselectedItem.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: themeColor.primary, width: 1),
                ),
              ),
            ),
          ),
          
          // List / Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final isSelected = item == widget.selectedValue;
                
                return InkWell(
                  onTap: () => Navigator.pop(context, item),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? themeColor.primary : themeColor.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? themeColor.primary : themeColor.unselectedItem.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: themeColor.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              )
                            ],
                    ),
                    child: Stack(
                      children: [
                        if (isSelected)
                          Positioned(
                            top: -10,
                            left: -10,
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: themeColor.onPrimary.withValues(alpha: 0.1),
                              size: 60,
                            ),
                          ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              item,
                              textAlign: TextAlign.center,
                              style: themeText.textBodyPrimary.copyWith(
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                                color: isSelected ? themeColor.onPrimary : themeColor.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: themeColor.onPrimary,
                              size: 16,
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
      ),
    );
  }
}
