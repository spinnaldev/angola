// lib/core/models/client_project.dart - Version améliorée avec copyWith
import 'user.dart';
import 'category.dart';
import 'project_skill.dart';
import 'subcategory.dart';

class ClientProject {
  final int id;
  final String title;
  final String description;
  final User? client;
  final String clientName;
  final Category? category;
  final String categoryName;
  final Subcategory? subcategory;
  final String? subcategoryName;
  final String budgetRange;
  final double? minBudget;
  final double? maxBudget;
  final String budgetDisplay;
  final String location;
  final bool remotePossible;
  final DateTime? deadline;
  final String urgency;
  final String status;
  final bool contactViaPlatform;
  final bool showEmail;
  final bool showPhone;
  final List<String> requiredSkills; // Simplifié pour les mock data
  final int offersCount;
  final int viewsCount;
  final DateTime createdAt;
  final String? timeSincePosted;
  final bool? isFavorited;
  final bool? hasUserOffered;
  final String? attachment1;
  final String? attachment2;
  final String? attachment3;
  final List<Map<String, String>>? attachments; // Liste des attachments

  ClientProject({
    required this.id,
    required this.title,
    required this.description,
    this.client,
    required this.clientName,
    this.category,
    required this.categoryName,
    this.subcategory,
    this.subcategoryName,
    required this.budgetRange,
    this.minBudget,
    this.maxBudget,
    required this.budgetDisplay,
    required this.location,
    required this.remotePossible,
    this.deadline,
    required this.urgency,
    required this.status,
    required this.contactViaPlatform,
    required this.showEmail,
    required this.showPhone,
    required this.requiredSkills,
    required this.offersCount,
    required this.viewsCount,
    required this.createdAt,
    this.timeSincePosted,
    this.isFavorited,
    this.hasUserOffered,
    this.attachment1,
    this.attachment2,
    this.attachment3,
    this.attachments,
  });

  // Méthode copyWith pour créer une copie modifiée
  ClientProject copyWith({
    int? id,
    String? title,
    String? description,
    User? client,
    String? clientName,
    Category? category,
    String? categoryName,
    Subcategory? subcategory,
    String? subcategoryName,
    String? budgetRange,
    double? minBudget,
    double? maxBudget,
    String? budgetDisplay,
    String? location,
    bool? remotePossible,
    DateTime? deadline,
    String? urgency,
    String? status,
    bool? contactViaPlatform,
    bool? showEmail,
    bool? showPhone,
    List<String>? requiredSkills,
    int? offersCount,
    int? viewsCount,
    DateTime? createdAt,
    String? timeSincePosted,
    bool? isFavorited,
    bool? hasUserOffered,
    String? attachment1,
    String? attachment2,
    String? attachment3,
    List<Map<String, String>>? attachments,
  }) {
    return ClientProject(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      client: client ?? this.client,
      clientName: clientName ?? this.clientName,
      category: category ?? this.category,
      categoryName: categoryName ?? this.categoryName,
      subcategory: subcategory ?? this.subcategory,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      budgetRange: budgetRange ?? this.budgetRange,
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
      budgetDisplay: budgetDisplay ?? this.budgetDisplay,
      location: location ?? this.location,
      remotePossible: remotePossible ?? this.remotePossible,
      deadline: deadline ?? this.deadline,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      contactViaPlatform: contactViaPlatform ?? this.contactViaPlatform,
      showEmail: showEmail ?? this.showEmail,
      showPhone: showPhone ?? this.showPhone,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      offersCount: offersCount ?? this.offersCount,
      viewsCount: viewsCount ?? this.viewsCount,
      createdAt: createdAt ?? this.createdAt,
      timeSincePosted: timeSincePosted ?? this.timeSincePosted,
      isFavorited: isFavorited ?? this.isFavorited,
      hasUserOffered: hasUserOffered ?? this.hasUserOffered,
      attachment1: attachment1 ?? this.attachment1,
      attachment2: attachment2 ?? this.attachment2,
      attachment3: attachment3 ?? this.attachment3,
      attachments: attachments ?? this.attachments,
    );
  }

