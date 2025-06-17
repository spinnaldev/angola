import 'user.dart';
import 'category.dart';
import 'project_skill.dart';
import 'subcategory.dart';
// import 'dart:convert';
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
  final List<ProjectSkill> requiredSkills;
  final int offersCount;
  final int viewsCount;
  final DateTime createdAt;
  final String? timeSincePosted;
  final bool? isFavorited;
  final bool? hasUserOffered;
  final String? attachment1;
  final String? attachment2;
  final String? attachment3;

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
  });

  factory ClientProject.fromJson(Map<String, dynamic> json) {
    return ClientProject(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      client: json['client'] != null ? User.fromJson(json['client']) : null,
      clientName: json['client_name'] ?? '',
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      categoryName: json['category_name'] ?? '',
      subcategory: json['subcategory'] != null ? Subcategory.fromJson(json['subcategory']) : null,
      subcategoryName: json['subcategory_name'],
      budgetRange: json['budget_range'],
      minBudget: json['min_budget'] != null ? double.parse(json['min_budget'].toString()) : null,
      maxBudget: json['max_budget'] != null ? double.parse(json['max_budget'].toString()) : null,
      budgetDisplay: json['budget_display'] ?? '',
      location: json['location'],
      remotePossible: json['remote_possible'] ?? false,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      urgency: json['urgency'],
      status: json['status'],
      contactViaPlatform: json['contact_via_platform'] ?? true,
      showEmail: json['show_email'] ?? false,
      showPhone: json['show_phone'] ?? false,
      requiredSkills: (json['required_skills'] as List<dynamic>?)
          ?.map((skill) => ProjectSkill.fromJson(skill))
          .toList() ?? [],
      offersCount: json['offers_count'] ?? 0,
      viewsCount: json['views_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      timeSincePosted: json['time_since_posted'],
      isFavorited: json['is_favorited'],
      hasUserOffered: json['has_user_offered'],
      attachment1: json['attachment1'],
      attachment2: json['attachment2'],
      attachment3: json['attachment3'],
    );
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
      'required_skills': requiredSkills.map((skill) => skill.toJson()).toList(),
      'offers_count': offersCount,
      'views_count': viewsCount,
      'created_at': createdAt.toIso8601String(),
      'time_since_posted': timeSincePosted,
      'is_favorited': isFavorited,
      'has_user_offered': hasUserOffered,
      'attachment1': attachment1,
      'attachment2': attachment2,
      'attachment3': attachment3,
    };
  }

  // Getters utilitaires
  String get urgencyLabel {
    switch (urgency) {
      case 'low':
        return 'Pas urgent';
      case 'medium':
        return 'Modérément urgent';
      case 'high':
        return 'Urgent';
      case 'very_high':
        return 'Très urgent';
      default:
        return urgency;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'open':
        return 'Ouvert';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  bool get isOpen => status == 'open';
  bool get hasDeadline => deadline != null;
  bool get hasAttachments => attachment1 != null || attachment2 != null || attachment3 != null;
}
