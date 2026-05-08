class AIRoleModel {
  final String roleCode;
  final String roleName;
  final String roleDescription;
  final String welcomeMessage;
  final List<String> suggestedQuestions;

  AIRoleModel({
    required this.roleCode,
    required this.roleName,
    required this.roleDescription,
    required this.welcomeMessage,
    required this.suggestedQuestions,
  });

  factory AIRoleModel.fromJson(Map<String, dynamic> json) {
    return AIRoleModel(
      roleCode: json['roleCode'] ?? json['role_code'] ?? '',
      roleName: json['roleName'] ?? json['role_name'] ?? '',
      roleDescription: json['roleDescription'] ?? json['role_description'] ?? '',
      welcomeMessage: json['welcomeMessage'] ?? json['welcome_message'] ?? '',
      suggestedQuestions: (json['suggestedQuestions'] ?? json['suggested_questions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleCode': roleCode,
      'roleName': roleName,
      'roleDescription': roleDescription,
      'welcomeMessage': welcomeMessage,
      'suggestedQuestions': suggestedQuestions,
    };
  }
}