  factory ClientProject.fromJson(Map<String, dynamic> json) {
    try {
      // Gestion des compétences requises
      List<String> skillsList = [];
      if (json['required_skills'] != null) {
        try {
          if (json['required_skills'] is List) {
            final rawSkills = json['required_skills'] as List;
            
            // CORRECTION : Utiliser une boucle for au lieu de where() pour éviter l'erreur de type
            for (var skill in rawSkills) {
              String skillName = '';
              if (skill is Map<String, dynamic> && skill.containsKey('name')) {
                skillName = skill['name']?.toString() ?? '';
              } else if (skill is String) {
                skillName = skill;
              } else {
                skillName = skill.toString();
              }
              
              // Ajouter seulement si non vide
              if (skillName.isNotEmpty) {
                skillsList.add(skillName);
              }
            }
          }
        } catch (e) {
          print('❌ Erreur parsing required_skills: $e');
          skillsList = [];
        }
      }

      // Gestion des attachments
      List<Map<String, String>>? attachmentsList;
        if (json['attachments'] != null && json['attachments'] is List) {
          try {
            attachmentsList = List<Map<String, String>>.from(
              json['attachments'].map((attachment) => Map<String, String>.from(attachment))
            );
          } catch (e) {
            print('❌ Erreur parsing attachments: $e');
            attachmentsList = null;
          }
        }

        Category? categoryObject;
        if (json['category'] != null) {
          if (json['category'] is Map<String, dynamic>) {
            // Si c'est un objet complet
            categoryObject = Category.fromJson(json['category']);
          } else {
            // Si c'est juste un ID, créer un objet Category minimal
            categoryObject = Category(
              id: json['category'] is int ? json['category'] : int.tryParse(json['category'].toString()) ?? 0,
              name: json['category_name'] ?? 'Catégorie',
              imageUrl: '',
              description: '',
              icon: '',
            );
          }
        }

        Subcategory? subcategoryObject;
        if (json['subcategory'] != null) {
          if (json['subcategory'] is Map<String, dynamic>) {
            // Si c'est un objet complet
            subcategoryObject = Subcategory.fromJson(json['subcategory']);
          } else {
            // Si c'est juste un ID, créer un objet Subcategory minimal
            subcategoryObject = Subcategory(
              id: json['subcategory'] is int ? json['subcategory'] : int.tryParse(json['subcategory'].toString()) ?? 0,
              name: json['subcategory_name'] ?? 'Sous-catégorie',
              description: '',
              categoryId: categoryObject?.id ?? 0,
            );
          }
        }
        
        return ClientProject(
          id: json['id'] ?? 0,
          title: json['title'] ?? '',
          description: json['description'] ?? '',
          client: json['client'] != null ? User.fromJson(json['client']) : null,
          clientName: json['client_name'] ?? 'Client anonyme',
          category: categoryObject,
          // category: json['category'] != null ? Category.fromJson(json['category']) : null,
          categoryName: json['category_name'] ?? '',
          // subcategory: json['subcategory'] != null ? Subcategory.fromJson(json['subcategory']) : null,
          subcategory: subcategoryObject,
          subcategoryName: json['subcategory_name'] ?? '',
          budgetRange: json['budget_range'] ?? '',
          minBudget: _parseDoubleFromDynamic(json['min_budget']),
          maxBudget: _parseDoubleFromDynamic(json['max_budget']),
          budgetDisplay: json['budget_display'] ?? '',
          location: json['location'] ?? '',
          remotePossible: _parseBoolSafely(json['remote_possible']) ?? false,
          deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
          urgency: json['urgency'] ?? 'medium',
          status: json['status'] ?? 'open',
          contactViaPlatform: _parseBoolSafely(json['contact_via_platform']) ?? true,
          showEmail: _parseBoolSafely(json['show_email']) ?? false,
          showPhone: _parseBoolSafely(json['show_phone']) ?? false,
          requiredSkills: skillsList,
          offersCount: json['offers_count'] ?? 0,
          viewsCount: json['views_count'] ?? 0,
          createdAt: json['created_at'] != null 
              ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
          timeSincePosted: json['time_since_posted'],
          isFavorited: _parseBoolSafely(json['is_favorited']) ?? false,
          hasUserOffered: _parseBoolSafely(json['has_user_offered']) ?? false,
          attachment1: json['attachment1'],
          attachment2: json['attachment2'],
          attachment3: json['attachment3'],
          attachments: attachmentsList,
        );
      } catch (e) {
        print('❌ Erreur critique dans ClientProject.fromJson: $e');
        print('Données JSON problématiques: $json');
        rethrow;
      }
    }

