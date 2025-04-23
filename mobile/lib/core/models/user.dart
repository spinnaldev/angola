import 'dart:convert';

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? bio;
  final String? profilePicture;
  final String role;
  final bool isVerified;
  final String? location;
  final DateTime dateJoined;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.bio,
    this.profilePicture,
    required this.role,
    required this.isVerified,
    this.location,
    required this.dateJoined,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      bio: json['bio'],
      profilePicture: json['profile_picture'],
      role: json['role'],
      isVerified: json['is_verified'],
      location: json['location'],
      dateJoined: DateTime.parse(json['date_joined']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'bio': bio,
      'profile_picture': profilePicture,
      'role': role,
      'is_verified': isVerified,
      'location': location,
      'date_joined': dateJoined.toIso8601String(),
    };
  }

  static String toJsonString(User user) {
    return json.encode(user.toJson());
  }

  static User fromJsonString(String jsonString) {
    return User.fromJson(json.decode(jsonString));
  }

  String get fullName => '$firstName $lastName';
}