import '../../core/utils/api_client.dart';
import '../models/part_model.dart';

class PartService {
  final ApiClient _client = ApiClient();

  /// 分页查询配件列表
  /// 后端路径: GET /api/wms/parts（分页参数: page, pageSize）
  Future<List<PartModel>> getPage({
    int page = 1,
    int pageSize = 20,
    String? keyword,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;

    // 后端实际路径: /api/wms/parts（无/page后缀）
    final resp = await _client.get('/api/wms/parts', queryParameters: query);
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
      return list.map((e) => PartModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取配件列表失败');
  }

  /// 获取库存列表
  /// 后端路径: GET /api/wms/parts/stock/{warehouseId}
  Future<List<PartModel>> getStock(int warehouseId) async {
    final resp = await _client.get('/api/wms/parts/stock/$warehouseId');
    final data = resp.data;
    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => PartModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取库存列表失败');
  }
}
