class LanguageContentEntity {
  final String? title;
  final String? icon;
  final String? iconPath;
  final String? iconId;
  final List<String>? points;

  const LanguageContentEntity({
    this.title,
    this.icon,
    this.iconPath,
    this.iconId,
    this.points,
  });
}

class NotIncludedEntity {
  final LanguageContentEntity ar;
  final LanguageContentEntity en;

  const NotIncludedEntity({required this.ar, required this.en});
}

class DetailEntity {
  final String? id;
  final LanguageContentEntity ar;
  final LanguageContentEntity en;

  const DetailEntity({this.id, required this.ar, required this.en});
}
