class UserModel {
  final int id;
  final String username;
  final String realName;
  final int deptId;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.username,
    required this.realName,
    required this.deptId,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      realName: json['realName'] ?? '',
      deptId: json['deptId'] ?? 0,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'realName': realName,
      'deptId': deptId,
      'roles': roles,
    };
  }

  bool get isAdmin => roles.contains('ADMIN');
  bool get isEngineer => roles.contains('ENGINEER');
  bool get isServiceManager => roles.contains('SERVICE_MANAGER');
}
