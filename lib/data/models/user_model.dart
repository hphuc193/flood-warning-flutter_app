class User {
  final int? id;
  final String? email;
  final String? fullName;

  User({this.id, this.email, this.fullName});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
    );
  }
}