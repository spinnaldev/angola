import 'dart:convert';

class Category {
  final int id;
  final String name;
  final String nameEn;  // Nom en anglais
  final String nameFr;  // Nom en français
  final String imageUrl;
  final String description;
  final String descriptionEn;  // Description en anglais
  final String descriptionFr;  // Description en français
  final String? icon;
  final int serviceCount;

  Category({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.nameFr,
    required this.imageUrl,
    required this.description,
    required this.descriptionEn,
    required this.descriptionFr,
    this.icon,
    this.serviceCount = 0,
  });

  // Méthode pour obtenir le nom selon la langue
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

  // Méthode pour obtenir la description selon la langue
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

  factory Category.fromJson(Map<String, dynamic> json) {
    // Gestion de l'encodage UTF-8 pour les accents
    String decodeName(String input) {
      try {
        // Si le texte contient des caractères mal encodés, essayer de le décoder
        if (input.contains('Ã') || input.contains('Â') || input.contains('Ä')) {
          return utf8.decode(input.codeUnits);
        }
        return input;
      } catch (e) {
        print("Erreur d'encodage: $e");
        return input;
      }
    }

    // Appliquer la fonction de décodage aux champs textuels
    return Category(
      id: json['id'],
      name: decodeName(json['name'] ?? ''),
      nameEn: decodeName(json['name_en'] ?? json['name'] ?? ''),
      nameFr: decodeName(json['name_fr'] ?? json['name'] ?? ''),
      imageUrl: json['image_url'] ?? '',
      description: decodeName(json['description'] ?? ''),
      descriptionEn: decodeName(json['description_en'] ?? json['description'] ?? ''),
      descriptionFr: decodeName(json['description_fr'] ?? json['description'] ?? ''),
      icon: json['icon'],
      serviceCount: json['service_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'name_fr': nameFr,
      'image_url': imageUrl,
      'description': description,
      'description_en': descriptionEn,
      'description_fr': descriptionFr,
      'icon': icon,
      'service_count': serviceCount,
    };
  }

  static List<Category> getDefaultCategories() {
    return [
      Category(
        id: 1,
        name: 'Maison & Construction',
        nameEn: 'Home & Construction',
        nameFr: 'Maison & Construction',
        imageUrl: '',
        description: 'Services pour la maison et construction',
        descriptionEn: 'Home and construction services',
        descriptionFr: 'Services pour la maison et construction',
      ),
      Category(
        id: 2,
        name: 'Bien-être & Beauté',
        nameEn: 'Wellness & Beauty',
        nameFr: 'Bien-être & Beauté',
        imageUrl: '',
        description: 'Services de bien-être et beauté',
        descriptionEn: 'Wellness and beauty services',
        descriptionFr: 'Services de bien-être et beauté',
      ),
      Category(
        id: 3,
        name: 'Événements & Artistiques',
        nameEn: 'Events & Artistic',
        nameFr: 'Événements & Artistiques',
        imageUrl: '',
        description: 'Services pour événements et artistiques',
        descriptionEn: 'Event and artistic services',
        descriptionFr: 'Services pour événements et artistiques',
      ),
      Category(
        id: 4,
        name: 'Transport & Logistique',
        nameEn: 'Transport & Logistics',
        nameFr: 'Transport & Logistique',
        imageUrl: '',
        description: 'Services de transport et logistique',
        descriptionEn: 'Transport and logistics services',
        descriptionFr: 'Services de transport et logistique',
      ),
      Category(
        id: 5,
        name: 'Santé & Bien-être',
        nameEn: 'Health & Wellness',
        nameFr: 'Santé & Bien-être',
        imageUrl: '',
        description: 'Services de santé et bien-être',
        descriptionEn: 'Health and wellness services',
        descriptionFr: 'Services de santé et bien-être',
      ),
      Category(
        id: 6,
        name: 'Services Professionnels',
        nameEn: 'Professional Services',
        nameFr: 'Services Professionnels',
        imageUrl: '',
        description: 'Services professionnels divers',
        descriptionEn: 'Various professional services',
        descriptionFr: 'Services professionnels divers',
      ),
      Category(
        id: 7,
        name: 'Services Numériques',
        nameEn: 'Digital Services',
        nameFr: 'Services Numériques',
        imageUrl: '',
        description: 'Services numériques et technologies',
        descriptionEn: 'Digital services and technologies',
        descriptionFr: 'Services numériques et technologies',
      ),
      Category(
        id: 8,
        name: 'Services pour Animaux',
        nameEn: 'Pet Services',
        nameFr: 'Services pour Animaux',
        imageUrl: '',
        description: 'Services pour animaux de compagnie',
        descriptionEn: 'Pet care services',
        descriptionFr: 'Services pour animaux de compagnie',
      ),
      Category(
        id: 9,
        name: 'Services Divers',
        nameEn: 'Miscellaneous Services',
        nameFr: 'Services Divers',
        imageUrl: '',
        description: 'Autres services spécialisés',
        descriptionEn: 'Other specialized services',
        descriptionFr: 'Autres services spécialisés',
      ),
    ];
  }
}
//   static List<Category> getDefaultCategories() {
//     return [
//       Category(
//         id: 1,
//         name: 'Maison & Construction',
//         imageUrl: '',
//         description: 'Services pour la maison et construction',
//       ),
//       Category(
//         id: 2,
//         name: 'Bien-être & Beauté',
//         imageUrl: '',
//         description: 'Services de bien-être et beauté',
//       ),
//       Category(
//         id: 3,
//         name: 'Événements & Artistiques',
//         imageUrl: '',
//         description: 'Services pour événements et artistiques',
//       ),
//       Category(
//         id: 4,
//         name: 'Transport & Logistique',
//         imageUrl: '',
//         description: 'Services de transport et logistique',
//       ),
//       Category(
//         id: 5,
//         name: 'Santé & Bien-être',
//         imageUrl: '',
//         description: 'Services de santé et bien-être',
//       ),
//       Category(
//         id: 6,
//         name: 'Services Professionnels',
//         imageUrl: '',
//         description: 'Services professionnels divers',
//       ),
//       Category(
//         id: 7,
//         name: 'Services Numériques',
//         imageUrl: '',
//         description: 'Services numériques et technologies',
//       ),
//       Category(
//         id: 8,
//         name: 'Services pour Animaux',
//         imageUrl: '',
//         description: 'Services pour animaux de compagnie',
//       ),
//       Category(
//         id: 9,
//         name: 'Services Divers',
//         imageUrl: '',
//         description: 'Autres services spécialisés',
//       ),
//     ];

//   }
// }
