import '../../core/utils/api_client.dart';
import '../models/project_model.dart';

class ProjectService {
  final ApiClient _client = ApiClient();

  /// 分页查询项目列表
  /// 后端路径: GET /api/fsm/projects（分页参数: page, pageSize）
  Future<List<ProjectModel>> getPage({
    int page = 1,
    int pageSize = 20,
    int? status,
    String? keyword,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (status != null) query['status'] = status;
    if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;

    // 后端实际路径: /api/fsm/projects（无/page后缀）
    final resp = await _client.get('/api/v1/fsm/projects', queryParameters: query);
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
      return list.map((e) => ProjectModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取项目列表失败');
  }

  /// 获取项目详情
  /// 后端路径: GET /api/fsm/projects/{id}
  Future<ProjectModel> getDetail(int id) async {
    final resp = await _client.get('/api/v1/fsm/projects/$id');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return ProjectModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '获取项目详情失败');
  }

  /// 获取成本汇总
  /// 后端路径: GET /api/fsm/projects/{id}/cost-summary
  Future<Map<String, dynamic>> getCostSummary(int id) async {
    final resp = await _client.get('/api/v1/fsm/projects/$id/cost-summary');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return data['data'];
    }
    throw Exception(data['message'] ?? '获取成本汇总失败');
  }
}
