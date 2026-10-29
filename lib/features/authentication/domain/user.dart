/// Domain model representing an authenticated user profile.
class User {
  const User({
    required this.id,
    required this.name,
    this.email,
    this.preferredLanguage = 'DE',
  });

  final String id;
  final String name;
  final String? email;
  final String preferredLanguage;

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? preferredLanguage,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (email != null) 'email': email,
      'preferredLanguage': preferredLanguage,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      preferredLanguage: (json['preferredLanguage'] as String?) ?? 'DE',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          preferredLanguage == other.preferredLanguage;

  @override
  int get hashCode => Object.hash(id, name, email, preferredLanguage);
}
