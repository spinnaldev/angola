class Subcategory {
  final int id;
  final String name;
  final int categoryId;
  final String description;

  Subcategory({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.description,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      name: json['name'],
      categoryId: json['category'],
      description: json['description'] ?? '',
    );
  }
}