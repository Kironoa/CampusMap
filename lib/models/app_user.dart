class AppUser {
  final int id;
  final String username;
  final String? profilePath;

  const AppUser({
    required this.id,
    required this.username,
    this.profilePath,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int,
      username: (map['username'] ?? 'Student').toString(),
      profilePath: map['profilePath']?.toString(),
    );
  }

  AppUser copyWith({
    int? id,
    String? username,
    String? profilePath,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      profilePath: profilePath ?? this.profilePath,
    );
  }
}
