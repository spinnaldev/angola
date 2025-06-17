class ProjectSkill {
  final int id;
  final String name;
  final bool isRequired;

  ProjectSkill({
    required this.id,
    required this.name,
    required this.isRequired,
  });

  factory ProjectSkill.fromJson(Map<String, dynamic> json) {
    return ProjectSkill(
      id: json['id'],
      name: json['name'],
      isRequired: json['is_required'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_required': isRequired,
    };
  }
}
