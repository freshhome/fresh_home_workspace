import 'package:equatable/equatable.dart';
import 'page_stat_entity.dart';

class WebAnalyticsEntity extends Equatable {
  final int totalUsers;
  final int totalViews;
  final List<PageStatEntity> pages;

  const WebAnalyticsEntity({
    required this.totalUsers,
    required this.totalViews,
    required this.pages,
  });

  @override
  List<Object?> get props => [totalUsers, totalViews, pages];
}
