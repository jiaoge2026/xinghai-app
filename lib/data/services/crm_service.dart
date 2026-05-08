import '../../core/utils/api_client.dart';
import '../models/opportunity_model.dart';

class CRMService {
  final ApiClient _client = ApiClient();

  /// 获取商机列表
  /// 后端路径: GET /api/crm/opportunities
  Future<List<OpportunityModel>> getOpportunities({
    int? stage,
    int? employeeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (stage != null) query['stage'] = stage;
    if (employeeId != null) query['employeeId'] = employeeId;

    final resp = await _client.get('/api/crm/opportunities', queryParameters: query);
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final dataBody = data['data'];
      List<dynamic> list;
      if (dataBody is Map) {
        list = dataBody['list'] as List<dynamic>? ?? [];
      } else if (dataBody is List) {
        list = dataBody;
      } else {
        list = [];
      }
      return list.map((e) => OpportunityModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取商机列表失败');
  }

  /// 获取商机详情
  /// 后端路径: GET /api/crm/opportunities/{id}
  Future<OpportunityModel> getOpportunityDetail(int id) async {
    final resp = await _client.get('/api/crm/opportunities/$id');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return OpportunityModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '获取商机详情失败');
  }

  /// 更新商机阶段
  /// 后端路径: PUT /api/crm/opportunities/{id}/stage
  Future<void> updateOpportunityStage(int id, int stage) async {
    final resp = await _client.put('/api/crm/opportunities/$id/stage', data: {
      'stage': stage,
    });
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '推进阶段失败');
    }
  }

  /// 创建商机
  /// 后端路径: POST /api/crm/opportunities
  Future<int> createOpportunity(Map<String, dynamic> data) async {
    final resp = await _client.post('/api/crm/opportunities', data: data);
    final result = resp.data;
    if (result['code'] == 0) {
      return result['data']['id'] ?? 0;
    }
    throw Exception(result['message'] ?? '创建商机失败');
  }

  /// 更新商机
  /// 后端路径: PUT /api/crm/opportunities/{id}
  Future<void> updateOpportunity(int id, Map<String, dynamic> data) async {
    final resp = await _client.put('/api/crm/opportunities/$id', data: data);
    final result = resp.data;
    if (result['code'] != 0) {
      throw Exception(result['message'] ?? '更新商机失败');
    }
  }

  /// 获取跟进记录
  /// 后端路径: GET /api/crm/follow-ups?customerId=xxx
  Future<List<CustomerFollowUpModel>> getFollowUps(int customerId) async {
    final resp = await _client.get('/api/crm/follow-ups', queryParameters: {
      'customerId': customerId,
    });
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => CustomerFollowUpModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取跟进记录失败');
  }

  /// 新增跟进记录
  /// 后端路径: POST /api/crm/follow-ups
  Future<void> addFollowUp(Map<String, dynamic> followUpData) async {
    final resp = await _client.post('/api/crm/follow-ups', data: followUpData);
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '添加跟进记录失败');
    }
  }

  /// 获取漏斗统计
  /// 后端路径: GET /api/crm/opportunities/funnel
  Future<Map<String, int>> getFunnelStats() async {
    final resp = await _client.get('/api/crm/opportunities/funnel');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return Map<String, int>.from(data['data']);
    }
    throw Exception(data['message'] ?? '获取漏斗统计失败');
  }
}
