import '../../domain/entities/page_stat_entity.dart';

class PageStatModel extends PageStatEntity {
  const PageStatModel({
    required super.path,
    required super.users,
    required super.views,
  });

  factory PageStatModel.fromJson(Map<String, dynamic> json) {
    return PageStatModel(
      path: json['path'] as String? ?? '',
      users: (json['users'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'users': users,
      'views': views,
    };
  }
}
