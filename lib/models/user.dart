// models/user.dart
class User {
  final int userId;
  final String username;
  final String email;
  final String publicKey;
  
  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.publicKey,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      username: json['username'],
      email: json['email'],
      publicKey: json['publicKey'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'publicKey': publicKey,
    };
  }
}