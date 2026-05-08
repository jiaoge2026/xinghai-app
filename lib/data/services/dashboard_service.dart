import '../../core/utils/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  final ApiClient _client = ApiClient();

  /// 获取经营概览
  /// 后端路径: GET /api/report/dashboard
  Future<DashboardOverviewModel> getOverview() async {
    final resp = await _client.get('/api/report/dashboard');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return DashboardOverviewModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '获取经营概览失败');
  }

  /// 获取FSM驾驶舱
  /// 后端路径: GET /api/report/fsm
  Future<FsmDashboardModel> getFsmDashboard() async {
    final resp = await _client.get('/api/report/fsm');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return FsmDashboardModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '获取FSM驾驶舱失败');
  }

  /// 获取财务驾驶舱
  /// 后端路径: GET /api/report/finance
  Future<FinanceDashboardModel> getFinanceDashboard() async {
    final resp = await _client.get('/api/report/finance');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return FinanceDashboardModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '获取财务驾驶舱失败');
  }

  /// 获取库存驾驶舱
  /// 后端路径: GET /api/report/inventory
  Future<InventoryDashboardModel> getInventoryDashboard() async {
    final resp = await _client.get('/api/report/inventory');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return InventoryDashboardModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '获取库存驾驶舱失败');
  }

  /// 获取零售驾驶舱
  /// 后端路径: GET /api/report/retail（如无则返回空map）
  Future<Map<String, dynamic>> getRetailDashboard() async {
    try {
      final resp = await _client.get('/api/report/retail');
      final data = resp.data;

      if (data['code'] == 0 && data['data'] != null) {
        return data['data'];
      }
      throw Exception(data['message'] ?? '获取零售驾驶舱失败');
    } catch (e) {
      // 后端如无此接口，返回空map
      return {};
    }
  }

  /// 获取工程师排行
  /// 后端路径: GET /api/report/engineer-ranking
  Future<List<EngineerRankingModel>> getEngineerRanking({
    String? month,
  }) async {
    final query = <String, dynamic>{};
    if (month != null) query['month'] = month;

    final resp = await _client.get('/api/report/engineer-ranking', queryParameters: query);
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => EngineerRankingModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取工程师排行失败');
  }

  /// 获取销售排行
  /// 后端路径: GET /api/report/sales-ranking
  Future<List<Map<String, dynamic>>> getSalesRanking({
    String? month,
    int limit = 10,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
    };
    if (month != null) query['month'] = month;

    final resp = await _client.get('/api/report/sales-ranking', queryParameters: query);
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    throw Exception(data['message'] ?? '获取销售排行失败');
  }
}
