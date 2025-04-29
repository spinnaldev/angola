
class ProviderInProject {  // Renommé de ProjectProvider
  final int id;
  final String name;
  final String specialty;
  final String imageUrl;

  ProviderInProject({  // Constructeur mis à jour
    required this.id,
    required this.name,
    required this.specialty,
    required this.imageUrl,
  });

  factory ProviderInProject.fromJson(Map<String, dynamic> json) {
    return ProviderInProject(  // Appel factory mis à jour
      id: json['id'],
      name: json['name'],
      specialty: json['specialty'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class Project {
  final int id;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;
  final List<ProviderInProject> providers;  // Type mis à jour ici

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.providers,
  });
  
  factory Project.fromJson(Map<String, dynamic> json) {
    List<ProviderInProject> providersList = [];
    
    if (json['providers'] != null) {
      providersList = List<ProviderInProject>.from(
        json['providers'].map((provider) => ProviderInProject.fromJson(provider))
      );
    }
    
    return Project(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      status: json['status'] ?? 'En cours',
      createdAt: DateTime.parse(json['created_at']),
      providers: providersList,
    );
  }
}


// class ProjectProvider {
//   final int id;
//   final String name;
//   final String specialty;
//   final String imageUrl;

//   ProjectProvider({
//     required this.id,
//     required this.name,
//     required this.specialty,
//     required this.imageUrl,
//   });

//   factory ProjectProvider.fromJson(Map<String, dynamic> json) {
//     return ProjectProvider(
//       id: json['id'],
//       name: json['name'],
//       specialty: json['specialty'] ?? '',
//       imageUrl: json['image_url'] ?? '',
//     );
//   }
// }