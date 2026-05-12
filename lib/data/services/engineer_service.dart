import '../../core/utils/api_client.dart';
import '../models/engineer_model.dart';

class EngineerService {
  final ApiClient _client = ApiClient();

  /// 获取工程师详情
  /// 后端路径: GET /api/fsm/engineers/{id}
  Future<EngineerModel> getDetail(int id) async {
    final resp = await _client.get('/api/v1/fsm/engineers/$id');
    final data = resp.data;
    if (data['code'] == 0 && data['data'] != null) {
      return EngineerModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '获取工程师详情失败');
  }

  /// 更新工程师接单状态
  /// 后端路径: PUT /api/fsm/engineers/{id}/status
  Future<void> updateStatus(int id, int status) async {
    final resp = await _client.put('/api/v1/fsm/engineers/$id/status', data: {
      'status': status,
    });
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '更新接单状态失败');
    }
  }

  /// 获取可派工程师列表
  /// 后端路径: GET /api/fsm/engineers/available
  Future<List<EngineerModel>> getAvailable({String? date, String? area, String? skill}) async {
    final query = <String, dynamic>{};
    if (date != null) query['date'] = date;
    if (area != null) query['area'] = area;
    if (skill != null) query['skill'] = skill;

    final resp = await _client.get('/api/v1/fsm/engineers/available', queryParameters: query);
    final data = resp.data;
    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => EngineerModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取可派工程师列表失败');
  }

  /// 获取工程师列表（分页）
  /// 后端路径: GET /api/fsm/engineers
  Future<List<EngineerModel>> getPage({
    int page = 1,
    int pageSize = 20,
    String? keyword,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;

    final resp = await _client.get('/api/v1/fsm/engineers', queryParameters: query);
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
      return list.map((e) => EngineerModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取工程师列表失败');
  }
}
