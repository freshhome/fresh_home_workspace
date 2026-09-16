import '../../domain/entities/web_analytics_entity.dart';
import 'page_stat_model.dart';

class WebAnalyticsModel extends WebAnalyticsEntity {
  const WebAnalyticsModel({
    required super.totalUsers,
    required super.totalViews,
    required List<PageStatModel> super.pages,
  });

  factory WebAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final pagesRaw = json['pages'] as List<dynamic>? ?? [];
    final pages = pagesRaw
        .map((e) => PageStatModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return WebAnalyticsModel(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      pages: pages,
    );
  }
}
