import '../../core/utils/api_client.dart';
import '../models/ai_message_model.dart';
import '../models/ai_role_model.dart';

class AIChatService {
  final ApiClient _client = ApiClient();

  /// 获取AI角色列表
  /// 后端路径: GET /api/ai/roles
  Future<List<AIRoleModel>> getRoles() async {
    final resp = await _client.get('/api/ai/roles');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => AIRoleModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取AI角色列表失败');
  }

  /// 发送消息
  /// 后端路径: POST /api/ai/chat
  Future<Map<String, dynamic>> sendMessage({
    required String sessionId,
    required String roleCode,
    required String query,
  }) async {
    final resp = await _client.post('/api/ai/chat', data: {
      'sessionId': sessionId,
      'roleCode': roleCode,
      'query': query,
    });
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception(data['message'] ?? '发送消息失败');
  }

  /// 创建会话
  /// 后端路径: POST /api/ai/sessions
  Future<String> createSession(String roleCode) async {
    final resp = await _client.post('/api/ai/sessions', data: {
      'roleCode': roleCode,
    });
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return data['data']['sessionId'] ?? '';
    }
    throw Exception(data['message'] ?? '创建会话失败');
  }

  /// 获取会话列表
  /// 后端路径: GET /api/ai/sessions
  Future<List<AISessionModel>> getSessions() async {
    final resp = await _client.get('/api/ai/sessions');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => AISessionModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取会话列表失败');
  }

  /// 获取历史消息
  /// 后端路径: GET /api/ai/sessions/{sessionId}/messages
  Future<List<AIMessageModel>> getSessionMessages(String sessionId) async {
    final resp = await _client.get('/api/ai/sessions/$sessionId/messages');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => AIMessageModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取历史消息失败');
  }

  /// 删除会话
  /// 后端路径: DELETE /api/ai/sessions/{sessionId}
  Future<void> deleteSession(String sessionId) async {
    final resp = await _client.delete('/api/ai/sessions/$sessionId');
    final data = resp.data;

    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '删除会话失败');
    }
  }

  /// 清空会话消息
  /// 后端路径: DELETE /api/ai/sessions/{sessionId}/messages
  Future<void> clearSession(String sessionId) async {
    final resp = await _client.delete('/api/ai/sessions/$sessionId/messages');
    final data = resp.data;

    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '清空会话失败');
    }
  }
}
