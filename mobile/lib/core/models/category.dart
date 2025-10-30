// mobile/lib/core/models/category.dart

class Category {
  final int id;
  final String name;        // PORTUGAIS (langue de base)
  final String nameEn;      // Anglais
  final String nameFr;      // Français
  final String imageUrl;
  final String description; // PORTUGAIS (langue de base)
  final String descriptionEn; // Anglais
  final String descriptionFr; // Français
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

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',           // PORTUGAIS
      nameEn: json['name_en'] ?? '',      // Anglais
      nameFr: json['name_fr'] ?? '',      // Français
      imageUrl: json['image_url'] ?? '',
      description: json['description'] ?? '',        // PORTUGAIS
      descriptionEn: json['description_en'] ?? '',   // Anglais
      descriptionFr: json['description_fr'] ?? '',   // Français
      icon: json['icon'],
      serviceCount: json['service_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,           // PORTUGAIS
      'name_en': nameEn,      // Anglais
      'name_fr': nameFr,      // Français
      'image_url': imageUrl,
      'description': description,        // PORTUGAIS
      'description_en': descriptionEn,   // Anglais
      'description_fr': descriptionFr,   // Français
      'icon': icon,
      'service_count': serviceCount,
    };
  }

  static List<Category> getDefaultCategories() {
    return [
      Category(
        id: 1,
        name: 'Casa & Construção',                    // PORTUGAIS
        nameEn: 'Home & Construction',                // Anglais
        nameFr: 'Maison & Construction',              // Français
        imageUrl: '',
        description: 'Serviços para construção, renovação e manutenção da casa',
        descriptionEn: 'Services for construction, renovation and home maintenance',
        descriptionFr: 'Services pour la construction, rénovation et entretien de la maison',
      ),
      Category(
        id: 2,
        name: 'Bem-estar & Beleza',
        nameEn: 'Wellness & Beauty',
        nameFr: 'Bien-être & Beauté',
        imageUrl: '',
        description: 'Serviços de cuidados pessoais e beleza',
        descriptionEn: 'Personal care and beauty services',
        descriptionFr: 'Services de soins personnels et de beauté',
      ),
      Category(
        id: 3,
        name: 'Eventos & Artísticos',
        nameEn: 'Events & Artistic',
        nameFr: 'Événements & Artistiques',
        imageUrl: '',
        description: 'Serviços para organização de eventos e apresentações artísticas',
        descriptionEn: 'Services for event organization and artistic performances',
        descriptionFr: 'Services pour l\'organisation d\'événements et prestations artistiques',
      ),
      Category(
        id: 4,
        name: 'Aluguel de Locais',
        nameEn: 'Venue Rental',
        nameFr: 'Location de lieux',
        imageUrl: '',
        description: 'Aluguel de espaços para casamentos, aniversários e eventos privados',
        descriptionEn: 'Space rental for weddings, birthdays and private events',
        descriptionFr: 'Location d\'espaces pour mariages, anniversaires et événements privés',
      ),
      Category(
        id: 5,
        name: 'Transporte & Logística',
        nameEn: 'Transport & Logistics',
        nameFr: 'Transport & Logistique',
        imageUrl: '',
        description: 'Serviços de transporte de pessoas e mercadorias',
        descriptionEn: 'People and goods transportation services',
        descriptionFr: 'Services de transport de personnes et marchandises',
      ),
      Category(
        id: 6,
        name: 'Saúde & Bem-estar',
        nameEn: 'Health & Wellness',
        nameFr: 'Santé & Bien-être',
        imageUrl: '',
        description: 'Serviços relacionados à saúde e bem-estar',
        descriptionEn: 'Health and wellness related services',
        descriptionFr: 'Services liés à la santé et au bien-être',
      ),
      Category(
        id: 7,
        name: 'Serviços Profissionais & Formação',
        nameEn: 'Professional Services & Training',
        nameFr: 'Services Professionnels & Formation',
        imageUrl: '',
        description: 'Serviços profissionais e treinamentos diversos',
        descriptionEn: 'Professional services and various training',
        descriptionFr: 'Services professionnels et formations diverses',
      ),
      Category(
        id: 8,
        name: 'Serviços Digitais & Tecnológicos',
        nameEn: 'Digital & Technology Services',
        nameFr: 'Services Numériques & Technologiques',
        imageUrl: '',
        description: 'Serviços relacionados ao digital e tecnologias',
        descriptionEn: 'Services related to digital and technologies',
        descriptionFr: 'Services liés au numérique et aux technologies',
      ),
      Category(
        id: 9,
        name: 'Serviços para Animais',
        nameEn: 'Pet Services',
        nameFr: 'Services pour Animaux',
        imageUrl: '',
        description: 'Serviços de cuidados e hospedagem de animais',
        descriptionEn: 'Pet care and boarding services',
        descriptionFr: 'Services de soins et garde d\'animaux',
      ),
      Category(
        id: 10,
        name: 'Serviços Diversos',
        nameEn: 'Miscellaneous Services',
        nameFr: 'Services Divers',
        imageUrl: '',
        description: 'Outros serviços especializados',
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
