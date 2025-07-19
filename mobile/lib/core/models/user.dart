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
  final String? companyName;

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
    this.companyName,
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
      companyName: json['company_name'], 
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
      'company_name': companyName,
    };
  }

  static String toJsonString(User user) {
    return json.encode(user.toJson());
  }

  static User fromJsonString(String jsonString) {
    return User.fromJson(json.decode(jsonString));
  }

  String get fullName => '$firstName $lastName';

  String get displayName {
    if (fullName.isNotEmpty) {
      return fullName;
    }
    return username.isNotEmpty ? username : email.split('@').first;
  }

  // ✅ AJOUT - Getter pour le nom d'affichage avec entreprise
  String get displayNameWithCompany {
    if (role == 'provider' && companyName != null && companyName!.isNotEmpty) {
      return companyName!;
    }
    return displayName;
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? bio,
    String? profilePicture,
    String? role,
    bool? isVerified,
    String? location,
    DateTime? dateJoined,
    String? companyName, // ✅ AJOUT
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      location: location ?? this.location,
      dateJoined: dateJoined ?? this.dateJoined,
      companyName: companyName ?? this.companyName, // ✅ AJOUT
    );
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email, fullName: $fullName, role: $role, companyName: $companyName}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
