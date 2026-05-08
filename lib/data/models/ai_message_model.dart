class AIMessageModel {
  final int id;
  final String sessionId;
  final String query;
  final String response;
  final String roleCode;
  final bool isMe;
  final DateTime timestamp;

  AIMessageModel({
    required this.id,
    required this.sessionId,
    required this.query,
    required this.response,
    required this.roleCode,
    required this.isMe,
    required this.timestamp,
  });

  factory AIMessageModel.fromJson(Map<String, dynamic> json) {
    return AIMessageModel(
      id: json['id'] ?? 0,
      sessionId: json['sessionId'] ?? json['session_id'] ?? '',
      query: json['query'] ?? '',
      response: json['response'] ?? '',
      roleCode: json['roleCode'] ?? json['role_code'] ?? '',
      isMe: json['isMe'] ?? json['is_me'] ?? true,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'query': query,
      'response': response,
      'roleCode': roleCode,
      'isMe': isMe,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class AISessionModel {
  final String sessionId;
  final String roleCode;
  final String roleName;
  final String? lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  AISessionModel({
    required this.sessionId,
    required this.roleCode,
    required this.roleName,
    this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory AISessionModel.fromJson(Map<String, dynamic> json) {
    return AISessionModel(
      sessionId: json['sessionId'] ?? json['session_id'] ?? '',
      roleCode: json['roleCode'] ?? json['role_code'] ?? '',
      roleName: json['roleName'] ?? json['role_name'] ?? '',
      lastMessage: json['lastMessage'] ?? json['last_message'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.tryParse(json['lastMessageTime'].toString()) ?? DateTime.now()
          : (json['last_time'] != null
              ? DateTime.tryParse(json['last_time'].toString()) ?? DateTime.now()
              : DateTime.now()),
      unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
    );
  }
}
