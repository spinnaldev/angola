import 'dart:convert';

class Category {
  final int id;
  final String name;
  final String imageUrl;
  final String description;
  final String? icon;
  final int serviceCount; 

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    this.icon,
    this.serviceCount = 0,
  });

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
      imageUrl: json['image_url'] ?? '',
      description: decodeName(json['description'] ?? ''),
      icon: json['icon'],
      serviceCount: json['service_count'] ?? 0,
    );
  }
  static List<Category> getDefaultCategories() {
    return [
      Category(
        id: 1,
        name: 'Maison & Construction',
        imageUrl: '',
        description: 'Services pour la maison et construction',
      ),
      Category(
        id: 2,
        name: 'Bien-être & Beauté',
        imageUrl: '',
        description: 'Services de bien-être et beauté',
      ),
      Category(
        id: 3,
        name: 'Événements & Artistiques',
        imageUrl: '',
        description: 'Services pour événements et artistiques',
      ),
      Category(
        id: 4,
        name: 'Transport & Logistique',
        imageUrl: '',
        description: 'Services de transport et logistique',
      ),
      Category(
        id: 5,
        name: 'Santé & Bien-être',
        imageUrl: '',
        description: 'Services de santé et bien-être',
      ),
      Category(
        id: 6,
        name: 'Services Professionnels',
        imageUrl: '',
        description: 'Services professionnels divers',
      ),
      Category(
        id: 7,
        name: 'Services Numériques',
        imageUrl: '',
        description: 'Services numériques et technologies',
      ),
      Category(
        id: 8,
        name: 'Services pour Animaux',
        imageUrl: '',
        description: 'Services pour animaux de compagnie',
      ),
      Category(
        id: 9,
        name: 'Services Divers',
        imageUrl: '',
        description: 'Autres services spécialisés',
      ),
    ];

  }
}
