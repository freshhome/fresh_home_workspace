import 'package:shared/shared.dart';

class TreeHelpers {
  static Future<Map<String?, List<ServiceEntity>>> loadFullActiveTree(
    GetRootServicesUseCase getRoots,
    GetChildrenUseCase getChildren,
  ) async {
    final Map<String?, List<ServiceEntity>> adjacencyList = {};
    final rootsResult = await getRoots();
    
    await rootsResult.fold(
      (failure) async {},
      (roots) async {
        adjacencyList[null] = roots;
        for (final root in roots) {
          if (!root.isBookable) {
            await _loadDescendants(root.id, getChildren, adjacencyList);
          }
        }
      },
    );
    return adjacencyList;
  }

  static Future<void> _loadDescendants(
    String parentId,
    GetChildrenUseCase getChildren,
    Map<String?, List<ServiceEntity>> adjacencyList,
  ) async {
    final result = await getChildren(parentId);
    await result.fold(
      (failure) async {},
      (children) async {
        if (children.isNotEmpty) {
          adjacencyList[parentId] = children;
          for (final child in children) {
            if (!child.isBookable) {
              await _loadDescendants(child.id, getChildren, adjacencyList);
            }
          }
        }
      },
    );
  }

  static Set<String> getDescendantIds(
    String nodeId,
    Map<String?, List<ServiceEntity>> adjacencyList,
  ) {
    final Set<String> descendants = {};
    _addDescendants(nodeId, adjacencyList, descendants);
    return descendants;
  }

  static void _addDescendants(
    String nodeId,
    Map<String?, List<ServiceEntity>> adjacencyList,
    Set<String> descendants,
  ) {
    final children = adjacencyList[nodeId] ?? [];
    for (final child in children) {
      descendants.add(child.id);
      _addDescendants(child.id, adjacencyList, descendants);
    }
  }
}
