class ProjectStats {
  final int totalProjects;
  final int openProjects;
  final int completedProjects;
  final int totalOffers;
  final double averageOffersPerProject;

  ProjectStats({
    required this.totalProjects,
    required this.openProjects,
    required this.completedProjects,
    required this.totalOffers,
    required this.averageOffersPerProject,
  });

  factory ProjectStats.fromJson(Map<String, dynamic> json) {
    return ProjectStats(
      totalProjects: json['total_projects'] ?? 0,
      openProjects: json['open_projects'] ?? 0,
      completedProjects: json['completed_projects'] ?? 0,
      totalOffers: json['total_offers'] ?? 0,
      averageOffersPerProject: (json['average_offers_per_project'] ?? 0.0).toDouble(),
    );
  }
}