  // Méthode utilitaire pour parser les booléens de manière sécurisée
  static bool? _parseBoolSafely(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lowerValue = value.toLowerCase();
      return lowerValue == 'true' || lowerValue == '1' || lowerValue == 'yes';
    }
    if (value is int) return value == 1;
    if (value is double) return value == 1.0;
    
    // Par défaut, retourner false pour les valeurs inattendues
    print('⚠️ Valeur booléenne inattendue: $value (${value.runtimeType})');
    return false;
  }
  // static bool? _parseBoolSafely(dynamic value) {
  //   if (value == null) return null;
  //   if (value is bool) return value;
  //   if (value is String) {
  //     final lowerValue = value.toLowerCase().trim();
  //     if (lowerValue == 'true' || lowerValue == '1') return true;
  //     if (lowerValue == 'false' || lowerValue == '0') return false;
  //     return null;
  //   }
  //   if (value is int) return value != 0;
  //   if (value is double) return value != 0.0;
    
  //   // Si c'est un autre type, essayer de le convertir en string puis parser
  //   try {
  //     final stringValue = value.toString().toLowerCase().trim();
  //     if (stringValue == 'true' || stringValue == '1') return true;
  //     if (stringValue == 'false' || stringValue == '0') return false;
  //   } catch (e) {
  //     print('⚠️ Impossible de parser la valeur booléenne: $value (${value.runtimeType})');
  //   }
    
  //   return null;
  // }

  static double? _parseDoubleFromDynamic(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is double) {
        return value;
      } else if (value is int) {
        return value.toDouble();
      } else if (value is String) {
        if (value.isEmpty) return null;
        return double.parse(value);
      } else {
        print('⚠️ Type inattendu pour nombre: ${value.runtimeType} - $value');
        return double.tryParse(value.toString());
      }
    } catch (e) {
      print('❌ Erreur parsing nombre: $e pour valeur: $value');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'client': client?.toJson(),
      'client_name': clientName,
      'category': category?.toJson(),
      'category_name': categoryName,
      'subcategory': subcategory?.toJson(),
      'subcategory_name': subcategoryName,
      'budget_range': budgetRange,
      'min_budget': minBudget,
      'max_budget': maxBudget,
      'budget_display': budgetDisplay,
      'location': location,
      'remote_possible': remotePossible,
      'deadline': deadline?.toIso8601String(),
      'urgency': urgency,
      'status': status,
      'contact_via_platform': contactViaPlatform,
      'show_email': showEmail,
      'show_phone': showPhone,
      'required_skills': requiredSkills,
      'offers_count': offersCount,
      'views_count': viewsCount,
      'created_at': createdAt.toIso8601String(),
      'time_since_posted': timeSincePosted,
      'is_favorited': isFavorited,
      'has_user_offered': hasUserOffered,
      'attachment1': attachment1,
      'attachment2': attachment2,
      'attachment3': attachment3,
      'attachments': attachments,
    };
  }

  @override
  String toString() {
    return 'ClientProject(id: $id, title: $title, status: $status, clientName: $clientName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ClientProject &&
        other.id == id &&
        other.title == title &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ status.hashCode;
  }

  // Méthodes utilitaires
  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isClosed => status == 'closed';
  
  bool get isUrgent => urgency == 'high';
  bool get hasDeadline => deadline != null;
  bool get hasAttachments => (attachments?.isNotEmpty ?? false) || 
                            attachment1 != null || 
                            attachment2 != null || 
                            attachment3 != null;
  
  String get statusDisplay {
    switch (status) {
      case 'open':
        return 'Ouvert';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'closed':
        return 'Fermé';
      case 'paused':
        return 'En pause';
      default:
        return status;
    }
  }

  String get urgencyDisplay {
    switch (urgency) {
      case 'high':
        return 'Urgent';
      case 'medium':
        return 'Modéré';
      case 'low':
        return 'Pas pressé';
      default:
        return urgency;
    }
  }

  // Alias pour compatibilité
  String get urgencyLabel => urgencyDisplay;
}