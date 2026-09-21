class ServiceGalleryItemEntity {
  final String url;
  final String? id;
  final String? caption;

  const ServiceGalleryItemEntity({
    required this.url,
    this.id,
    this.caption,
  });

  ServiceGalleryItemEntity copyWith({
    String? url,
    String? id,
    String? caption,
  }) {
    return ServiceGalleryItemEntity(
      url: url ?? this.url,
      id: id ?? this.id,
      caption: caption ?? this.caption,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceGalleryItemEntity &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          id == other.id &&
          caption == other.caption;

  @override
  int get hashCode => url.hashCode ^ id.hashCode ^ caption.hashCode;
}
