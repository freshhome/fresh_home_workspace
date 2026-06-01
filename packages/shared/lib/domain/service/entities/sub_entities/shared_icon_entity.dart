import 'package:equatable/equatable.dart';

class SharedIconEntity extends Equatable {
  final String id;
  final Map<String, String> name;       // Multilingual: {"ar": "...", "en": "..."}
  final String storagePath;
  final String publicUrl;
  final String category;
  final int usageCount;
  final DateTime? createdAt;

  const SharedIconEntity({
    required this.id,
    required this.name,
    required this.storagePath,
    required this.publicUrl,
    required this.category,
    required this.usageCount,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, storagePath, publicUrl, category, usageCount, createdAt];
}
