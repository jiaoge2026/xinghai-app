import '../../core/utils/api_client.dart';
import '../models/work_order_model.dart';

class WorkOrderService {
  final ApiClient _client = ApiClient();

  Future<List<WorkOrderModel>> getPage({
    int page = 1,
    int pageSize = 20,
    int? status,
    int? engineerId,
    int? projectId,
    String? startDate,
    String? endDate,
    String? keyword,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (status != null) query['status'] = status;
    if (engineerId != null) query['engineerId'] = engineerId;
    if (projectId != null) query['projectId'] = projectId;
    if (startDate != null) query['startDate'] = startDate;
    if (endDate != null) query['endDate'] = endDate;
    if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;

    final resp = await _client.get('/api/fsm/work-orders', queryParameters: query);
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final dataBody = data['data'] as Map<String, dynamic>?;
      final list = dataBody?['records'] as List<dynamic>? ??
                   dataBody?['list'] as List<dynamic>? ?? [];
      return list.map((e) => WorkOrderModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取工单列表失败');
  }

  Future<WorkOrderModel> getDetail(int id) async {
    final resp = await _client.get('/api/fsm/work-orders/$id');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return WorkOrderModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '获取工单详情失败');
  }

  Future<void> updateStatus(int id, int status, {String? remark}) async {
    final resp = await _client.put('/api/fsm/work-orders/$id/status', data: {
      'status': status,
      if (remark != null) 'remark': remark,
    });
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '更新状态失败');
    }
  }

  Future<void> complete({
    required int id,
    required double workHours,
    required double travelFee,
    double materialFee = 0,
    String? remark,
  }) async {
    final resp = await _client.put('/api/fsm/work-orders/$id/complete', data: {
      'workHours': workHours,
      'travelFee': travelFee,
      'materialFee': materialFee,
      if (remark != null) 'remark': remark,
    });
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '完工登记失败');
    }
  }

  Future<void> addMaterials(int id, List<PartModel> parts, {int warehouseId = 1}) async {
    final resp = await _client.post('/api/fsm/work-orders/$id/materials', data: {
      'warehouseId': warehouseId,
      'materials': parts.map((e) => e.toJson()).toList(),
    });
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '添加配件失败');
    }
  }

  Future<Map<String, dynamic>> getTodayStat() async {
    final resp = await _client.get('/api/fsm/work-orders/today-stat');
    final data = resp.data;
    if (data['code'] == 0 && data['data'] != null) {
      return data['data'];
    }
    throw Exception(data['message'] ?? '获取今日统计失败');
  }
}
