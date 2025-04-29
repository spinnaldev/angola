class Review {
  final int id;
  final String userName;
  final String userImageUrl;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.id,
    required this.userName,
    required this.userImageUrl,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userName: json['user_name'],
      userImageUrl: json['user_image_url'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      date: DateTime.parse(json['date']),
    );
  }
}