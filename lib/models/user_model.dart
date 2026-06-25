class UserModel {
  final String userId;
  final String name;
  final String email;
  final String avatar;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.avatar,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      userId: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      avatar: data['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }
}
