import 'package:equatable/equatable.dart';

class PageStatEntity extends Equatable {
  final String path;
  final int users;
  final int views;

  const PageStatEntity({
    required this.path,
    required this.users,
    required this.views,
  });

  @override
  List<Object?> get props => [path, users, views];
}
