import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:shared/shared.dart';
import 'package:shared/presentation/dialogs/dialog_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services_management_presentation.dart';
import '../widgets/tree_helpers.dart';
import '../../../pricing_governance/presentation/pages/service_pricing_hub_page.dart';
import '../../../../core/di/injection_container.dart' as di;

class ServicesManagementPage extends StatefulWidget {
  const ServicesManagementPage({super.key});

  @override
  State<ServicesManagementPage> createState() => _ServicesManagementPageState();
}

class _ServicesManagementPageState extends State<ServicesManagementPage> {
  // Tree Explorer State
  bool _isLoadingTree = true;
  bool _isSearching = false;
  String _searchQuery = "";
  ServiceEntity? _selectedService;
  Map<String?, List<ServiceEntity>> _adjacencyList = {};
  final Set<String> _expandedNodes = {};

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  Future<void> _loadTree({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingTree = true;
    });

    final getRoots = di.getIt<GetRootServicesUseCase>();
    final getChildren = di.getIt<GetChildrenUseCase>();
    final adj = await TreeHelpers.loadFullActiveTree(
      getRoots,
      getChildren,
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;

    setState(() {
      _adjacencyList = adj;
      _isLoadingTree = false;
      // Do not auto-expand root categories initially to show only main services
    });
  }

