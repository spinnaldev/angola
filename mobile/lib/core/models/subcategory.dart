// mobile/lib/core/models/subcategory.dart

class Subcategory {
  final int id;
  final String name;        // PORTUGAIS (langue de base)
  final String nameEn;      // Anglais
  final String nameFr;      // Français
  final int categoryId;
  final String description; // PORTUGAIS (langue de base)
  final String descriptionEn; // Anglais
  final String descriptionFr; // Français

  Subcategory({
    required this.id,
    required this.name,       // PORTUGAIS par défaut
    required this.nameEn,
    required this.nameFr,
    required this.categoryId,
    required this.description, // PORTUGAIS par défaut
    required this.descriptionEn,
    required this.descriptionFr,
  });

  // Méthode pour obtenir le nom selon la langue
  String getLocalizedName(String locale) {
    switch (locale) {
      case 'en':
        return nameEn.isNotEmpty ? nameEn : name;
      case 'fr':
        return nameFr.isNotEmpty ? nameFr : name;
      case 'pt':
      default:
        return name; // PORTUGAIS par défaut
    }
  }

  // Méthode pour obtenir la description selon la langue
  String getLocalizedDescription(String locale) {
    switch (locale) {
      case 'en':
        return descriptionEn.isNotEmpty ? descriptionEn : description;
      case 'fr':
        return descriptionFr.isNotEmpty ? descriptionFr : description;
      case 'pt':
      default:
        return description; // PORTUGAIS par défaut
    }
  }

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      name: json['name'] ?? '',           // PORTUGAIS
      nameEn: json['name_en'] ?? '',      // Anglais
      nameFr: json['name_fr'] ?? '',      // Français
      categoryId: json['category'] ?? json['category_id'] ?? 0,
      description: json['description'] ?? '',        // PORTUGAIS
      descriptionEn: json['description_en'] ?? '',   // Anglais
      descriptionFr: json['description_fr'] ?? '',   // Français
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,           // PORTUGAIS
      'name_en': nameEn,      // Anglais
      'name_fr': nameFr,      // Français
      'category': categoryId,
      'category_id': categoryId,
      'description': description,        // PORTUGAIS
      'description_en': descriptionEn,   // Anglais
      'description_fr': descriptionFr,   // Français
    };
  }
}