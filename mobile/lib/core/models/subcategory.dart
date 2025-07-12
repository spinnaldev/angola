class Subcategory {
  final int id;
  final String name;
  final String nameEn;
  final String nameFr;
  final int categoryId;
  final String description;
  final String descriptionEn;
  final String descriptionFr;

  Subcategory({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.nameFr,
    required this.categoryId,
    required this.description,
    required this.descriptionEn,
    required this.descriptionFr,
  });

  String getLocalizedName(String locale) {
    switch (locale) {
      case 'en':
        return nameEn.isNotEmpty ? nameEn : name;
      case 'fr':
        return nameFr.isNotEmpty ? nameFr : name;
      default:
        return name;
    }
  }

  String getLocalizedDescription(String locale) {
    switch (locale) {
      case 'en':
        return descriptionEn.isNotEmpty ? descriptionEn : description;
      case 'fr':
        return descriptionFr.isNotEmpty ? descriptionFr : description;
      default:
        return description;
    }
  }

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      name: json['name'] ?? '',
      nameEn: json['name_en'] ?? json['name'] ?? '',
      nameFr: json['name_fr'] ?? json['name'] ?? '',
      categoryId: json['category'] ?? json['category_id'] ?? 0,
      description: json['description'] ?? '',
      descriptionEn: json['description_en'] ?? json['description'] ?? '',
      descriptionFr: json['description_fr'] ?? json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'name_fr': nameFr,
      'category': categoryId,
      'category_id': categoryId,
      'description': description,
      'description_en': descriptionEn,
      'description_fr': descriptionFr,
    };
  }
}