  // Filtered nodes based on search query
  bool _shouldShowNode(ServiceEntity node) {
    if (_searchQuery.isEmpty) return true;

    final arTitle = node.title['ar']?.toLowerCase() ?? "";
    final enTitle = node.title['en']?.toLowerCase() ?? "";
    final arDesc = node.description['ar']?.toLowerCase() ?? "";
    final enDesc = node.description['en']?.toLowerCase() ?? "";
    final q = _searchQuery.toLowerCase();

    if (arTitle.contains(q) ||
        enTitle.contains(q) ||
        arDesc.contains(q) ||
        enDesc.contains(q) ||
        node.id.toLowerCase().contains(q)) {
      return true;
    }

    // Check if any descendant matches
    final children = _adjacencyList[node.id] ?? [];
    for (final child in children) {
      if (_shouldShowNode(child)) return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSplitPane = screenWidth >= 768; // Tablet or Desktop view

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: _buildAppBar(themeColor),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocListener<ServicesManagementCubit, ServicesManagementState>(
          listener: (context, state) {
            if (state is ServicesManagementError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
          child: Column(
            children: [
              Expanded(
                child: _isLoadingTree
                    ? Center(
                        child: CircularProgressIndicator(
                          color: themeColor.primary,
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tree View Section (Always visible)
                          Expanded(
                            flex: 3,
                            child: _buildTreeExplorer(themeColor),
                          ),

                          // Split Pane Preview Section (Only visible on Tablet/Desktop)
                          if (isSplitPane)
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: themeColor.unselectedItem
                                          .withValues(alpha: 0.1),
                                    ),
                                  ),
                                  color: themeColor.background,
                                ),
                                child: _buildDetailsPane(
                                  themeColor,
                                  isMobile: false,
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: MyCustomButton(
          width: 170,
          height: 52,
          text: "إضافة تصنيف رئيسي",
          onPressed: () => _openAddWizard(null),
          leadingIcon: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 22,
          ),
          borderRadius: 26,
          backgroundColor: themeColor.primary,
          textStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // --- Standard AppBar with search integration ---
  PreferredSizeWidget _buildAppBar(ThemeColorExtension themeColor) {
    return AppBar(
      backgroundColor: themeColor.primary,
      elevation: 0,
      centerTitle: true,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: _isSearching
          ? TextField(
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontSize: 14,
              ),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: "ابحث عن تصنيف أو خدمة...",
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontFamily: 'Cairo',
                  fontSize: 13,
                ),
                border: InputBorder.none,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            )
          : const Text(
              "إدارة الخدمات",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close_rounded : Icons.search_rounded,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = "";
              }
            });
          },
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  // --- Tree Explorer Widget ---
  Widget _buildTreeExplorer(ThemeColorExtension themeColor) {
    final roots = _adjacencyList[null] ?? [];
    final filteredRoots = roots.where(_shouldShowNode).toList();

    if (filteredRoots.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () => _loadTree(forceRefresh: true),
      color: themeColor.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: filteredRoots.length,
        itemBuilder: (context, index) {
          return _buildTreeNode(filteredRoots[index], 0, themeColor);
        },
      ),
    );
  }

  Color _getCategoryColor(String id) {
    final int hash = id.hashCode.abs();
    final List<Color> colors = [
      const Color(0xFF3B82F6), // Royal Blue
      const Color(0xFF10B981), // Emerald Green
      const Color(0xFFF59E0B), // Amber Gold
      const Color(0xFF8B5CF6), // Violet Purple
      const Color(0xFF0EA5E9), // Sky Blue
      const Color(0xFF06B6D4), // Cyan/Teal
      const Color(0xFF14B8A6), // Teal
    ];
    return colors[hash % colors.length];
  }

  Widget _buildIdBadge(
    String id,
    Color accentColor,
    ThemeColorExtension themeColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: themeColor.unselectedItem.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: themeColor.unselectedItem.withValues(alpha: 0.1),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tag_rounded,
            size: 10,
            color: themeColor.textPrimary.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 3),
          Text(
            id,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: themeColor.textPrimary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // Recursive Tree Node Builder
  Widget _buildTreeNode(
    ServiceEntity node,
    int depth,
    ThemeColorExtension themeColor, {
    Color? inheritedCategoryColor,
    bool isGridItem = false,
  }) {
    final hasChildren = _adjacencyList[node.id]?.isNotEmpty ?? false;
    final isExpanded = _expandedNodes.contains(node.id);
    final isSelected = _selectedService?.id == node.id;
    final displayTitle = node.title['ar'] ?? node.title['en'] ?? "بدون عنوان";
    final displayDesc = node.description['ar'] ?? node.description['en'] ?? "";

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color categoryColor = inheritedCategoryColor ?? _getCategoryColor(node.id);

    // Color theme and sizing logic for cards based on depth
    final double cardBorderRadius;
    final Color cardBg;
    final Color cardBorderColor;
    final double cardBorderWidth;
    final double iconContainerSize;
    final double iconRadius;
    final double titleFontSize;
    final FontWeight titleFontWeight;
    final double verticalMargin;
    final double verticalPadding;
    final double horizontalPadding;
    final bool showAccentBar;
    final double accentBarWidth;
    final double accentBarHeight;

    if (depth == 0) {
      cardBorderRadius = 20;
      cardBg = isSelected
          ? categoryColor.withValues(alpha: isDark ? 0.14 : 0.08)
          : categoryColor.withValues(alpha: isDark ? 0.06 : 0.03);
      cardBorderColor = isSelected ? categoryColor : categoryColor.withValues(alpha: 0.25);
      cardBorderWidth = isSelected ? 2.2 : 1.2;
      iconContainerSize = 56;
      iconRadius = 14;
      titleFontSize = 16;
      titleFontWeight = FontWeight.w800;
      verticalMargin = 8;
      verticalPadding = 16;
      horizontalPadding = 16;
      showAccentBar = true;
      accentBarWidth = 4.5;
      accentBarHeight = 40;
    } else if (depth == 1) {
      cardBorderRadius = 16;
      cardBg = isSelected
          ? themeColor.primary.withValues(alpha: 0.08)
          : themeColor.nestedCardBackground;
      cardBorderColor = isSelected ? themeColor.primary : themeColor.unselectedItem.withValues(alpha: 0.18);
      cardBorderWidth = isSelected ? 1.8 : 1.0;
      iconContainerSize = 46;
      iconRadius = 11;
      titleFontSize = 14;
      titleFontWeight = FontWeight.bold;
      verticalMargin = 5;
      verticalPadding = 12;
      horizontalPadding = 14;
      showAccentBar = true;
      accentBarWidth = 2.5;
      accentBarHeight = 28;
    } else {
      // depth >= 2
      cardBorderRadius = 12;
      cardBg = isSelected
          ? themeColor.primary.withValues(alpha: 0.05)
          : themeColor.background;
      cardBorderColor = isSelected ? themeColor.primary.withValues(alpha: 0.6) : themeColor.unselectedItem.withValues(alpha: 0.1);
      cardBorderWidth = 1.0;
      iconContainerSize = 38;
      iconRadius = 8;
      titleFontSize = 12.5;
      titleFontWeight = FontWeight.w600;
      verticalMargin = 4;
      verticalPadding = 10;
      horizontalPadding = 12;
      showAccentBar = false;
      accentBarWidth = 0;
      accentBarHeight = 0;
    }

    // Grid specific overrides for compact dimensions
    final double finalBorderRadius = isGridItem ? 14 : cardBorderRadius;
    final Color finalBg = isGridItem
        ? (isSelected
            ? themeColor.primary.withValues(alpha: 0.08)
            : (isDark ? themeColor.nestedCardBackground : Colors.white))
        : cardBg;
    final Color finalBorderColor = isGridItem
        ? (isSelected ? themeColor.primary : themeColor.unselectedItem.withValues(alpha: 0.12))
        : cardBorderColor;
    final double finalBorderWidth = isGridItem ? (isSelected ? 1.8 : 1.0) : cardBorderWidth;
    final double finalIconContainerSize = isGridItem ? 40 : iconContainerSize;
    final double finalIconRadius = isGridItem ? 10 : iconRadius;
    final double finalTitleFontSize = isGridItem ? 13 : titleFontSize;
    final FontWeight finalTitleFontWeight = isGridItem ? FontWeight.bold : titleFontWeight;
    final double finalVerticalMargin = isGridItem ? 2 : verticalMargin;
    final double finalVerticalPadding = isGridItem ? 10 : verticalPadding;
    final double finalHorizontalPadding = isGridItem ? 12 : horizontalPadding;
    final bool finalShowAccentBar = isGridItem ? false : showAccentBar;

    // Depth indentation indicator lines
    Widget indentConnector = const SizedBox.shrink();
    if (depth > 0 && !isGridItem) {
      indentConnector = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(depth, (index) {
          return Container(
            margin: const EdgeInsets.only(left: 16),
            width: 1.5,
            color: themeColor.unselectedItem.withValues(alpha: 0.15),
          );
        }),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              indentConnector,
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: finalVerticalMargin),
                  decoration: BoxDecoration(
                    color: finalBg,
                    borderRadius: BorderRadius.circular(finalBorderRadius),
                    border: Border.all(
                      color: finalBorderColor,
                      width: finalBorderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      if (isSelected)
                        BoxShadow(
                          color: (depth == 0 ? categoryColor : themeColor.primary)
                              .withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      if (hasChildren || !node.isBookable) {
                        setState(() {
                          if (isExpanded) {
                            _expandedNodes.remove(node.id);
                          } else {
                            _expandedNodes.add(node.id);
                          }
                        });
                      } else {
                        setState(() {
                          _selectedService = node;
                        });
                        final double screenWidth = MediaQuery.of(context).size.width;
                        if (screenWidth < 768) {
                          _showMobileDetailsSheet(themeColor);
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(finalBorderRadius),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: finalHorizontalPadding,
                        vertical: finalVerticalPadding,
                      ),
                      child: Row(
                        children: [
                          // 1) Right Side: Vertical accent bar + spacing
                          if (finalShowAccentBar) ...[
                            Container(
                              width: accentBarWidth,
                              height: accentBarHeight,
                              decoration: BoxDecoration(
                                color: depth == 0 ? categoryColor : themeColor.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ] else ...[
                            // For nested children, indent spacing slightly
                            const SizedBox(width: 8),
                          ],

                          // 2) Icon / Thumbnail with custom background squircle
                          Container(
                            width: finalIconContainerSize,
                            height: finalIconContainerSize,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (depth == 0 ? categoryColor : themeColor.primary).withValues(
                                alpha: isDark ? 0.12 : 0.06,
                              ),
                              borderRadius: BorderRadius.circular(finalIconRadius + 4),
                              border: Border.all(
                                color: (depth == 0 ? categoryColor : themeColor.primary).withValues(alpha: 0.15),
                                width: 1.0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(finalIconRadius),
                              child: node.image != null && node.image!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: node.image!,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: themeColor.primary,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          _buildPlaceholderIcon(themeColor),
                                    )
                                  : _buildPlaceholderIcon(themeColor),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // 3) Center: Title, Description, and Badges (placed vertically)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(node.status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        displayTitle,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: finalTitleFontSize,
                                          fontWeight: finalTitleFontWeight,
                                          color: themeColor.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (displayDesc.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    displayDesc,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: depth == 0 ? 12 : (depth == 1 ? 11.5 : 11),
                                      color: themeColor.textPrimary.withValues(
                                        alpha: 0.65,
                                      ),
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _buildIdBadge(node.id, categoryColor, themeColor),
                                    _buildNodeBadge(node, themeColor),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // 4) Left Side: Circle Action Buttons (Status control & Settings gear)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!node.isBookable) ...[
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: (depth == 0 ? categoryColor : themeColor.primary).withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.add_rounded,
                                        color: depth == 0 ? categoryColor : themeColor.primary,
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: "إضافة خدمة فرعية",
                                      onPressed: () => _openAddWizard(node.id),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              _buildStatusControlAction(
                                node: node,
                                themeColor: themeColor,
                              ),
                              const SizedBox(width: 8),
                              _buildTrailingAction(
                                hasChildren: hasChildren,
                                isBookable: node.isBookable,
                                isExpanded: isExpanded,
                                categoryColor: categoryColor,
                                themeColor: themeColor,
                                nodeId: node.id,
                                node: node,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Children node builder (Indented and grid-aware layout)
        if (hasChildren && isExpanded)
          Padding(
            padding: EdgeInsets.only(
              right: depth == 0 ? 24.0 : 16.0,
              top: 6,
              bottom: 12,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final children = (_adjacencyList[node.id] ?? [])
                    .where(_shouldShowNode)
                    .toList();

                // If there is enough width, display in 2 columns, otherwise single column.
                final bool useTwoColumns = constraints.maxWidth > 550;
                final double spacing = 12.0;
                final double itemWidth = useTwoColumns
                    ? (constraints.maxWidth - spacing) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: children.map((child) {
                    return SizedBox(
                      width: itemWidth,
                      child: _buildTreeNode(
                        child,
                        depth + 1,
                        themeColor,
                        inheritedCategoryColor: categoryColor,
                        isGridItem: true,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTrailingAction({
    required bool hasChildren,
    required bool isBookable,
    required bool isExpanded,
    required Color categoryColor,
    required ThemeColorExtension themeColor,
    required String nodeId,
    required ServiceEntity node,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: IconButton(
          icon: Icon(
            Icons.settings_rounded,
            color: categoryColor,
            size: 18,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            setState(() {
              _selectedService = node;
            });

            // On mobile viewports, show preview details in a sliding bottom sheet
            final double screenWidth = MediaQuery.of(context).size.width;
            if (screenWidth < 768) {
              _showMobileDetailsSheet(themeColor);
            }
          },
        ),
      ),
    );
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.active:
        return const Color(0xFF10B981);
      case ServiceStatus.ready:
        return const Color(0xFF3B82F6);
      case ServiceStatus.paused:
        return const Color(0xFFEF4444);
      case ServiceStatus.review:
        return const Color(0xFFF59E0B);
      case ServiceStatus.draft:
        return const Color(0xFF6B7280);
      case ServiceStatus.archived:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData _getStatusIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.active:
        return Icons.play_arrow_rounded;
      case ServiceStatus.ready:
        return Icons.check_circle_rounded;
      case ServiceStatus.paused:
        return Icons.pause_circle_filled_rounded;
      case ServiceStatus.review:
        return Icons.rate_review_rounded;
      case ServiceStatus.draft:
        return Icons.edit_note_rounded;
      case ServiceStatus.archived:
        return Icons.archive_rounded;
    }
  }

  Future<void> _updateServiceStatus(ServiceEntity service, ServiceStatus newStatus) async {
    DialogHelper.showLoading(context);
    try {
      final updateUseCase = di.getIt<UpdateServiceUseCase>();
      final result = await updateUseCase(service.copyWith(status: newStatus));

      if (!mounted) return;
      DialogHelper.dismissLoading(context);

      result.fold(
        (failure) {
          DialogHelper.showError(
            context,
            message: "فشل تحديث حالة الخدمة: ${failure.message}",
          );
        },
        (savedService) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("تم تغيير حالة الخدمة إلى ${newStatus.arabicLabel} بنجاح!"),
              backgroundColor: Colors.green,
            ),
          );
          _loadTree(forceRefresh: true);
        },
      );
    } catch (e) {
      if (!mounted) return;
      DialogHelper.dismissLoading(context);
      DialogHelper.showError(
        context,
        message: "حدث خطأ غير متوقع: $e",
      );
    }
  }

  Widget _buildStatusControlAction({
    required ServiceEntity node,
    required ThemeColorExtension themeColor,
  }) {
    final statusColor = _getStatusColor(node.status);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          popupMenuTheme: PopupMenuThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        child: PopupMenuButton<ServiceStatus>(
          icon: Icon(
            _getStatusIcon(node.status),
            color: statusColor,
            size: 18,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'تغيير حالة الخدمة',
          onSelected: (ServiceStatus status) {
            if (node.status == status) return;
            _updateServiceStatus(node, status);
          },
          itemBuilder: (BuildContext context) {
            return ServiceStatus.values.map((status) {
              final isCurrent = node.status == status;
              return PopupMenuItem<ServiceStatus>(
                value: status,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        status.arabicLabel,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? themeColor.primary : themeColor.textPrimary,
                        ),
                      ),
                      if (isCurrent) ...[
                        const Spacer(),
                        Icon(
                          Icons.check_rounded,
                          color: themeColor.primary,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildNodeBadge(ServiceEntity node, ThemeColorExtension themeColor) {
    if (node.isBookable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: themeColor.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: themeColor.secondary.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        child: Text(
          "خدمة حجز",
          style: TextStyle(
            fontSize: 9,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: themeColor.secondary.withValues(alpha: 0.8),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: themeColor.unselectedItem.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: themeColor.unselectedItem.withValues(alpha: 0.1),
            width: 0.8,
          ),
        ),
        child: Text(
          "تصنيف",
          style: TextStyle(
            fontSize: 9,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: themeColor.textPrimary.withValues(alpha: 0.5),
          ),
        ),
      );
    }
  }

  // --- Left Details Pane Widget (Split-pane or Bottom Sheet) ---
  Widget _buildDetailsPane(
    ThemeColorExtension themeColor, {
    required bool isMobile,
  }) {
    if (_selectedService == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_shared_outlined,
                size: 64,
                color: themeColor.unselectedItem.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),
              const Text(
                "اختر خدمة أو تصنيف من الهيكل الشجري لعرض تفاصيلها والتحكم بها فوراً.",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final service = _selectedService!;
    final arTitle = service.title['ar'] ?? "بدون عنوان";
    final enTitle = service.title['en'] ?? "";
    final arDesc = service.description['ar'] ?? "";
    final enDesc = service.description['en'] ?? "";

    // Status color
    final bool isActive = service.status == ServiceStatus.active;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row containing title and close icon if on bottom sheet
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "لوحة الخصائص والإجراءات",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: themeColor.primary,
                ),
              ),
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),

          // Icon / Image banner
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: themeColor.serviceIconBackground,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: service.image != null && service.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: service.image!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: themeColor.primary,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.cleaning_services_rounded,
                          size: 40,
                          color: themeColor.primary.withValues(alpha: 0.4),
                        ),
                      )
                    : Icon(
                        Icons.cleaning_services_rounded,
                        size: 40,
                        color: themeColor.primary.withValues(alpha: 0.4),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Titles & description
          Center(
            child: Column(
              children: [
                Text(
                  arTitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeColor.textPrimary,
                  ),
                ),
                if (enTitle.isNotEmpty)
                  Text(
                    enTitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: themeColor.unselectedItem,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.shade50
                            : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? Colors.green : Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isActive ? "نشط" : "مسودة",
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? Colors.green.shade900
                                  : Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: service.isBookable
                            ? themeColor.secondary.withValues(alpha: 0.08)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        service.isBookable ? "خدمة حجز" : "تصنيف فرعي",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: service.isBookable
                              ? themeColor.secondary
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Descriptions
          if (arDesc.isNotEmpty || enDesc.isNotEmpty) ...[
            _buildInfoLabel("الوصف (عربي)"),
            Text(
              arDesc.isNotEmpty ? arDesc : "لا يوجد وصف عربي",
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: themeColor.textPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
          ],

          _buildInfoLabel("ترتيب الظهور"),
          Text(
            "${service.order}",
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: themeColor.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Pricing info summary if bookable
          if (service.isBookable && service.price != null) ...[
            _buildInfoLabel("تفاصيل التسعير الأساسية"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColor.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: themeColor.unselectedItem.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    color: themeColor.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "السعر: ${service.price!.value} ج.م / ${service.price!.unit.isNotEmpty ? service.price!.unit : 'وحدة'}",
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: themeColor.textPrimary,
                          ),
                        ),
                        Text(
                          "طريقة التسعير: ${_getPricingMethodLabel(service.price!.type)}",
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: themeColor.unselectedItem,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Quick Action Buttons
          _buildInfoLabel("إجراءات التحكم"),

          // 1. Edit Configurator (Wizard)
          SizedBox(
            width: double.infinity,
            child: MyCustomButton(
              text: "تعديل إعدادات وخصائص الخدمة",
              onPressed: () => _openEditWizard(service),
              backgroundColor: themeColor.primary,
              leadingIcon: const Icon(
                Icons.settings_suggest_outlined,
                color: Colors.white,
                size: 20,
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Pricing & Form Simulator (Only for bookables)
          if (service.isBookable && service.price != null) ...[
            SizedBox(
              width: double.infinity,
              child: MyCustomButton(
                text: "تعديل قواعد الأسعار والحقول",
                onPressed: () => _openPriceBuilder(service),
                isOutlined: true,
                borderColor: themeColor.secondary,
                leadingIcon: Icon(
                  Icons.calculate_outlined,
                  color: themeColor.secondary,
                  size: 20,
                ),
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: themeColor.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 3. Add sub-category/service (only for non-bookables)
          if (!service.isBookable) ...[
            SizedBox(
              width: double.infinity,
              child: MyCustomButton(
                text: "إضافة فئة أو خدمة فرعية تحتها",
                onPressed: () => _openAddWizard(service.id),
                isOutlined: true,
                borderColor: themeColor.primary.withValues(alpha: 0.5),
                leadingIcon: Icon(
                  Icons.playlist_add_rounded,
                  color: themeColor.primary,
                  size: 20,
                ),
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: themeColor.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 4. Archive/Delete Button
          SizedBox(
            width: double.infinity,
            child: MyCustomButton(
              text: "أرشفة أو حذف هذا العنصر",
              onPressed: () => _showDeleteConfirmation(context, service),
              backgroundColor: Colors.transparent,
              isOutlined: true,
              borderColor: Colors.redAccent.withValues(alpha: 0.3),
              leadingIcon: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          color: context.themeColor.unselectedItem,
        ),
      ),
    );
  }

  // --- Show Details in Bottom Sheet on Mobile ---
  void _showMobileDetailsSheet(ThemeColorExtension themeColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeColor.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: _buildDetailsPane(themeColor, isMobile: true),
        );
      },
    ).then((_) {
      // Clear selection on sheet close if preferred, or keep
    });
  }

  // --- Navigation & Action Methods ---
  void _openAddWizard(String? parentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (wizardContext) => ServiceConfiguratorWizardPage(
          defaultParentId: parentId,
          onSubmit: (newService, pageContext) async {
            DialogHelper.showConfirmation(
              pageContext,
              title: "تأكيد إضافة الخدمة",
              desc: "هل أنت متأكد من رغبتك في إضافة هذه الخدمة/التصنيف الجديد؟",
              okText: "تأكيد الحفظ",
              cancelText: "إلغاء",
              onConfirm: () async {
                DialogHelper.showLoading(pageContext);
                try {
                  final addUseCase = di.getIt<AddServiceUseCase>();
                  final entity = newService.copyWith(
                    parentId: newService.parentId ?? parentId,
                  );
                  final result = await addUseCase(entity);

                  if (!pageContext.mounted) return;
                  DialogHelper.dismissLoading(pageContext);

                  result.fold(
                    (failure) {
                      debugPrint(
                        "===========فشل حفظ الخدمة=========== ${failure.message}",
                      );
                      DialogHelper.showError(
                        pageContext,
                        message: "فشل حفظ الخدمة: ${failure.message}",
                      );
                    },
                    (savedService) {
                      DialogHelper.showSuccess(
                        pageContext,
                        message: "تم حفظ الخدمة بنجاح!",
                        onOkPress: () {
                          Navigator.pop(pageContext); // Close wizard
                          _loadTree();
                        },
                        onDismiss: (_) {
                          Navigator.pop(pageContext); // Close wizard
                          _loadTree();
                        },
                      );
                    },
                  );
                } catch (e) {
                  if (!pageContext.mounted) return;
                  DialogHelper.dismissLoading(pageContext);
                  debugPrint("===========حدث خطأ غير متوقع=========== $e");
                  DialogHelper.showError(
                    pageContext,
                    message: "حدث خطأ غير متوقع: $e",
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }

  void _openEditWizard(ServiceEntity service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (wizardContext) => ServiceConfiguratorWizardPage(
          initialData: service,
          onSubmit: (updatedService, pageContext) async {
            DialogHelper.showConfirmation(
              pageContext,
              title: "تأكيد تعديل الخدمة",
              desc: "هل أنت متأكد من حفظ التعديلات الجديدة؟",
              okText: "حفظ التعديلات",
              cancelText: "إلغاء",
              onConfirm: () async {
                DialogHelper.showLoading(pageContext);
                try {
                  final updateUseCase = di.getIt<UpdateServiceUseCase>();
                  final result = await updateUseCase(updatedService);

                  if (!pageContext.mounted) return;
                  DialogHelper.dismissLoading(pageContext);

                  result.fold(
                    (failure) {
                      debugPrint(
                        "===========فشل حفظ التعديلات=========== ${failure.message}",
                      );
                      DialogHelper.showError(
                        pageContext,
                        message: "فشل حفظ التعديلات: ${failure.message}",
                      );
                    },
                    (savedService) {
                      DialogHelper.showSuccess(
                        pageContext,
                        message: "تم حفظ التعديلات بنجاح!",
                        onOkPress: () {
                          Navigator.pop(pageContext); // Close wizard
                          _loadTree();
                        },
                        onDismiss: (_) {
                          Navigator.pop(pageContext); // Close wizard
                          _loadTree();
                        },
                      );
                    },
                  );
                } catch (e) {
                  if (!pageContext.mounted) return;
                  DialogHelper.dismissLoading(pageContext);
                  debugPrint("===========حدث خطأ غير متوقع=========== $e");
                  DialogHelper.showError(
                    pageContext,
                    message: "حدث خطأ غير متوقع: $e",
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }

  void _openPriceBuilder(ServiceEntity service) {
    if (service.price == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (builderContext) => ServicePricingHubPage(
          subServiceId: service.id,
          initialService: service,
        ),
      ),
    ).then((_) {
      _loadTree();
    });
  }


  void _showDeleteConfirmation(
    BuildContext context,
    ServiceEntity service,
  ) async {
    final getRoots = di.getIt<GetRootServicesUseCase>();
    final getChildren = di.getIt<GetChildrenUseCase>();

    final adj = await TreeHelpers.loadFullActiveTree(getRoots, getChildren);
    final children = adj[service.id] ?? [];

    if (!context.mounted) return;

    if (children.isEmpty) {
      _showNormalDeleteDialog(context, service);
    } else {
      // Collect all non-bookable nodes as potential targets
      final List<ServiceEntity> categories = [];
      adj.forEach((parent, list) {
        for (final s in list) {
          if (!s.isBookable) {
            categories.add(s);
          }
        }
      });

      final excluded = {service.id};
      excluded.addAll(TreeHelpers.getDescendantIds(service.id, adj));
      final reassignableCategories = categories
          .where((c) => !excluded.contains(c.id))
          .toList();

      _showCascadeDeleteDialog(
        context,
        service,
        children.length,
        reassignableCategories,
      );
    }
  }

  void _showNormalDeleteDialog(BuildContext context, ServiceEntity service) {
    final themeColor = context.themeColor;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: themeColor.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "تأكيد الأرشفة",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: themeColor.textPrimary,
          ),
        ),
        content: const Text(
          "هل أنت متأكد من رغبتك في أرشفة هذه الخدمة؟ لن تظهر في قائمة الحجز للعملاء بعد ذلك.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cairo',
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    "إلغاء",
                    style: TextStyle(
                      color: themeColor.unselectedItem,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);

                    DialogHelper.showLoading(context);

                    final updateUseCase = di.getIt<UpdateServiceUseCase>();
                    final archivedEntity = service.copyWith(
                      status: ServiceStatus.archived,
                    );

                    updateUseCase(archivedEntity)
                        .then((result) {
                          if (!context.mounted) return;
                          DialogHelper.dismissLoading(context);
                          result.fold(
                            (failure) {
                              debugPrint(
                                "===========فشل أرشفة الخدمة=========== ${failure.message}",
                              );
                              DialogHelper.showError(
                                context,
                                message: "فشل أرشفة الخدمة: ${failure.message}",
                              );
                            },
                            (_) {
                              DialogHelper.showSuccess(
                                context,
                                message: "تم أرشفة الخدمة بنجاح!",
                                onOkPress: () {
                                  setState(() {
                                    _selectedService = null;
                                  });
                                  _loadTree();
                                },
                                onDismiss: (_) {
                                  setState(() {
                                    _selectedService = null;
                                  });
                                  _loadTree();
                                },
                              );
                            },
                          );
                        })
                        .catchError((e) {
                          if (!context.mounted) return;
                          DialogHelper.dismissLoading(context);
                          debugPrint("===========حدث خطأ غير متوقع=========== $e");
                          DialogHelper.showError(
                            context,
                            message: "حدث خطأ غير متوقع: $e",
                          );
                        });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5252),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "أرشفة",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCascadeDeleteDialog(
    BuildContext context,
    ServiceEntity service,
    int childrenCount,
    List<ServiceEntity> reassignableCategories,
  ) {
    final themeColor = context.themeColor;
    String? selectedReassignId;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: themeColor.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                "خيارات أرشفة التصنيف الرئيسي",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "هذا التصنيف يحتوي على ($childrenCount) من الخدمات/التصنيفات التابعة. يرجى تحديد الإجراء المناسب قبل الأرشفة:",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: themeColor.unselectedItem,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (reassignableCategories.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      initialValue: selectedReassignId,
                      isExpanded: true,
                      dropdownColor: themeColor.cardBackground,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: themeColor.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: "نقل الخدمات التابعة إلى تصنيف آخر",
                        labelStyle: TextStyle(
                          color: themeColor.unselectedItem,
                          fontSize: 11,
                          fontFamily: 'Cairo',
                        ),
                        prefixIcon: Icon(
                          Icons.swap_horiz_rounded,
                          color: themeColor.secondary,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: themeColor.cardBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: themeColor.unselectedItem.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: 'root',
                          child: Text(
                            "تصنيف رئيسي (بدون أب)",
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                        ...reassignableCategories.map((c) {
                          final title =
                              c.title['ar'] ?? c.title['en'] ?? 'بدون عنوان';
                          return DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(
                              title,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedReassignId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                Column(
                  children: [
                    if (reassignableCategories.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: MyCustomButton(
                          text: "نقل الخدمات ثم الأرشفة",
                          onPressed: selectedReassignId == null
                              ? null
                              : () {
                                  Navigator.pop(
                                    dialogContext,
                                  ); // Close options dialog

                                  DialogHelper.showConfirmation(
                                    context,
                                    title: "تأكيد النقل والأرشفة",
                                    desc:
                                        "هل أنت متأكد من رغبتك في نقل كافة الخدمات التابعة لهذا التصنيف وأرشفته؟",
                                    okText: "نقل وأرشفة",
                                    cancelText: "إلغاء",
                                    onConfirm: () async {
                                      DialogHelper.showLoading(context);
                                      final result =
                                          await _performReassignAndDelete(
                                            service.id,
                                            selectedReassignId!,
                                          );
                                      if (!context.mounted) return;
                                      DialogHelper.dismissLoading(context);

                                      result.fold(
                                        (failure) {
                                          debugPrint(
                                            "===========فشل نقل وأرشفة الخدمات=========== ${failure.message}",
                                          );
                                          DialogHelper.showError(
                                            context,
                                            message:
                                                "فشل نقل وأرشفة الخدمات: ${failure.message}",
                                          );
                                        },
                                        (_) {
                                          DialogHelper.showSuccess(
                                            context,
                                            message:
                                                "تم نقل الخدمات التابعة وأرشفة التصنيف بنجاح!",
                                            onOkPress: () {
                                              setState(() {
                                                _selectedService = null;
                                              });
                                              _loadTree();
                                            },
                                            onDismiss: (_) {
                                              setState(() {
                                                _selectedService = null;
                                              });
                                              _loadTree();
                                            },
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                          backgroundColor: themeColor.primary,
                          textStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          borderRadius: 12,
                          height: 44,
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: MyCustomButton(
                        text:
                            "أرشفة التصنيف وكافة الخدمات التابعة له (حذف متتالي)",
                        onPressed: () {
                          Navigator.pop(dialogContext); // Close options dialog

                          DialogHelper.showConfirmation(
                            context,
                            title: "تأكيد الحذف المتتالي",
                            desc:
                                "تحذير: هل أنت متأكد من رغبتك في أرشفة هذا التصنيف وكافة الفئات والخدمات التابعة له بالتوالي؟",
                            okText: "تأكيد الأرشفة",
                            cancelText: "إلغاء",
                            onConfirm: () async {
                              DialogHelper.showLoading(context);
                                  final result = await _performCascadeDelete(
                                    service.id,
                                  );
                                  if (!context.mounted) return;
                                  DialogHelper.dismissLoading(context);

                                  result.fold(
                                    (failure) {
                                      debugPrint(
                                        "===========فشل الأرشفة المتتالية=========== ${failure.message}",
                                      );
                                      DialogHelper.showError(
                                        context,
                                        message:
                                            "فشل الأرشفة المتتالية: ${failure.message}",
                                      );
                                },
                                (_) {
                                  DialogHelper.showSuccess(
                                    context,
                                    message:
                                        "تم أرشفة التصنيف وكافة الخدمات التابعة له بنجاح!",
                                    onOkPress: () {
                                      setState(() {
                                        _selectedService = null;
                                      });
                                      _loadTree();
                                    },
                                    onDismiss: (_) {
                                      setState(() {
                                        _selectedService = null;
                                      });
                                      _loadTree();
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                        backgroundColor: const Color(0xFFFF5252),
                        textStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        borderRadius: 12,
                        height: 44,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        "إلغاء",
                        style: TextStyle(
                          color: themeColor.unselectedItem,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Either<Failure, void>> _performCascadeDelete(String serviceId) async {
    try {
      final getChildren = di.getIt<GetChildrenUseCase>();
      final updateUseCase = di.getIt<UpdateServiceUseCase>();

      final List<ServiceEntity> descendants = [];
      await _collectDescendantsRecursive(serviceId, descendants, getChildren);

      final List<Future<Either<Failure, ServiceEntity>>> futures = [];

      for (final desc in descendants) {
        futures.add(
          updateUseCase(desc.copyWith(status: ServiceStatus.archived)),
        );
      }

      ServiceEntity? targetEntity;
      _adjacencyList.forEach((parent, list) {
        for (final s in list) {
          if (s.id == serviceId) {
            targetEntity = s;
          }
        }
      });

      targetEntity ??= ServiceEntity(
        id: serviceId,
        parentId: null,
        isBookable: false,
        title: const {},
        description: const {},
        status: ServiceStatus.archived,
        updatedAt: DateTime.now(),
        order: 0,
      );

      futures.add(
        updateUseCase(targetEntity!.copyWith(status: ServiceStatus.archived)),
      );

      final results = await Future.wait(futures);

      Failure? firstFailure;
      for (final res in results) {
        res.fold((failure) => firstFailure = failure, (_) {});
      }

      if (firstFailure != null) {
        return Left(firstFailure!);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<void> _collectDescendantsRecursive(
    String nodeId,
    List<ServiceEntity> descendants,
    GetChildrenUseCase getChildren,
  ) async {
    final result = await getChildren(nodeId);
    await result.fold((failure) async {}, (children) async {
      for (final child in children) {
        descendants.add(child);
        await _collectDescendantsRecursive(child.id, descendants, getChildren);
      }
    });
  }

  Future<Either<Failure, void>> _performReassignAndDelete(
    String serviceId,
    String newParentId,
  ) async {
    try {
      final getChildren = di.getIt<GetChildrenUseCase>();
      final updateUseCase = di.getIt<UpdateServiceUseCase>();

      final childrenResult = await getChildren(serviceId);

      return await childrenResult.fold((failure) async => Left(failure), (
        children,
      ) async {
        final List<Future<Either<Failure, ServiceEntity>>> futures = [];

        for (final child in children) {
          futures.add(
            updateUseCase(
              child.copyWith(
                parentId: newParentId == 'root' ? null : newParentId,
              ),
            ),
          );
        }

        ServiceEntity? targetEntity;
        _adjacencyList.forEach((parent, list) {
          for (final s in list) {
            if (s.id == serviceId) {
              targetEntity = s;
            }
          }
        });

        targetEntity ??= ServiceEntity(
          id: serviceId,
          parentId: null,
          isBookable: false,
          title: const {},
          description: const {},
          status: ServiceStatus.archived,
          updatedAt: DateTime.now(),
          order: 0,
        );

        futures.add(
          updateUseCase(targetEntity!.copyWith(status: ServiceStatus.archived)),
        );

        final results = await Future.wait(futures);

        Failure? firstFailure;
        for (final res in results) {
          res.fold((failure) => firstFailure = failure, (_) {});
        }

        if (firstFailure != null) {
          return Left(firstFailure!);
        }

        return const Right(null);
      });
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }



  // --- UI Helpers ---
  Widget _buildPlaceholderIcon(ThemeColorExtension themeColor) {
    return Center(
      child: Icon(
        Icons.cleaning_services_rounded,
        size: 20,
        color: themeColor.primary.withValues(alpha: 0.3),
      ),
    );
  }

  String _getPricingMethodLabel(PricingMethod method) {
    switch (method) {
      case PricingMethod.fixed:
        return "سعر ثابت";
      case PricingMethod.perSquareMeter:
        return "سعر لكل متر مربع";
      case PricingMethod.perLinearMeter:
        return "سعر لكل متر طولي";
      case PricingMethod.perIssue:
        return "سعر لكل وحدة / مشكلة";
      case PricingMethod.inspection:
        return "سعر معاينة / فحص";
      default:
        return "غير محدد";
    }
  }

  // Header section was removed to maximize vertical screen space.

  Widget _buildEmptyState(BuildContext context) {
    final themeColor = context.themeColor;
    return RefreshIndicator(
      onRefresh: () => _loadTree(forceRefresh: true),
      color: themeColor.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.category_outlined,
                size: 70,
                color: themeColor.unselectedItem.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                "لا توجد فئات أو خدمات حالياً",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "اسحب للأسفل للتحديث أو اضغط على الزر أدناه لمزامنة شجرة الخدمات من الخادم.",
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Cairo',
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadTree(forceRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text(
                  "تحديث ومزامنة البيانات",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// HeaderClipper class was removed since the header was replaced with standard AppBar.
