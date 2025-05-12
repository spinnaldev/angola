// lib/core/models/completed_work.dart
import 'dart:convert';

class CompletedWork {
  final int? id;
  final int providerId;
  final String title;
  final String description;
  final String location;
  final DateTime completionDate;
  final List<String> imageUrls;
  final int subcategoryId;
  final String clientName;
  final String clientContact;
  final DateTime createdAt;

  CompletedWork({
    this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.location,
    required this.completionDate,
    this.imageUrls = const [],
    required this.subcategoryId,
    required this.clientName,
    required this.clientContact,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory CompletedWork.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['images'] != null) {
      images = List<String>.from(json['images']);
    }

    return CompletedWork(
      id: json['id'],
      providerId: json['provider'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      completionDate: DateTime.parse(json['completion_date']),
      imageUrls: images,
      subcategoryId: json['subcategory'],
      clientName: json['client_name'],
      clientContact: json['client_contact'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': providerId,
      'title': title,
      'description': description,
      'location': location,
      'completion_date': completionDate.toIso8601String(),
      'subcategory': subcategoryId,
      'client_name': clientName,
      'client_contact': clientContact,
    };
  }
}

class WorkImage {
  final int? id;
  final int workId;
  final String imageUrl;
  final String caption;
  final DateTime uploadedAt;

  WorkImage({
    this.id,
    required this.workId,
    required this.imageUrl,
    this.caption = '',
    DateTime? uploadedAt,
  }) : this.uploadedAt = uploadedAt ?? DateTime.now();

  factory WorkImage.fromJson(Map<String, dynamic> json) {
    return WorkImage(
      id: json['id'],
      workId: json['work'],
      imageUrl: json['image'],
      caption: json['caption'] ?? '',
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'work': workId,
      'image': imageUrl,
      'caption': caption,
    };
  }
}