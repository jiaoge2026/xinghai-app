import '../../core/utils/api_client.dart';

class SalesService {
  final ApiClient _client = ApiClient();

  // ============ 客户 ============

  Future<List<Map<String, dynamic>>> getCustomerList() async {
    final resp = await _client.get('/api/v1/sales/customer/list');
    final data = resp.data;
    if (data['code'] == 0) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception(data['message'] ?? '获取客户列表失败');
  }

  Future<Map<String, dynamic>> getCustomerById(int id) async {
    final resp = await _client.get('/api/v1/sales/customer/$id');
    final data = resp.data;
    if (data['code'] == 0 && data['data'] != null) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception(data['message'] ?? '获取客户详情失败');
  }

  Future<int> createCustomer(Map<String, dynamic> body) async {
    final resp = await _client.post('/api/v1/sales/customer', data: body);
    final data = resp.data;
    if (data['code'] == 0) return data['data']['id'] as int;
    throw Exception(data['message'] ?? '创建客户失败');
  }

  Future<void> updateCustomer(int id, Map<String, dynamic> body) async {
    final resp = await _client.put('/api/v1/sales/customer/$id', data: body);
    final data = resp.data;
    if (data['code'] != 0) throw Exception(data['message'] ?? '更新客户失败');
  }

  Future<void> deleteCustomer(int id) async {
    final resp = await _client.delete('/api/v1/sales/customer/$id');
    final data = resp.data;
    if (data['code'] != 0) throw Exception(data['message'] ?? '删除客户失败');
  }

  // ============ 商机 ============

  Future<List<Map<String, dynamic>>> getOpportunityList() async {
    final resp = await _client.get('/api/v1/sales/opportunity/list');
    final data = resp.data;
    if (data['code'] == 0) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception(data['message'] ?? '获取商机列表失败');
  }

  Future<Map<String, dynamic>> getOpportunityById(int id) async {
    final resp = await _client.get('/api/v1/sales/opportunity/$id');
    final data = resp.data;
    if (data['code'] == 0 && data['data'] != null) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception(data['message'] ?? '获取商机详情失败');
  }

  Future<int> createOpportunity(Map<String, dynamic> body) async {
    final resp = await _client.post('/api/v1/sales/opportunity', data: body);
    final data = resp.data;
    if (data['code'] == 0) return data['data']['id'] as int;
    throw Exception(data['message'] ?? '创建商机失败');
  }

  // ============ 报价单 ============

  Future<List<Map<String, dynamic>>> getQuoteList() async {
    final resp = await _client.get('/api/v1/sales/quote/page', queryParameters: {'pageNum': 1, 'pageSize': 100});
    final data = resp.data;
    if (data['code'] == 0) {
      final records = data['data']['records'] as List<dynamic>? ?? [];
      return records.cast<Map<String, dynamic>>();
    }
    throw Exception(data['message'] ?? '获取报价单列表失败');
  }

  Future<Map<String, dynamic>> getQuoteById(int id) async {
    final resp = await _client.get('/api/v1/sales/quote/$id');
    final data = resp.data;
    if (data['code'] == 0 && data['data'] != null) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception(data['message'] ?? '获取报价单详情失败');
  }

  Future<int> createQuote(Map<String, dynamic> body) async {
    final resp = await _client.post('/api/v1/sales/quote', data: body);
    final data = resp.data;
    if (data['code'] == 0) return data['data']['id'] as int;
    throw Exception(data['message'] ?? '创建报价单失败');
  }

  // ============ 工程项目订单 ============

  Future<List<Map<String, dynamic>>> getProjectOrderList() async {
    final resp = await _client.get('/api/v1/sales/project-order/list');
    final data = resp.data;
    if (data['code'] == 0) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception(data['message'] ?? '获取工程项目订单失败');
  }

  Future<Map<String, dynamic>> getProjectOrderById(int id) async {
    final resp = await _client.get('/api/v1/sales/project-order/$id');
    final data = resp.data;
    if (data['code'] == 0 && data['data'] != null) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception(data['message'] ?? '获取工程项目订单详情失败');
  }

  /// 确认工程项目订单（扣库+生成应收款+生成FSM工单）
  /// warehouseId: 仓库ID，默认1
  Future<Map<String, dynamic>> confirmProjectOrder(int id, {int warehouseId = 1}) async {
    final resp = await _client.post('/api/v1/sales/project-order/confirm/$id?warehouseId=$warehouseId');
    final data = resp.data;
    if (data['code'] == 0) {
      return data['data'] as Map<String, dynamic>? ?? {};
    }
    throw Exception(data['message'] ?? '确认订单失败');
  }

  // ============ 销售应收款 ============

  Future<List<Map<String, dynamic>>> getReceivableList() async {
    final resp = await _client.get('/api/v1/sales/receivable/list');
    final data = resp.data;
    if (data['code'] == 0) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception(data['message'] ?? '获取应收款列表失败');
  }
}
