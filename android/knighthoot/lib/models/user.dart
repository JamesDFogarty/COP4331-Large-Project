// File: lib/models/user.dart
class User {
  final String id;
  final String mongoId;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String role;
  final String? token;  // ADD THIS

  User({
    required this.id,
    required this.mongoId,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.role,
    this.token,  // ADD THIS
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      mongoId: json['_id'].toString(),
      firstName: json['firstName'],
      lastName: json['lastName'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      token: json['token'],  // ADD THIS
    );
  }
}