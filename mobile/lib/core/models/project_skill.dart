// lib/core/models/project_skill.dart - Version simplifiée
class ProjectSkill {
  final int? id;
  final String name;
  final bool isRequired;

  ProjectSkill({
    this.id,
    required this.name,
    this.isRequired = true,
  });

  factory ProjectSkill.fromJson(Map<String, dynamic> json) {
    return ProjectSkill(
      id: json['id'],
      name: json['name'] ?? '',
      isRequired: json['is_required'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'is_required': isRequired,
    };
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectSkill && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}