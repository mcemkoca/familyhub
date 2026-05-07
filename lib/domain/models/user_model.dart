class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });
}
